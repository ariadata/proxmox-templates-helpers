# Create Template of Rocky-Linux-8
<img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/rocky.png" alt="Rocky Linux on Proxmox" height="48" />

### ✅ Run these commands as `root` in proxmox shel (change as you need!) :
```sh
cd /var/lib/vz/template/iso
wget https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud.latest.x86_64.qcow2
wget https://github.com/ariadata/proxmox-templates-helpers/raw/main/static/91-RockyLinux8.cfg -O 91-RockyLinux.cfg
virt-customize -a Rocky-8-GenericCloud.latest.x86_64.qcow2 --install qemu-guest-agent,nano,sudo,rsync

virt-customize -a Rocky-8-GenericCloud.latest.x86_64.qcow2 --copy-in 91-RockyLinux.cfg:/etc/cloud/cloud.cfg.d/

qm create 995 --name "RockyLinux-8-Template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1
qm importdisk 995 Rocky-8-GenericCloud.latest.x86_64.qcow2 local-zfs
qm set 995 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-995-disk-0
qm set 995 --boot c --bootdisk scsi0
qm set 995 --ide2 local-zfs:cloudinit
qm set 995 --serial0 socket --vga serial0
qm set 995 --agent enabled=1

qm template 995

```
---

### ✅ Basic commands after VM initialized :
#### run these commands as `root` user inside VM :
```sh
cp /etc/selinux/config /etc/selinux/config.bk
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bk
sed -i 's/#Port 22/Port 6070/g' /etc/ssh/sshd_config
setenforce 0
service sshd restart

hostnamectl set-hostname hostname-254

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

systemctl disable --now rpcbind rpcbind.socket

systemctl disable --now firewalld

timedatectl set-timezone Europe/Istanbul

dnf install -y aria2 bind-utils chrony fcgi git htop httpd-tools iotop iperf3 lsof net-tools nmap numactl poppler-utils sysstat traceroute unzip wget yum-utils zip curl nano sqlite p7zip ca-certificates

dnf update -y

reboot

```

### ✅ Config VLAN 4000 with MTU=1400 example (after VM initialized) :
#### run these commands as `root` user inside VM :

Assume that the network is eth1 , [example vlan route file](https://github.com/ariadata/proxmox-templates-helpers/blob/main/static/rockt8-example-route-eth1), change commands as you need.

```sh
curl -L "https://github.com/ariadata/proxmox-templates-helpers/raw/main/static/rockt8-example-route-eth1" -o /etc/sysconfig/network-scripts/route-eth1

echo "MTU=1400" >> /etc/sysconfig/network-scripts/ifcfg-eth1

systemctl restart NetworkManager

dnf update -y

reboot

```
