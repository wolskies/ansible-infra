#!/bin/bash
# Create isolated internal network for VM testing
# VMs can talk to each other and host, but no external internet

cat > /tmp/isolated-test-network.xml <<'EOF'
<network>
  <name>ansible-test</name>
  <bridge name='virbr-test' stp='on' delay='0'/>
  <domain name='test.local'/>
  <ip address='10.10.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.10.10' end='10.10.10.250'/>
    </dhcp>
  </ip>
</network>
EOF

# Define and start network
virsh net-define /tmp/isolated-test-network.xml
virsh net-start ansible-test
virsh net-autostart ansible-test

echo "✅ Isolated network 'ansible-test' created"
echo "   - Network: 10.10.10.0/24"
echo "   - Host IP: 10.10.10.1"
echo "   - VM Range: 10.10.10.10-250"
echo ""
echo "To use in Terraform, set: network_name = \"ansible-test\""
