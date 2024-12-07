#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Import color definitions and UI elements with correct path
source "${SCRIPT_DIR}/ui.sh"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect storage
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

# Function to validate template ID
validate_template_id() {
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
    echo $TEMPLATE_ID
}

# Function to get SSH configuration
get_ssh_config() {
    read -p "Enter SSH port number [default: ${DEFAULT_SSH_PORT}]: " SSH_PORT
    SSH_PORT=${SSH_PORT:-$DEFAULT_SSH_PORT}
    
    read -p "Enable root login? (y/n): " ENABLE_ROOT
    ENABLE_ROOT=$(echo "$ENABLE_ROOT" | tr '[:upper:]' '[:lower:]')
    
    read -p "Enable password authentication? (y/n): " ENABLE_PASS_AUTH
    ENABLE_PASS_AUTH=$(echo "$ENABLE_PASS_AUTH" | tr '[:upper:]' '[:lower:]')
}
