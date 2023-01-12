#!/bin/sh
sed -i 's/^PasswordAuthentication.*/##\0/g' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/##\0/g' /etc/ssh/sshd_config
sed -i 's/^Port.*/##\0/g' /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'Port 6070' >> /etc/ssh/sshd_config
