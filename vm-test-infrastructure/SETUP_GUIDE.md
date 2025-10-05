# VM Testing Infrastructure Setup Guide

## Current Status Assessment

### ✅ What's Already Configured
- **QEMU/KVM**: Installed (`/usr/bin/qemu-system-x86_64`)
- **virsh**: Installed (`/usr/bin/virsh`)
- **libvirtd**: Installed but currently inactive
- **SSH Key**: Present (`~/.ssh/id_ed25519.pub`)
- **Infrastructure Code**: Well-organized in `vm-test-infrastructure/final-release-testing/`

### ❌ What Needs Configuration
- **Terraform/OpenTofu**: Not installed
- **libvirt Storage Pool**: Not configured
- **Network Bridge (br0)**: Not created
- **User Permissions**: Not in libvirt/kvm groups
- **libvirtd Service**: Not running
- **Cloud-init SSH Key**: Mismatch with actual key

---

## Installation & Setup Steps

### 1. Install OpenTofu (Terraform Alternative)

```bash
# Install OpenTofu (open-source Terraform fork)
# Arch Linux method:
yay -S opentofu-bin
# or from AUR
paru -S opentofu-bin

# Alternative: Install Terraform directly
# sudo pacman -S terraform
```

**Why OpenTofu?** Open-source, compatible with Terraform configurations, better for this use case.

### 2. Configure libvirt Permissions

```bash
# Add user to required groups
sudo usermod -a -G libvirt,kvm ed

# Apply group changes (logout/login or use newgrp)
newgrp libvirt

# Verify group membership
groups | grep -E "(libvirt|kvm)"
```

### 3. Start and Enable libvirtd

```bash
# Start libvirtd service
sudo systemctl start libvirtd.service

# Enable on boot
sudo systemctl enable libvirtd.service

# Verify status
sudo systemctl status libvirtd.service

# Start virtlogd (if needed)
sudo systemctl start virtlogd.socket
```

### 4. Create Default Storage Pool

```bash
# Define and start default storage pool
sudo virsh pool-define-as default dir - - - - /var/lib/libvirt/images
sudo virsh pool-build default
sudo virsh pool-start default
sudo virsh pool-autostart default

# Verify
virsh pool-list --all
```

### 5. Network Configuration - Bridge Setup

The Terraform config expects `bridge: "br0"`. You have two options:

#### Option A: Create Physical Bridge (Recommended for bare metal)

**Use if you want VMs on your physical network with direct IP addresses.**

```bash
# Identify your main network interface
ip addr show

# Example: Assuming interface is enp4s0
# Create bridge with nmcli (NetworkManager)
sudo nmcli connection add type bridge ifname br0 con-name br0
sudo nmcli connection add type bridge-slave ifname enp4s0 master br0
sudo nmcli connection modify br0 ipv4.method auto
sudo nmcli connection up br0

# Verify bridge
ip addr show br0
brctl show br0  # or: bridge link show
```

**⚠️ Warning**: This will briefly disconnect your network during setup.

#### Option B: Use NAT Network (Simpler, Isolated)

**Use for testing without affecting physical network.**

**1. Update Terraform to use libvirt default network:**

```bash
cd vm-test-infrastructure/final-release-testing/terraform
```

Edit `main.tf` line 91-95:

```hcl
# Change from:
network_interface {
  bridge         = "br0"
  wait_for_lease = true
  addresses      = []
}

# To:
network_interface {
  network_name   = "default"
  wait_for_lease = true
}
```

**2. Create default NAT network:**

```bash
# Create default network XML
cat > /tmp/default-network.xml <<'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

# Define and start network
virsh net-define /tmp/default-network.xml
virsh net-start default
virsh net-autostart default

# Verify
virsh net-list --all
```

### 6. Update Cloud-Init SSH Key

Your actual SSH key differs from the one in cloud-init config.

```bash
# Update cloud-init with your actual key
cd vm-test-infrastructure/final-release-testing/terraform/cloud-init

# Replace SSH key in user-data.yml
sed -i 's|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGVTKRzOQtyBFYST4LI7KKmVLmnQDtQz4w3cQGy8IwH ed@testing-vm|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH1BwJeplbo35HPEpc3r4n0opHKKUKXLiwDJ6H3G02j ed@xeon|' user-data.yml
```

---

## Recommended Network Approach

### For Your Setup: Use Option B (NAT Network)

**Rationale:**
1. **Safer**: Won't affect your physical network
2. **Simpler**: No bridge configuration on host
3. **Isolated**: VMs get IPs in 192.168.122.0/24 range
4. **Portable**: Works on any machine with libvirt
5. **Sufficient**: Ansible can reach VMs via NAT

**Trade-offs:**
- VMs not directly accessible from other machines on LAN (only from host)
- For this testing use case, that's perfectly fine

---

## Verification Steps

After completing setup:

```bash
# 1. Check OpenTofu installation
tofu version

# 2. Verify libvirt is running
sudo systemctl status libvirtd

# 3. Check storage pool
virsh pool-list

# 4. Check network
virsh net-list

# 5. Verify permissions (should show libvirt and kvm)
groups

# 6. Test Terraform provider
cd vm-test-infrastructure/final-release-testing/terraform
tofu init
```

---

## Testing the Setup

Once configured, run a test:

```bash
cd vm-test-infrastructure/final-release-testing

# Initialize Terraform
cd terraform
tofu init

# Plan (dry run)
tofu plan

# Apply (create VMs)
tofu apply -auto-approve

# Verify VMs are running
virsh list

# Check generated inventory
cat ../inventory/hosts.ini

# Test SSH connectivity
ssh -F ../ssh-config ed@<vm-ip>

# Cleanup
tofu destroy -auto-approve
```

---

## Architecture Review

### 1. Folder Structure ✅ GOOD

```
vm-test-infrastructure/
├── final-release-testing/        # Current implementation
│   ├── terraform/                # VM provisioning
│   ├── test-scenarios/           # Configuration files
│   ├── validation/               # Validation playbooks
│   └── *.sh                      # Automation scripts
├── MASTER_REFERENCE_CONFIG.yml   # Variable reference
└── LESSONS_LEARNED.md            # Documentation
```

**Assessment:** Well-organized, follows Infrastructure as Code best practices.

### 2. Terraform Configuration ✅ MOSTLY GOOD

**Strengths:**
- Uses libvirt provider correctly
- Cloud-init setup is proper
- Dynamic inventory generation
- Proper VM matrix with locals

**Issues to Address:**
- Hardcoded bridge `br0` - needs NAT network option
- No Terraform backend configuration (state in local files)
- Missing `.terraform.lock.hcl` in `.gitignore`

### 3. Network Design ⚠️ NEEDS DECISION

**Current approach:** Bridge mode to `br0`
- **Pro**: VMs on physical network
- **Con**: Requires bridge setup, less portable

**Recommended:** NAT network via `virbr0`
- **Pro**: Simple, isolated, portable
- **Con**: VMs not accessible from LAN (only host)

---

## Next Steps (In Order)

1. ✅ **Install OpenTofu**: `yay -S opentofu-bin`
2. ✅ **Configure Permissions**: Add user to libvirt/kvm groups
3. ✅ **Start libvirtd**: `sudo systemctl enable --now libvirtd`
4. ✅ **Create Storage Pool**: Default pool at `/var/lib/libvirt/images`
5. ✅ **Choose Network Option**: NAT (Option B) recommended
6. ✅ **Update main.tf**: Change from bridge to network_name
7. ✅ **Update cloud-init**: Fix SSH key
8. ✅ **Test**: Run `tofu init && tofu plan`
9. ✅ **Execute**: `./run-comprehensive-test.sh`

---

## Common Issues & Solutions

### Issue: Permission Denied

```bash
# Solution: Restart libvirt socket
sudo systemctl restart libvirtd.socket libvirtd.service
```

### Issue: VMs Don't Get IP

```bash
# Solution: Check DHCP in network
virsh net-dumpxml default | grep dhcp
```

### Issue: Can't SSH to VMs

```bash
# Solution: Check cloud-init log
virsh console <vm-name>
# Login and check: sudo cat /var/log/cloud-init.log
```

---

## Conclusion

Your VM testing infrastructure is **well-designed** with proper separation of concerns. The main gaps are:

1. **OpenTofu/Terraform** - Need to install
2. **Networking** - Need to choose and configure (NAT recommended)
3. **libvirt Setup** - Need to start services and create pools
4. **SSH Key Update** - Need to sync cloud-init with actual key

Once these are addressed, your infrastructure is production-ready for comprehensive collection testing.
