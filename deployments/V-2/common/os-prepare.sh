#!/bin/bash

prepare_debian() {
    local image=$1
    local extra_packages=$2
    local prepare_cmd=$3
    local after_cmd=$4
    
    print_message "Preparing Debian/Ubuntu image..."
    
    # Install base packages
    virt-customize -a "$image" --install qemu-guest-agent
    
    # Run prepare command
    virt-customize -a "$image" --run-command "$prepare_cmd"
    
    # Install extra packages
    virt-customize -a "$image" --install "$extra_packages"
    
    # Run after-install commands
    virt-customize -a "$image" --run-command "$after_cmd"
}

prepare_rocky() {
    local image=$1
    local extra_packages=$2
    local prepare_cmd=$3
    local after_cmd=$4
    
    print_message "Preparing Rocky Linux image..."
    
    virt-customize -a "$image" --install qemu-guest-agent
    virt-customize -a "$image" --run-command "$prepare_cmd"
    virt-customize -a "$image" --install "$extra_packages"
    virt-customize -a "$image" --run-command "$after_cmd"
}