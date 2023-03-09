# Create SMB Server with Cockpit
### Create an SMB server with cockpit on Proxmox using Debian 11 LXC container.
<img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/LXC.png" alt="Debian LXC" height="48" /> <img src="https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/static/icons/smb-debian.png" alt="SMB on Debian" height="48" />

Based on [this](https://www.youtube.com/watch?v=Hu3t8pcq8O0) tutorial.

## 1️⃣ Create LXC container with Debian 11 template.

## 2️⃣ Run these commands as `root` inside LXC container:
```sh
apt update && apt upgrade -y && apt autoremove -y
echo "deb http://deb.debian.org/debian bullseye-backports main contrib" | sudo tee -a /etc/apt/sources.list
apt install -t bullseye-backports systemctl cockpit --no-install-recommends -y
sed -i "s|root|# root\n|g" /etc/cockpit/disallowed-users
systemctl enable --now cockpit.socket
```

## 3️⃣ Add custom cockpoit plugins:
we will use these plugins:
- [file-sharing](https://github.com/45Drives/cockpit-file-sharing)
- [navigator](https://github.com/45Drives/cockpit-navigator)
- [identities](https://github.com/45Drives/cockpit-identities)
```sh
## you may need to download latest version of plugins with links above
wget https://github.com/45Drives/cockpit-file-sharing/releases/download/v3.3.1/cockpit-file-sharing_3.3.1-1focal_all.deb
wget https://github.com/45Drives/cockpit-navigator/releases/download/v0.5.10/cockpit-navigator_0.5.10-1focal_all.deb
wget https://github.com/45Drives/cockpit-identities/releases/download/v0.1.10/cockpit-identities_0.1.10-1focal_all.deb

apt install -y ./*.deb && rm -f *.deb
```

## 4️⃣ Goto `https://<your-ip>:9090` and login with `root` user.

## 5️⃣ Goto "File Sharing" and fix permissions

## 6️⃣ Now edit user and make share

