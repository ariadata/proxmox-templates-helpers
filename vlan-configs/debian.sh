#!/bin/bash

# Dynamically detect the interface with an IP in the 10.0.x.x range
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

# Check if an interface was found
if [ -n "$INTERFACE" ]; then
    echo "Found interface: $INTERFACE"

    # Write the dynamic VLAN configuration to Cloud-Init
    cat <<EOF | sudo tee /etc/cloud/cloud.cfg.d/99_custom-config.cfg
#cloud-config
runcmd:
  - ip link set mtu 1400 dev $INTERFACE
  - ip route add 10.0.0.0/16 via 10.0.16.1 dev $INTERFACE
EOF

    # Clean and reinitialize Cloud-Init to apply the new configuration
    cloud-init clean
    cloud-init init
    cloud-init modules --mode=config
    cloud-init modules --mode=final

    echo "Configuration applied successfully for interface: $INTERFACE"
else
    echo "No interface found with an IP in the 10.0.x.x range. Exiting."
    exit 1
fi