# Deploy Mikrotik on Proxmox
<img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/mikrotik-2.png" alt="Mikrotik on Proxmox" height="48" />

## Step 1 :
### 1- Create a VM as these settintgs via gui with these settings :
Note : you can use any name for `ID` and `Name`

- VM ID : `1002`
- Name : `mikrotik`
- In OS Tab : `Do not use any media`
- Guest OS Type: `Other`
- In Disks Tab:  `remove all disks`
- Network Model : `Intel E1000`

## Step 2 : 
### Goto console of proxmox and run these commands as root :
```
apt install -y libguestfs-tools unzip iptables-persistent

cd /var/lib/vz/images/

wget https://mehrdad.ariadata.co/notes/wp-content/uploads/2022/02/mikrotik6-routeros-kvm-disk.zip

unzip mikrotik6-routeros-kvm-disk.zip && rm -f mikrotik6-routeros-kvm-disk.zip

qm importdisk 100 mikrotik-routeros-kvm-disk.qcow2 local-lvm
```

## Step 3 :
### Goto gui and do these settings for VM :
- In hardware tab, double-click on **Unused Disk 0** , Choose `Bus/Device : IDE` , Add!
- In Options tab, Enable `Start at boot`
- In Boot Order : choose only `ide0` and drag it to first 
- Start the VM

## Step 4 :
### Goto console of VM and use login `admin` and empty password
Run these commands (when numbers asked, just enter 0 ):

change `password`,`ip`,`netmask` and `gateway` as you want :
```
user set password=MyPassword
interface ethernet reset-mac-address
ip address add address=192.168.88.2 netmask=255.255.255.0
ip route add gateway=192.168.88.1
ip dns set servers=1.1.1.1
/sys reboot
```

## Step 5 :
### Login with WinBox to server : https://mt.lv/winbox

Done!