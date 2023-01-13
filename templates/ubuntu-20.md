cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
virt-customize -a focal-server-cloudimg-amd64.img --root-password password:abcd_123456

qm create 999 --name "ubuntu-2004-cloudinit-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 999 focal-server-cloudimg-amd64.img local
qm set 999 --scsihw virtio-scsi-pci --scsi0 local:999/vm-999-disk-0.raw
qm set 999 --boot c --bootdisk scsi0
qm set 999 --ide2 local:cloudinit
qm set 999 --serial0 socket --vga serial0
qm set 999 --agent enabled=1

qm template 999

qm clone 999 199 --name test-clone-cloud-init
#qm set 199 --sshkey ~/.ssh/id_rsa.pub
qm set 199 --ipconfig0 ip=192.168.18.3/24,gw=192.168.18.1
qm start 199
#ssh root@192.168.18.3
qm stop 199 && qm destroy 199
rm focal-server-cloudimg-amd64.img