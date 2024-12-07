#!/bin/bash
set -e
cd "$(dirname "$0")"


# define some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Available templates with numbers
declare -A TEMPLATES=(
    [1]="debian-11"
    [1]="debian-12"
    [3]="ubuntu-20"
    [4]="ubuntu-22"
    [5]="ubuntu-24"
    [6]="rocky-8"
)

# template URLs
declare -A TEMPLATE_URLS=(
    [debian-11]="https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
    [debian-12]="https://cloud.debian.org/cdimage/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
    [ubuntu-20]="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
    [ubuntu-22]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    [ubuntu-24]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    [rocky-8]="https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud.latest.x86_64.qcow2"
)

declare -A TEMPLATE_CODENAMES=(
    [debian-11]="bullseye"
    [debian-12]="bookworm"
    [ubuntu-20]="focal"
    [ubuntu-22]="jammy"
    [ubuntu-24]="noble"
    [rocky-8]="rocky-8"
)

declare -A TEMPLATE_NAMES=(
    [debian-11]="debian-11-template"
    [debian-12]="debian-12-template"
    [ubuntu-20]="ubuntu-20-template"
    [ubuntu-22]="ubuntu-22-template"
    [ubuntu-24]="ubuntu-24-template"
    [rocky-8]="rocky-8-template"
)

declare -A TEMPLATE_PREPARE_PACKAGES=(
    [debian-11]="apt update && apt upgrade -yq"
    [debian-12]="apt update && apt upgrade -yq"
    [ubuntu-20]="apt update && apt upgrade -yq"
    [ubuntu-22]="apt update && apt upgrade -yq"
    [ubuntu-24]="apt update && apt upgrade -yq"
    [rocky-8]="dnf update -y && dnf install -y epel-release && dnf update -y"
)

declare -A TEMPLATE_EXTRA_PACKAGES=(
    [debian-11]="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent apt-transport-https ca-certificates software-properties-common jq systemd-timesyncd cron htop zstd"
    [debian-12]="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent apt-transport-https ca-certificates software-properties-common jq systemd-timesyncd cron htop zstd"
    [ubuntu-20]="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent apt-transport-https ca-certificates software-properties-common jq systemd-timesyncd cron htop zstd"
    [ubuntu-22]="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent apt-transport-https ca-certificates software-properties-common jq systemd-timesyncd cron htop zstd"
    [ubuntu-24]="wget curl git rsync nano lsb-release sqlite3 p7zip gnupg-agent apt-transport-https ca-certificates software-properties-common jq systemd-timesyncd cron htop zstd"
    [rocky-8]="wget curl git rsync nano sqlite p7zip p7zip-plugins gnupg2 ca-certificates cronie chrony htop zstd"
)

declare -A TEMPLATE_AFTER_PACKAGES_INSTALLED=(
    [debian-11]="systemctl enable --now systemd-timesyncd cron"
    [debian-12]="systemctl enable --now systemd-timesyncd cron"
    [ubuntu-20]="systemctl enable --now systemd-timesyncd cron"
    [ubuntu-22]="systemctl enable --now systemd-timesyncd cron"
    [ubuntu-24]="systemctl enable --now systemd-timesyncd cron"
    [rocky-8]="systemctl enable --now chronyd crond"
)



# functions
function info_msg() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

function warn_msg() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

function error_msg() {
  echo -e "${RED}[ERROR]${NC} $1"
}

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# PVE functions
detect_storage() {
    local storages=$(pvesm status -content images | awk 'NR>1 {print $1}')
    if echo "$storages" | grep -q "local-zfs"; then
        echo "local-zfs"
    elif echo "$storages" | grep -q "local"; then
        echo "local"
    else
        echo "$storages" | head -n1
    fi
}

# Function to get and validate template ID
get_template_id() {
    while true; do
        read -p "Enter template ID (100-999): " TEMPLATE_ID
        if [[ $TEMPLATE_ID =~ ^[1-9][0-9]{2}$ && $TEMPLATE_ID -le 999 ]]; then
            if ! qm status $TEMPLATE_ID >/dev/null 2>&1; then
                break
            else
                error_msg "Template ID $TEMPLATE_ID already exists. Please choose another ID."
            fi
        else
            error_msg "Please enter a valid template ID between 100 and 999."
        fi
    done
    echo $TEMPLATE_ID
}


# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "Please run as ${RED}root${NC} user, not ${YELLOW}$(whoami)${NC} or not even with ${YELLOW}sudo${NC} command"
  exit
fi

# Check if the script is being run on Proxmox VE
if ! command_exists pvesm; then
    error_msg "This script must be run on Proxmox VE"
    exit
fi


# Show available templates
print_header "Available Templates"
for number in "${!TEMPLATES[@]}"; do
    printf "%2d) ${GREEN}%s${NC}\n" "$number" "${TEMPLATES[$number]}"
done
echo

# Get template selection
while true; do
    read -p "Select template number (1-${#TEMPLATES[@]}): " TEMPLATE_NUMBER
    if [[ "$TEMPLATE_NUMBER" =~ ^[1-9]+$ ]] && [ -n "${TEMPLATES[$TEMPLATE_NUMBER]}" ]; then
        TEMPLATE_NAME="${TEMPLATES[$TEMPLATE_NUMBER]}"
        break
    else
        print_error "Invalid selection. Please enter a number between 1 and ${#TEMPLATES[@]}"
    fi
done


#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Spinner characters
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Function to show spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Message functions
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    local text="$1"
    local width=50
    local padding=$(( (width - ${#text}) / 2 ))
    echo
    printf "%${width}s\n" | tr ' ' '='
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
    printf "%${width}s\n" | tr ' ' '='
    echo
}

# Progress bar function
show_progress() {
    local duration=$1
    local width=50
    local progress=0
    local step=$(( 100 / $duration ))
    
    while [ $progress -le 100 ]; do
        local completed=$(( $width * $progress / 100 ))
        local remaining=$(( $width - $completed ))
        printf "\rProgress: [${GREEN}%${completed}s${NC}%${remaining}s] ${progress}%%" "" ""
        progress=$(( progress + step ))
        sleep 1
    done
    echo
}




# Detect storage
STORAGE=$(detect_storage)
info_msg "Detected storage: $STORAGE"

TEMPLATE_ID=$(get_template_id)
info_msg "Template ID: $TEMPLATE_ID"


