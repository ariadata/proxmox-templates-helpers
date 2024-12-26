#!/bin/bash

# Define variables
VLAN_IP_PREFIX="10.0"
ROUTE_TO="10.0.16.1"
CONFIG_FILE="/etc/network/interfaces.d/50-cloud-init"
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

# Route lines to add (with exact spacing)
ROUTE_UP="    up ip route add ${VLAN_IP_PREFIX}.0.0/16 via ${ROUTE_TO}"
ROUTE_DOWN="    down ip route del ${VLAN_IP_PREFIX}.0.0/16 via ${ROUTE_TO}"

# Exit if interface not found
if [ -z "$INTERFACE" ]; then
    echo "Error: No interface with prefix ${VLAN_IP_PREFIX} found"
    exit 1
fi

# Create temporary file
TMP_FILE=$(mktemp)

# Process the file
in_target_interface=false
route_exists=false
current_section=""

while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if entering a new interface section
    if [[ $line =~ ^iface[[:space:]]+([^[:space:]]+)[[:space:]]+inet[[:space:]]+static$ ]]; then
        current_section="${BASH_REMATCH[1]}"
        # If this is our target interface
        if [[ $current_section == "$INTERFACE" ]]; then
            in_target_interface=true
        else
            in_target_interface=false
        fi
    fi
    
    # Check if route already exists (to prevent duplicates)
    if [[ $line == *"ip route add ${VLAN_IP_PREFIX}.0.0/16 via ${ROUTE_TO}"* ]]; then
        route_exists=true
        continue  # Skip this line to remove old route
    fi
    if [[ $line == *"ip route del ${VLAN_IP_PREFIX}.0.0/16 via ${ROUTE_TO}"* ]]; then
        continue  # Skip this line to remove old route
    fi
    
    # Write current line to temp file
    echo "$line" >> "$TMP_FILE"
    
    # Add routes after the address line if we're in the right interface
    if [[ $in_target_interface == true ]] && [[ $line =~ ^[[:space:]]+address[[:space:]] ]]; then
        # Only add if routes don't already exist
        if [[ $route_exists == false ]]; then
            echo "$ROUTE_UP" >> "$TMP_FILE"
            echo "$ROUTE_DOWN" >> "$TMP_FILE"
        fi
    fi
done < "$CONFIG_FILE"

# Check if any changes were made
if ! diff "$CONFIG_FILE" "$TMP_FILE" > /dev/null; then
    # Create backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak-$(date +%Y%m%d%H%M%S)"
    # Apply changes
    mv "$TMP_FILE" "$CONFIG_FILE"
    echo "Configuration updated successfully."
    echo "Routes added to interface $INTERFACE"
else
    rm "$TMP_FILE"
    if [[ $route_exists == true ]]; then
        echo "Routes already exist in configuration. No changes needed."
    else
        echo "No changes were made to the configuration."
    fi
fi

