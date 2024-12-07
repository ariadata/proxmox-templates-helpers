# File: run.sh
#!/bin/bash

# Source common files
source "common/config.sh"
source "common/functions.sh"
source "common/ui.sh"
source "common/cloud-init.sh"
source "common/os-prepare.sh"

# Function to dynamically load templates
load_templates() {
    local template_dir="templates"
    declare -gA TEMPLATES
    
    # Get list of template files
    local files=($(ls ${template_dir}/*.sh | sort))
    local index=1
    
    for file in "${files[@]}"; do
        # Get filename without path and extension
        local template_name=$(basename "$file" .sh)
        TEMPLATES[$index]="$template_name"
        
        # Source the template file to get its variables and functions
        source "$file"
        
        ((index++))
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Check if running on Proxmox
if ! command_exists pvesm; then
    print_error "This script must be run on Proxmox VE"
    exit 1
fi

# Load templates dynamically
load_templates

# Print welcome message
print_header "Proxmox Template Maker"

# Show available templates
show_templates

# Get template selection and validate
get_template_selection

# Get template ID
TEMPLATE_ID=$(get_template_id)
print_message "Template ID: $TEMPLATE_ID"

# Get SSH configuration
get_ssh_config

# Detect storage
STORAGE=$(detect_storage)
print_message "Detected storage: $STORAGE"

# Create template based on selection
create_template "$TEMPLATE_NAME" "$TEMPLATE_ID" "$STORAGE"

print_message "Template creation complete!"
