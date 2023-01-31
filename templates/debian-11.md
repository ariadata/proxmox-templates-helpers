# Create Template of Debian 11
<img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/debian.png" alt="Debian on Proxmox" height="48" />

### ✅ Run these commands as `root` in proxmox shel (change as you need!) :
```sh
cd /var/lib/vz/template/iso

wget https://cloud.debian.org/cdimage/cloud/bullseye/latest/debian-11-generic-amd64.qcow2
wget https://github.com/ariadata/proxmox-templates-helpers/raw/main/static/init_command_debian_11.sh init_command_debian_11.sh

virt-customize -a debian-11-generic-amd64.qcow2 --install qemu-guest-agent,nano,sudo,rsync
virt-customize -a debian-11-generic-amd64.qcow2 --run init_command_debian_11.sh

qm create 996 --name "debian-11-generic-amd64-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1
qm importdisk 996 debian-11-generic-amd64.qcow2 local-zfs
qm set 996 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-996-disk-0
qm set 996 --boot c --bootdisk scsi0
qm set 996 --ide2 local-zfs:cloudinit
qm set 996 --serial0 socket --vga serial0
qm set 996 --agent enabled=1

qm template 996

```
---

### ✅ Basic commands after VM initialized :
#### run these commands as `root` user inside VM :
```sh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bk
sed -i 's/#Port 22/Port 6070/g' /etc/ssh/sshd_config
systemctl restart sshd

hostnamectl set-hostname hostname-254

timedatectl set-timezone Europe/Istanbul

reboot

```

### ✅ Config VLAN 4000 with MTU=1400 example (after VM initialized) :
#### run these commands as `root` user inside VM :

Assume that the network is eth1 , [example vlan route file](https://github.com/ariadata/proxmox-templates-helpers/blob/main/static/), change commands as you need.

```sh
nano /etc/network/interfaces.d/50-cloud-init
### add this lines (edit as you need)
mtu 1400
up ip route add 10.0.0.0/16 via 10.0.16.1
down ip route del 10.0.0.0/16 via 10.0.16.1

## restart network or reboot
systemctl restart networking

```