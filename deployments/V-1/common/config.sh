#!/bin/bash

# Base VM Configuration
VM_MEMORY=1024           # Memory in MB
VM_CORES=1               # Number of CPU cores
VM_DISK_SIZE=10         # Disk size in GB
VM_OSTYPE="l26"         # Linux 2.6+ kernel
VM_BRIDGE="vmbr1"       # Network bridge
VM_NET_MODEL="virtio"   # Network card model

# Cloud-Init Settings
CI_USER="root"
CI_DNS="1.1.1.1"
CI_SEARCHDOMAIN=""
CI_IPCONFIG="ip=dhcp"

# SSH Configuration
DEFAULT_SSH_PORT=22

# Working Directory
TEMPLATE_WORKING_DIR="/var/lib/vz/template/iso"
