#!/bin/bash

###########################################
# Configuration Variables - Easy to modify
###########################################

# VM Resources
VM_MEMORY=1024           # Memory in MB
VM_CORES=1               # Number of CPU cores
VM_DISK_SIZE=10         # Disk size in GB
VM_TEMPLATE_NAME="debian-11-template"  # Template name

# Network Configuration
VM_BRIDGE="vmbr1"       # Network bridge
VM_NET_MODEL="virtio"   # Network card model

# Cloud-Init Default Settings
CI_USER="root"          # Default cloud-init user
CI_DNS="1.1.1.1"        # Default DNS server
CI_SEARCHDOMAIN=""      # Default search domain
CI_IPCONFIG="ip=dhcp"   # Default IP configuration

# Image Source
DEBIAN_IMAGE_URL="https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
DEBIAN_IMAGE_NAME="debian-11-generic-amd64.qcow2"

# Additional Packages to Install
ADDITIONAL_PACKAGES="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent \
    apt-transport-https ca-certificates software-properties-common jq \
    systemd-timesyncd cron htop zstd"

# Working Directory
TEMPLATE_WORKING_DIR="/var/lib/vz/template/iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect storage
detect_storage() {
    # Get list of available storages
    local storages=$(pvesm status -content images | awk 'NR>1 {print $1}')
    
    # First try to find local-zfs
    if echo "$storages" | grep -q "local-zfs"; then
        echo "local-zfs"
    # Then try to find local
    elif echo "$storages" | grep -q "local"; then
        echo "local"
    # Otherwise use the first available storage
    else
        echo "$storages" | head -n1
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Check required commands
for cmd in wget virt-customize qm pvesm; do
    if ! command_exists $cmd; then
        print_error "Required command '$cmd' not found. Please install it first."
        exit 1
    fi
done

# Prompt for template ID
while true; do
    read -p "Enter template ID (100-999): " TEMPLATE_ID
    if [[ $TEMPLATE_ID =~ ^[1-9][0-9]{2}$ && $TEMPLATE_ID -le 999 ]]; then
        if ! qm status $TEMPLATE_ID >/dev/null 2>&1; then
            break
        else
            print_error "Template ID $TEMPLATE_ID already exists. Please choose another ID."
        fi
    else
        print_error "Please enter a valid template ID between 100 and 999."
    fi
done

# Prompt for SSH port
read -e -p $'Enter \e[33mSSH port\033[0m : ' -i "6070" SSH_PORT

# Prompt for root login configuration
read -e -p $'Enable \e[33mroot login\033[0m (y/n): ' -i "y" ENABLE_ROOT
ENABLE_ROOT=$(echo "$ENABLE_ROOT" | tr '[:upper:]' '[:lower:]')

# Prompt for password authentication
read -e -p $'Enable \e[33mpassword authentication\033[0m (y/n): ' -i "y" ENABLE_PASS_AUTH
ENABLE_PASS_AUTH=$(echo "$ENABLE_PASS_AUTH" | tr '[:upper:]' '[:lower:]')

# Detect storage
STORAGE=$(detect_storage)
print_message "Detected storage: $STORAGE"

# Set working directory
cd $TEMPLATE_WORKING_DIR || exit 1

# Download Debian cloud image
print_message "Downloading Debian cloud image..."
wget -q --show-progress "${DEBIAN_IMAGE_URL}"

# Resize the disk image
print_message "Resizing disk image to ${VM_DISK_SIZE}GB..."
qemu-img resize "${DEBIAN_IMAGE_NAME}" "${VM_DISK_SIZE}G"

# Create initialization script
cat > init_script_debian-11.sh << EOL
#!/bin/bash

# Configure SSH
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config

# Enable root login if requested
if [ "${ENABLE_ROOT}" = "y" ]; then
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

# Enable password authentication if requested
if [ "${ENABLE_PASS_AUTH}" = "y" ]; then
    sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
fi

sed -i 's/^source-directory \/run.*/##\0/g' /etc/network/interfaces
sed -i 's|inet dhcp|inet manual|g' /etc/network/cloud-interfaces-template
sed -i 's/^do_setup$/##\0/g' /etc/network/cloud-ifupdown-helper

# Install additional packages
apt-get update
apt-get install -y ${ADDITIONAL_PACKAGES}

# Enable services
systemctl enable cron
systemctl enable systemd-timesyncd

# Update system
apt-get update
apt-get -q -y upgrade
apt-get -y autoremove

# Note : Fix DNS Server :
systemctl disable --now systemd-resolved
rm -f /etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1\nnameserver 4.2.2.4\nnameserver 9.9.9.9" | tee /etc/resolv.conf

EOL

chmod +x init_script_debian-11.sh

# Customize the image
print_message "Customizing image..."
virt-customize -a "${DEBIAN_IMAGE_NAME}" --install qemu-guest-agent
virt-customize -a "${DEBIAN_IMAGE_NAME}" --run ./init_script_debian-11.sh

# Create VM
print_message "Creating VM template..."
qm create $TEMPLATE_ID --name "${VM_TEMPLATE_NAME}" --memory $VM_MEMORY --cores $VM_CORES --net0 ${VM_NET_MODEL},bridge=${VM_BRIDGE} --ostype "l26"
qm importdisk $TEMPLATE_ID "${DEBIAN_IMAGE_NAME}" $STORAGE
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

# Configure Cloud-Init settings
qm set $TEMPLATE_ID --ciuser "${CI_USER}"
qm set $TEMPLATE_ID --nameserver "${CI_DNS}"
qm set $TEMPLATE_ID --searchdomain "${CI_SEARCHDOMAIN}"
qm set $TEMPLATE_ID --ipconfig0 "${CI_IPCONFIG}"

# Convert to template
#print_message "Converting to template..."
#qm template $TEMPLATE_ID

# Cleanup
print_message "Cleaning up..."
rm -f "${DEBIAN_IMAGE_NAME}" init_script_debian-11.sh

#print_message "Template creation complete! Template ID: ${TEMPLATE_ID}"
#print_message "You can now create VMs from this template using:"
#print_message "qm clone ${TEMPLATE_ID} <new_vm_id> --name <new_vm_name>"
print_message "\ndone!\n"
