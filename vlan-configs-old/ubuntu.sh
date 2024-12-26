#!/bin/bash

# Dynamically detect the interface with an IP in the 10.0.x.x range
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

# Check if an interface was found
if [ -n "$INTERFACE" ]; then
    echo "Found interface: $INTERFACE"

    # Backup the current Netplan configuration
    NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
    BACKUP_FILE="/etc/netplan/50-cloud-init.yaml.bak"
    sudo cp "$NETPLAN_FILE" "$BACKUP_FILE"
    echo "Backup created at $BACKUP_FILE"

    # Get the current IP address of the detected interface
    IP_ADDRESS=$(ip -o -4 addr show "$INTERFACE" | awk '{print $4}')

    # Write the dynamic VLAN configuration to the Netplan file
    sudo cat <<EOF > $NETPLAN_FILE
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - $IP_ADDRESS
      routes:
        - to: 10.0.0.0/16
          via: 10.0.16.1
      mtu: 1400
EOF

    echo "Netplan configuration updated for interface: $INTERFACE"

    # Apply the new Netplan configuration
    sudo netplan apply
    echo "Netplan configuration applied successfully for interface: $INTERFACE"
else
    echo "No interface found with an IP in the 10.0.x.x range. Exiting."
    exit 1
fi
