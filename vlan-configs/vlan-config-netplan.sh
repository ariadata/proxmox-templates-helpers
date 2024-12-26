#!/bin/bash

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Pretty print functions
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✘ $1${NC}"
}

# Define variables
VLAN_IP_PREFIX="10.0"
ROUTE_TO="10.0.16.1"
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

print_header "Network Route Configuration Tool"

# Exit if interface not found
if [ -z "$INTERFACE" ]; then
    print_error "No interface with prefix ${VLAN_IP_PREFIX} found"
    exit 1
fi

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

print_header "Configuration Process"

# Set the route using netplan
echo -e "${BLUE}➜ Configuring netplan for interface ${BOLD}${INTERFACE}${NC}..."
netplan set ethernets.${INTERFACE}.routes="[{\"to\":\"${VLAN_IP_PREFIX}.0.0/16\", \"via\": \"${ROUTE_TO}\"}]"

if [ $? -eq 0 ]; then
    print_success "Route configuration set"
    
    echo -e "\n${BLUE}➜ Applying netplan configuration...${NC}"
    netplan apply

    # Wait a moment for routes to be applied
    sleep 2

    # Verify route exists
    if ip route show dev ${INTERFACE} | grep -q "${VLAN_IP_PREFIX}.0.0/16"; then
        echo -e "\n${GREEN}╔══════════════════════════════════════╗"
        echo -e "║   Netplan configuration applied       ║"
        echo -e "║          successfully! 🚀             ║"
        echo -e "╚══════════════════════════════════════╝${NC}"

        print_header "Current Routes"
        echo -e "${BLUE}Routes for interface ${BOLD}${INTERFACE}${NC}:"
        echo "----------------------------------------"
        ip route show dev ${INTERFACE} | while read -r line; do
            echo -e "  ${BOLD}${line}${NC}"
        done
        echo "----------------------------------------"
    else
        print_error "Route was not applied successfully"
        echo -e "\nCurrent routes:"
        ip route show dev ${INTERFACE}
        exit 1
    fi
else
    print_error "Failed to set netplan configuration"
    exit 1
fi