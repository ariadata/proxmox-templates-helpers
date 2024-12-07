# VLAN Configurations Guide

<details>
<summary><h2>Debian Configuration</h2></summary>

You can use the following method to configure VLAN dynamically on Debian.

### Option 1: Run the Script (Recommended)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/vlan-configs/debian.sh)
```

This script will dynamically detect the interface with an IP in the `10.0.x.x` range and apply the configuration for you.

### Option 2: Manual Steps

<details>
<summary>1. Detect Interface</summary>

```bash
ip -o -4 addr show | awk '/10\.0\./ {print $2}'
```

Example Output:
```
eth1
```

Replace `eth1` with the interface name detected in the following steps.
</details>

<details>
<summary>2. Configure Cloud-Init</summary>

Open the Cloud-Init configuration file:
```bash
nano /etc/cloud/cloud.cfg.d/99_custom-config.cfg
```

Add the following content (replace `eth1` with your detected interface):
```yaml
#cloud-config
runcmd:
  - ip link set mtu 1400 dev eth1
  - ip route add 10.0.0.0/16 via 10.0.16.1 dev eth1
```
</details>

<details>
<summary>3. Apply Changes</summary>

```bash
cloud-init clean
cloud-init init
cloud-init modules --mode=config
cloud-init modules --mode=final
```
</details>

<details>
<summary>4. Restart Networking</summary>

```bash
systemctl restart networking
```
</details>

<details>
<summary>5. Verify Configuration</summary>

```bash
ip link show
ip route
ping -M want -s 65507 10.0.0.2
```
</details>

</details>

<details>
<summary><h2>Ubuntu Configuration</h2></summary>

You can use the following method to configure VLAN dynamically on Ubuntu.

### Option 1: Run the Script (Recommended)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/vlan-configs/ubuntu.sh)
```

This script will dynamically detect the interface with an IP in the `10.0.x.x` range and apply the configuration for you.

### Option 2: Manual Steps

<details>
<summary>1. Detect Interface</summary>

```bash
ip -o -4 addr show | awk '/10\.0\./ {print $2}'
```

Example Output:
```
eth1
```

Replace `eth1` with the interface name detected in the following steps.
</details>

<details>
<summary>2. Backup and Configure Netplan</summary>

Backup existing configuration:
```bash
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
```

Open the Netplan configuration file:
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Add or modify the configuration:
```yaml
network:
  version: 2
  ethernets:
    eth1:
      dhcp4: false
      addresses:
        - 10.0.20.254/24
      routes:
        - to: 10.0.0.0/16
          via: 10.0.16.1
      mtu: 1400
```

> Note: Replace `eth1` with your detected interface name and `10.0.20.254/24` with the appropriate IP address and subnet.
</details>

<details>
<summary>3. Apply Configuration</summary>

```bash
sudo netplan apply
```
</details>

<details>
<summary>4. Verify Configuration</summary>

```bash
ip link show
ip route
ping -M want -s 65507 10.0.0.2
```
</details>

</details>

<details>
<summary><h2>Rocky Linux 8 Configuration</h2></summary>

You can use the following method to configure VLAN dynamically on Rocky Linux 8.

### Option 1: Run the Script (Recommended)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/ariadata/proxmox-templates-helpers/main/vlan-configs/rocky-8.sh)
```

This script will dynamically detect the interface with an IP in the `10.0.x.x` range and apply the configuration for you.

### Option 2: Manual Steps

<details>
<summary>1. Detect Interface</summary>

```bash
ip -o -4 addr show | awk '/10\.0\./ {print $2}'
```

Example Output:
```
eth1
```

Replace `eth1` with the interface name detected in the following steps.
</details>

<details>
<summary>2. Configure Network Interface</summary>

Create/edit the network interface configuration:
```bash
sudo nano /etc/sysconfig/network-scripts/ifcfg-eth1
```

Add or modify the configuration (replace `eth1` with your interface):
```ini
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=eth1
DEVICE=eth1
ONBOOT=yes
IPADDR=10.0.20.254
PREFIX=24
MTU=1400
```
</details>

<details>
<summary>3. Configure Static Route</summary>

Create/edit the route configuration:
```bash
sudo nano /etc/sysconfig/network-scripts/route-eth1
```

Add the following content:
```
10.0.0.0/16 via 10.0.16.1 dev eth1
```
</details>

<details>
<summary>4. Restart Network Service</summary>

```bash
sudo systemctl restart NetworkManager
```
</details>

<details>
<summary>5. Verify Configuration</summary>

```bash
ip link show
ip route
ping -M want -s 65507 10.0.0.2
```
</details>

</details>

<details>
<summary><h2>Key Notes</h2></summary>

### Dynamic Detection
Both Debian and Ubuntu methods include a step to dynamically detect the interface with an IP in the `10.0.x.x` range using:
```bash
ip -o -4 addr show | awk '/10\.0\./ {print $2}'
```

### Persistent Configurations
- **Debian**: Changes are persisted in `/etc/cloud/cloud.cfg.d/99_custom-config.cfg`
- **Ubuntu**: Changes are persisted via Netplan in `/etc/netplan/50-cloud-init.yaml`
- **Rocky Linux 8**: Changes are persisted in `/etc/sysconfig/network-scripts/`

### Important Reminders
- Always create a backup of configuration files before modification
- Verify configurations after applying changes
- Use the recommended script option for automatic configuration when possible

</details>