#!/bin/bash

prepare_debian_based() {
    local image_path=$1
    local ssh_port=$2
    local enable_root=$3
    local enable_pass_auth=$4
    local packages=$5

    cat > init_script.sh << EOL
#!/bin/bash

# Configure SSH
sed -i "s/#Port 22/Port ${ssh_port}/" /etc/ssh/sshd_config

# Enable root login if requested
if [ "${enable_root}" = "y" ]; then
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

# Enable password authentication if requested
if [ "${enable_pass_auth}" = "y" ]; then
    sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
fi

# Install additional packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ${packages}

# Enable services
systemctl enable cron
systemctl enable systemd-timesyncd

# Update system
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade
apt-get -y autoremove

# Set DNS server
echo "nameserver ${CI_DNS}" > /etc/resolv.conf
EOL

    chmod +x init_script.sh
    
    print_message "Customizing image..."
    virt-customize -a "${image_path}" --install qemu-guest-agent
    virt-customize -a "${image_path}" --run ./init_script.sh
    
    rm -f init_script.sh
}
