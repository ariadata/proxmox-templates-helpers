#!/bin/bash

# Get the directory where the script is located and resolve paths
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
COMMON_DIR="$(readlink -f "${SCRIPT_DIR}/../common")"

# Source common scripts with absolute paths
source "${COMMON_DIR}/config.sh"
source "${COMMON_DIR}/functions.sh"
source "${COMMON_DIR}/cloud-init.sh"
source "${COMMON_DIR}/os-prep.sh"

# Debian 11 specific configuration
DEBIAN_IMAGE_URL="https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
DEBIAN_IMAGE_NAME="debian-11-generic-amd64.qcow2"
VM_TEMPLATE_NAME="debian-11-template"

# Additional packages for Debian
ADDITIONAL_PACKAGES="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent \
    apt-transport-https ca-certificates software-properties-common jq \
    systemd-timesyncd cron htop zstd"

create_template() {
    print_header "Creating Debian 11 Template"
    
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

    # Get template ID
    TEMPLATE_ID=$(validate_template_id)

    # Get SSH configuration
    get_ssh_config

    # Detect storage
    STORAGE=$(detect_storage)
    print_message "Detected storage: $STORAGE"

    # Create working directory if it doesn't exist
    mkdir -p $TEMPLATE_WORKING_DIR
    cd $TEMPLATE_WORKING_DIR || exit 1

    # Download Debian cloud image with progress spinner
    print_message "Downloading Debian 11 cloud image..."
    wget -q --show-progress "${DEBIAN_IMAGE_URL}" 2>&1 | while read line; do
        echo -ne "\r\033[K${GREEN}[INFO]${NC} Downloading: $line"
    done
    echo

    # Resize the disk image
    print_message "Resizing disk image to ${VM_DISK_SIZE}GB..."
    qemu-img resize "${DEBIAN_IMAGE_NAME}" "${VM_DISK_SIZE}G"

    # Prepare OS (install packages, configure SSH, etc.)
    prepare_debian_based "${DEBIAN_IMAGE_NAME}" "${SSH_PORT}" "${ENABLE_ROOT}" \
        "${ENABLE_PASS_AUTH}" "${ADDITIONAL_PACKAGES}"

    # Create VM
    print_message "Creating VM template..."
    qm create $TEMPLATE_ID \
        --name "${VM_TEMPLATE_NAME}" \
        --memory $VM_MEMORY \
        --cores $VM_CORES \
        --net0 ${VM_NET_MODEL},bridge=${VM_BRIDGE} \
        --ostype "${VM_OSTYPE}"

    qm importdisk $TEMPLATE_ID "${DEBIAN_IMAGE_NAME}" $STORAGE
    qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
    qm set $TEMPLATE_ID --boot c --bootdisk scsi0
    qm set $TEMPLATE_ID --serial0 socket --vga serial0
    qm set $TEMPLATE_ID --agent enabled=1

    # Configure cloud-init
    configure_cloud_init $TEMPLATE_ID $STORAGE

    # Convert to template
    print_message "Converting to template..."
    qm template $TEMPLATE_ID

    # Cleanup
    print_message "Cleaning up..."
    rm -f "${DEBIAN_IMAGE_NAME}"

    print_message "Template creation complete! Template ID: ${TEMPLATE_ID}"
    print_message "You can now create VMs from this template using:"
    print_message "qm clone ${TEMPLATE_ID} <new_vm_id> --name <new_vm_name>"
}