#!/bin/bash
# Validate VM test configuration against proven CI patterns

echo "=== VM Test Configuration Validation ==="
echo ""

CONFIG_FILE="../test-scenarios/confidence-test.yml"
REFERENCE_CONFIG="../../molecule/configure_system/molecule.yml"

echo "Checking configuration structure against CI patterns..."

# Check if packages use correct structure
if grep -q "packages:" "$CONFIG_FILE" && grep -q "present:" "$CONFIG_FILE"; then
    echo "✅ Package structure: Using packages.present hierarchy"
else
    echo "❌ Package structure: Should use packages.present.{all|group|host}.{Distribution}"
fi

# Check for language configurations
if grep -q "dev_nodejs:" "$CONFIG_FILE"; then
    echo "✅ Language configs: Found dev_nodejs"
else
    echo "⚠️  Language configs: No dev_nodejs found"
fi

# Check user structure
if grep -q "users:" "$CONFIG_FILE" && grep -q "name:" "$CONFIG_FILE"; then
    echo "✅ User structure: Using name field (matches CI)"
else
    echo "❌ User structure: Should use 'name' field, not 'username'"
fi

# Check firewall structure
if grep -q "firewall:" "$CONFIG_FILE" || grep -q "host_security:" "$CONFIG_FILE"; then
    echo "✅ Security configs: Found firewall/security settings"
else
    echo "⚠️  Security configs: No firewall settings found"
fi

echo ""
echo "=== Comparison with CI Reference ==="
echo "Reference file: $REFERENCE_CONFIG"
echo ""
echo "Key CI patterns your config should follow:"
echo "1. packages.present.{all|group|host}.{Distribution}"
echo "2. users[].name (not username)"
echo "3. dev_nodejs.install: true"
echo "4. firewall.enabled: true/false"
echo ""
echo "Run this before ./run-test.sh to catch config issues early!"
