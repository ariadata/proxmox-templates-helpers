#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source common scripts with absolute paths
source "${SCRIPT_DIR}/common/config.sh"
source "${SCRIPT_DIR}/common/ui.sh"
source "${SCRIPT_DIR}/common/functions.sh"

# Available templates with numbers
declare -A TEMPLATES=(
    [1]="debian-11"
    [2]="ubuntu-20-04"
    [3]="ubuntu-22-04"
    [4]="ubuntu-24-04"
    [5]="rocky-8"
)

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

print_message "Selected template: ${GREEN}${TEMPLATE_NAME}${NC}"
echo

# Execute selected template
source "${SCRIPT_DIR}/templates/${TEMPLATE_NAME}.sh"
create_template
