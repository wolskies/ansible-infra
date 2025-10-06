# Bridge Network (br0) Setup for VM Testing

This document describes how to set up a bridged network interface (`br0`) on the host machine for VM testing infrastructure.

## Network Configuration

- **Bridge Interface**: `br0`
- **Network**: `192.168.100.0/24`
- **Gateway**: `192.168.100.1` (host machine)
- **VM IP Range**: `192.168.100.50-59`
- **DNS Servers**: `192.168.100.1, 8.8.8.8, 1.1.1.1`

## VM IP Assignments

| VM Name                  | IP Address       | Purpose           |
|--------------------------|------------------|-------------------|
| ubuntu2204-server        | 192.168.100.50   | Ubuntu 22.04 test |
| ubuntu2404-workstation   | 192.168.100.51   | Ubuntu 24.04 test |
| debian12-server          | 192.168.100.52   | Debian 12 test    |
| arch-workstation         | 192.168.100.53   | Arch Linux test   |
| (reserved)               | 192.168.100.54-59| Future expansion  |

## Host Bridge Setup

### Option 1: systemd-networkd (Recommended for Arch Linux)

1. **Create bridge interface:**

```bash
# /etc/systemd/network/10-br0.netdev
[NetDev]
Name=br0
Kind=bridge
```

2. **Configure bridge with static IP:**

```bash
# /etc/systemd/network/20-br0.network
[Match]
Name=br0

[Network]
Address=192.168.100.1/24
DHCPServer=yes
IPMasquerade=yes
IPForward=yes

[DHCPServer]
PoolOffset=100
PoolSize=50
EmitDNS=yes
DNS=8.8.8.8
DNS=1.1.1.1
```

3. **Bind physical interface to bridge (if needed):**

```bash
# /etc/systemd/network/30-br0-bind.network
# Only needed if you want to bridge physical network
[Match]
Name=enp*  # Match your physical interface

[Network]
Bridge=br0
```

4. **Enable and restart networking:**

```bash
sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd
```

### Option 2: NetworkManager (Ubuntu/Debian)

```bash
# Create bridge
nmcli connection add type bridge ifname br0 con-name br0

# Configure bridge IP
nmcli connection modify br0 ipv4.addresses 192.168.100.1/24
nmcli connection modify br0 ipv4.method manual

# Optional: Add physical interface to bridge
nmcli connection add type bridge-slave ifname enp3s0 master br0

# Bring up bridge
nmcli connection up br0
```

### Option 3: netplan (Ubuntu Server)

```yaml
# /etc/netplan/01-bridge.yaml
network:
  version: 2
  renderer: networkd

  ethernets:
    enp3s0:  # Your physical interface (optional)
      dhcp4: false
      dhcp6: false

  bridges:
    br0:
      addresses:
        - 192.168.100.1/24
      dhcp4: false
      dhcp6: false
      interfaces:
        - enp3s0  # Optional: bridge to physical network
      parameters:
        stp: false
        forward-delay: 0
```

Apply configuration:
```bash
sudo netplan apply
```

## Firewall Configuration

### Allow VM traffic and enable NAT (iptables)

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Allow bridge traffic
sudo iptables -I FORWARD -i br0 -j ACCEPT
sudo iptables -I FORWARD -o br0 -j ACCEPT

# Enable NAT for VM internet access
sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j MASQUERADE

# Save rules (Debian/Ubuntu)
sudo netfilter-persistent save

# Save rules (Arch Linux)
sudo iptables-save | sudo tee /etc/iptables/iptables.rules
```

### UFW Configuration (if using UFW)

```bash
# Allow forwarding from bridge
sudo ufw route allow in on br0
sudo ufw route allow out on br0

# Enable masquerading
sudo nano /etc/ufw/before.rules

# Add before *filter section:
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.100.0/24 -j MASQUERADE
COMMIT
```

## Verification

1. **Check bridge exists:**
```bash
ip addr show br0
```

Expected output:
```
br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 192.168.100.1/24 brd 192.168.100.255 scope global br0
```

2. **Test bridge connectivity:**
```bash
ping -c 3 192.168.100.1
```

3. **Verify libvirt can see the bridge:**
```bash
sudo virsh net-list --all
```

4. **Check IP forwarding:**
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1
```

## Deploy VMs

Once br0 is configured:

```bash
cd vm-test-infrastructure/final-release-testing/terraform
terraform init
terraform plan
terraform apply
```

VMs will automatically:
- Connect to br0 bridge
- Configure static IPs (192.168.100.50-53)
- Use br0 gateway (192.168.100.1)
- Have direct SSH access from host

## SSH Access

VMs are directly accessible via their static IPs:

```bash
ssh ed@192.168.100.50  # ubuntu2204-server
ssh ed@192.168.100.51  # ubuntu2404-workstation
ssh ed@192.168.100.52  # debian12-server
ssh ed@192.168.100.53  # arch-workstation
```

Or use the generated SSH config:
```bash
ssh -F ../ssh-config ubuntu2204-server
```

## Troubleshooting

### Bridge not forwarding traffic

```bash
# Enable bridge netfilter
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

# Allow bridge traffic
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=0
```

### VMs can't reach internet

```bash
# Verify NAT is configured
sudo iptables -t nat -L -n -v | grep MASQUERADE

# Check IP forwarding
sudo sysctl net.ipv4.ip_forward

# Verify routing
ip route show
```

### Can't SSH to VMs

```bash
# Check VMs are running
sudo virsh list --all

# Check VM console
sudo virsh console ubuntu2204-server

# Verify cloud-init completed
ssh ed@192.168.100.50 "cloud-init status"
```

## Cleanup

To remove bridge:

```bash
# NetworkManager
nmcli connection delete br0

# systemd-networkd
sudo rm /etc/systemd/network/*br0*
sudo systemctl restart systemd-networkd

# Destroy VMs first
cd vm-test-infrastructure/final-release-testing/terraform
terraform destroy
```
