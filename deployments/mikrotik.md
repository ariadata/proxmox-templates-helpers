#under design


<img src="" width="48" height="48" />

## Create a VM as these settintgs via gui :
# VM ID : 100
# Name : mikrotik-18.2
# in OS Tab : Do not use any media
# Guest OS Type: Other
# in Disks Tab remove all disks
# Network Model : Intel E1000
# after cteated use command :
cd /var/lib/vz/images/
wget https://mehrdad.ariadata.co/notes/wp-content/uploads/2022/02/mikrotik6-routeros-kvm-disk.zip
# wget https://files.ariadata.co/file/mikrotik6-routeros-kvm-disk.zip

unzip mikrotik6-routeros-kvm-disk.zip && rm -f mikrotik6-routeros-kvm-disk.zip
qm importdisk 100 mikrotik-routeros-kvm-disk.qcow2 local
# Goto hardware tab using gui
# Double Click on "Unused Disk 0" , Choose Bus/Device : IDE , Add!
# Goto Options tab using gui : 
# Enable "Start at boot"
# In Boot Order : choose only ide0 and drag it to first
# Goto Console tab and Start the VM
# Login in console via user admin and empty password
# Change router password (for numbers enter 0 ):
user set password=MyPassword
# interface ethernet reset-mac-address ether2
ip address add address=192.168.18.2 netmask=255.255.255.0 interface=ether2
ip route add gateway=192.168.18.1
# ip dns set servers=1.1.1.1

# Login with WinBox to server : https://mt.lv/winbox
142.132.195.122:8999
admin
MyPassword