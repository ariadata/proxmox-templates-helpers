# Create Template for Rocky-Linux-8
[![Build Status](https://files.ariadata.co/file/ariadata_logo.png)](https://ariadata.co)

![](https://img.shields.io/github/stars/ariadata/proxmox-templates-helpers.svg)
![](https://img.shields.io/github/watchers/ariadata/proxmox-templates-helpers.svg)
![](https://img.shields.io/github/forks/ariadata/proxmox-templates-helpers.svg)


### ✅ Run these commands as `root` in proxmox shel :
```sh
cd /var/lib/vz/template/iso
wget https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud.latest.x86_64.qcow2
wget https://github.com/ariadata/proxmox-templates-helpers/raw/main/static/91-RockyLinux8.cfg 91-RockyLinux.cfg
virt-customize -a Rocky-8-GenericCloud.latest.x86_64.qcow2 --install qemu-guest-agent,nano,sudo,rsync

virt-customize -a Rocky-8-GenericCloud.latest.x86_64.qcow2 --copy-in 91-RockyLinux.cfg:/etc/cloud/cloud.cfg.d/

qm create 995 --name "RockyLinux-8-Template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1
qm importdisk 995 Rocky-8-GenericCloud.latest.x86_64.qcow2 local-zfs
qm set 995 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-995-disk-0
qm set 995 --boot c --bootdisk scsi0
qm set 995 --ide2 local-zfs:cloudinit
qm set 995 --serial0 socket --vga serial0
qm set 995 --agent enabled=1
```

---

