# Create Template of Ubuntu 20.04
<img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/ubuntu.png" alt="Ubuntu on Proxmox" height="48" />

### ✅ Run these commands as `root` in proxmox shel (change as you need!) :
```sh
cd /var/lib/vz/template/iso

wget -O ubuntu-20.04-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

virt-customize -a ubuntu-20.04-server-cloudimg-amd64.img --install qemu-guest-agent,nano,sudo,rsync
virt-customize -a ubuntu-20.04-server-cloudimg-amd64.img --run-command "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config"


virt-customize -a ubuntu-20.04-server-cloudimg-amd64.img --run-command "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config"
qm create 998 --name "ubuntu-20.04-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1
qm importdisk 998 ubuntu-20.04-server-cloudimg-amd64.img local-zfs
qm set 998 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-998-disk-0
qm set 998 --boot c --bootdisk scsi0
qm set 998 --ide2 local-zfs:cloudinit
qm set 998 --serial0 socket --vga serial0
qm set 998 --agent enabled=1
qm template 998

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
