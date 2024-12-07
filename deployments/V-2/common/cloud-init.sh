#!/bin/bash

configure_cloud_init() {
    local template_id=$1
    local storage=$2
    
    print_message "Configuring Cloud-Init settings..."
    
    qm set $template_id --ide2 $storage:cloudinit
    qm set $template_id --ciuser "${CI_USER}"
    qm set $template_id --nameserver "${CI_DNS}"
    qm set $template_id --searchdomain "${CI_SEARCHDOMAIN}"
    qm set $template_id --ipconfig0 "${CI_IPCONFIG}"
}