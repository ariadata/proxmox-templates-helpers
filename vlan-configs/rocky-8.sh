#!/bin/bash

# Dynamically detect the interface with an IP in the 10.0.x.x range
INTERFACE=$(ip -o -4 addr show | awk '/10\.0\./ {print $2}')

# Check if an interface was found
if [ -n "$INTERFACE" ]; then
    echo "Found interface: $INTERFACE"
    
    # Get the current IP address of the detected interface
    IP_ADDRESS=$(ip -o -4 addr show "$INTERFACE" | awk '{print $4}')
    IP_ADDR=${IP_ADDRESS%/*}  # Remove CIDR notation
    
    # Create the network interface configuration
    cat <<EOF | sudo tee /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=$INTERFACE
DEVICE=$INTERFACE
ONBOOT=yes
IPADDR=$IP_ADDR
PREFIX=24
MTU=1400
EOF
    
    # Create the route configuration
    echo "10.0.0.0/16 via 10.0.16.1 dev $INTERFACE" | sudo tee /etc/sysconfig/network-scripts/route-$INTERFACE
    
    # Restart NetworkManager to apply changes
    sudo systemctl restart NetworkManager
    
    echo "Configuration applied successfully for interface: $INTERFACE"
    echo "IP Address: $IP_ADDRESS"
    echo "MTU: 1400"
    echo "Static route: 10.0.0.0/16 via 10.0.16.1"
else
    echo "No interface found with an IP in the 10.0.x.x range. Exiting."
    exit 1
fi
