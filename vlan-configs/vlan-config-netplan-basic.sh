#!/bin/bash

# Define variables
VLAN_IP_PREFIX="10.0"
ROUTE_TO="10.0.16.1"
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

# Exit if interface not found
if [ -z "$INTERFACE" ]; then
    echo "Error: No interface with prefix ${VLAN_IP_PREFIX} found"
    exit 1
fi

# Function to check if route already exists
check_existing_route() {
    local output=$(netplan get ethernets.${INTERFACE}.routes 2>/dev/null)
    if [[ $output == *"${VLAN_IP_PREFIX}.0.0/16"* ]] && [[ $output == *"${ROUTE_TO}"* ]]; then
        return 0  # Route exists
    fi
    return 1  # Route doesn't exist
}

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Main logic
if check_existing_route; then
    echo "Route already exists for interface ${INTERFACE}"
else
    echo "Adding route to interface ${INTERFACE}..."
    
    # Set the route using netplan
    netplan set ethernets.${INTERFACE}.routes="[{\"to\":\"${VLAN_IP_PREFIX}.0.0/16\", \"via\": \"${ROUTE_TO}\"}]"
    
    if [ $? -eq 0 ]; then
        echo "Route configuration added successfully"
        
        # Apply the changes
        echo "Applying netplan configuration..."
        netplan apply
        
        if [ $? -eq 0 ]; then
            echo "Netplan configuration applied successfully"
            
            # Verify route exists
            if ip route | grep -q "${VLAN_IP_PREFIX}.0.0/16"; then
                echo "Route verification successful"
            else
                echo "Warning: Route not found in routing table after apply"
            fi
        else
            echo "Error: Failed to apply netplan configuration"
            exit 1
        fi
    else
        echo "Error: Failed to set netplan configuration"
        exit 1
    fi
fi

# Show current routes for verification
echo -e "\nCurrent routes for ${INTERFACE}:"
ip route show dev ${INTERFACE}