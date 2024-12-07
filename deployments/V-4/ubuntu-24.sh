#!/bin/bash

###########################################
# Configuration Variables - Ubuntu 24.04
###########################################

# VM Resources
VM_MEMORY=1024           # Memory in MB
VM_CORES=1               # Number of CPU cores
VM_DISK_SIZE=10         # Disk size in GB
VM_TEMPLATE_NAME="ubuntu-24-template"  # Template name

# Network Configuration
VM_BRIDGE="vmbr1"       # Network bridge
VM_NET_MODEL="virtio"   # Network card model

# Cloud-Init Default Settings
CI_USER="root"          # Default cloud-init user
CI_DNS="1.1.1.1"        # Default DNS server
CI_SEARCHDOMAIN=""      # Default search domain
CI_IPCONFIG="ip=dhcp"   # Default IP configuration

# Image Source
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
UBUNTU_IMAGE_NAME="noble-server-cloudimg-amd64.img"

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
export SSH_PORT

# Prompt for root login configuration
read -e -p $'Enable \e[33mroot login\033[0m (y/n): ' -i "y" ENABLE_ROOT
ENABLE_ROOT=$(echo "$ENABLE_ROOT" | tr '[:upper:]' '[:lower:]')
export ENABLE_ROOT

# Prompt for password authentication
read -e -p $'Enable \e[33mpassword authentication\033[0m (y/n): ' -i "y" ENABLE_PASS_AUTH
ENABLE_PASS_AUTH=$(echo "$ENABLE_PASS_AUTH" | tr '[:upper:]' '[:lower:]')
export ENABLE_PASS_AUTH

# Detect storage
STORAGE=$(detect_storage)
print_message "Detected storage: $STORAGE"

# Set working directory
cd $TEMPLATE_WORKING_DIR || exit 1

# Download Ubuntu cloud image
print_message "Downloading Ubuntu 24.04 cloud image..."
wget -q --show-progress "${UBUNTU_IMAGE_URL}"

# Resize the disk image
print_message "Resizing disk image to ${VM_DISK_SIZE}GB..."
qemu-img resize "${UBUNTU_IMAGE_NAME}" "${VM_DISK_SIZE}G"

# Create initialization script
cat > init_script.sh << EOF
#!/bin/bash

# Configure SSH
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i "s/Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config  # In case it's not commented out

# Configure SSH authentication
if [ "${ENABLE_ROOT}" = "y" ]; then
    # Enable root login more aggressively
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config  # Add it again to be sure
    sed -i 's/^#\?AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
    
    # Set root password (required for Ubuntu 24.04)
    echo "root:root" | chpasswd
fi

if [ "${ENABLE_PASS_AUTH}" = "y" ]; then
    # Configure password authentication more explicitly
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config  # Add it again to be sure
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
    
    # Ensure password login works
    sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
fi

# Ensure PubkeyAuthentication is enabled
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Disable StrictModes which can prevent root login in some cases
sed -i 's/^#\?StrictModes.*/StrictModes no/' /etc/ssh/sshd_config

# Install additional packages
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ${ADDITIONAL_PACKAGES}

# Enable services
systemctl enable cron
systemctl enable systemd-timesyncd

# Update system
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

# Configure DNS properly for Ubuntu 24.04
systemctl disable --now systemd-resolved.service
rm -f /etc/resolv.conf
echo "nameserver ${CI_DNS}" > /etc/resolv.conf
EOF

chmod +x init_script.sh

# Customize the image
print_message "Customizing image..."
virt-customize -a "${UBUNTU_IMAGE_NAME}" --install qemu-guest-agent
virt-customize -a "${UBUNTU_IMAGE_NAME}" --run ./init_script.sh

# Create VM
print_message "Creating VM template..."
qm create $TEMPLATE_ID --name "${VM_TEMPLATE_NAME}" --memory $VM_MEMORY --cores $VM_CORES --net0 ${VM_NET_MODEL},bridge=${VM_BRIDGE} --ostype "l26"
qm importdisk $TEMPLATE_ID "${UBUNTU_IMAGE_NAME}" $STORAGE
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
print_message "Converting to template..."
qm template $TEMPLATE_ID

# Cleanup
print_message "Cleaning up..."
rm -f "${UBUNTU_IMAGE_NAME}" init_script.sh

print_message "Template creation complete! Template ID: ${TEMPLATE_ID}"
print_message "You can now create VMs from this template using:"
print_message "qm clone ${TEMPLATE_ID} <new_vm_id> --name <new_vm_name>"
print_message "\ndone!\n"