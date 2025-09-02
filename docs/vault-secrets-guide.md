# Ansible Vault Secrets Management Guide

This guide explains how to securely manage sensitive data using Ansible Vault with the wolskinet.infrastructure collection.

## Overview

Ansible Vault provides encryption for sensitive data like passwords, API keys, and private configuration values. This collection is designed to work seamlessly with vault-encrypted files.

## Quick Start

### 1. Create a Vault Password File

```bash
# Create a secure password file (keep this safe and never commit it!)
echo "your-very-secure-vault-password" > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass
```

### 2. Configure Ansible to Use the Vault Password

Add to your `ansible.cfg`:

```ini
[defaults]
vault_password_file = ~/.ansible-vault-pass
```

Or use environment variable:
```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-pass
```

### 3. Create Encrypted Vault Files

```bash
# Create an encrypted secrets file
ansible-vault create group_vars/all/vault.yml
```

## Recommended File Structure

Organize your inventory with both plain and encrypted variables:

```
inventory/
├── inventory.yml
├── group_vars/
│   ├── all/
│   │   ├── vars.yml      # Plain variables
│   │   └── vault.yml     # Encrypted secrets
│   ├── docker_hosts/
│   │   ├── vars.yml
│   │   └── vault.yml
│   └── workstations/
│       ├── vars.yml
│       └── vault.yml
└── host_vars/
    ├── server01/
    │   ├── vars.yml
    │   └── vault.yml
    └── workstation01/
        ├── vars.yml
        └── vault.yml
```

## Example Vault Files

### Global Secrets (`group_vars/all/vault.yml`)

```yaml
---
# User passwords (generate with: python3 -c "import crypt; print(crypt.crypt('password', crypt.mksalt(crypt.METHOD_SHA512)))")
vault_user_passwords:
  admin: "$6$rounds=656000$YourSaltHere$HashHere"
  service: "$6$rounds=656000$AnotherSalt$AnotherHash"

# API Keys and Tokens
vault_api_keys:
  github_token: "ghp_xxxxxxxxxxxxxxxxxxxx"
  gitlab_token: "glpat-xxxxxxxxxxxxxxxxxxxx"

# Database credentials
vault_database:
  root_password: "super-secure-db-password"
  app_password: "app-specific-password"

# SSL/TLS certificates and keys
vault_ssl:
  private_key: |
    -----BEGIN PRIVATE KEY-----
    [Your private key content here]
    -----END PRIVATE KEY-----
  certificate: |
    -----BEGIN CERTIFICATE-----
    MIIDXTCCAkWgAwIBAgIJAKL0UG+J6CzIMA0GCSqGSIb3DQEBCwUA...
    -----END CERTIFICATE-----

# Email/SMTP credentials
vault_email:
  smtp_password: "your-smtp-app-password"
  notification_email: "admin@yourdomain.com"
```

### Docker Hosts Secrets (`group_vars/docker_hosts/vault.yml`)

```yaml
---
# Docker registry credentials
vault_docker_registry:
  username: "your-registry-user"
  password: "your-registry-password"
  email: "docker@yourdomain.com"

# Container environment secrets
vault_container_secrets:
  postgres_password: "secure-postgres-password"
  redis_password: "secure-redis-password"
  jwt_secret: "your-jwt-signing-key"

# Backup credentials
vault_backup:
  s3_access_key: "AKIAIOSFODNN7EXAMPLE"
  s3_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  encryption_key: "backup-encryption-key"
```

### Host-Specific Secrets (`host_vars/server01/vault.yml`)

```yaml
---
# Machine-specific credentials
vault_host_specific:
  service_account_key: "machine-specific-service-key"
  monitoring_token: "host-monitoring-token"

# Hardware-specific encryption keys
vault_hardware:
  disk_encryption_key: "luks-encryption-passphrase"
  tpm_seal_key: "tpm-sealing-key"
```

## Using Vault Variables in Playbooks

### Reference Vault Variables in Plain Variables

Create `group_vars/all/vars.yml`:

```yaml
---
# Reference vault variables for easier use
user_details:
  - name: 'admin'
    uid: 1000
    gid: 1000
    password: "{{ vault_user_passwords.admin }}"
  - name: 'service'
    uid: 1001
    gid: 1001
    password: "{{ vault_user_passwords.service }}"

# API configuration
github_api_token: "{{ vault_api_keys.github_token }}"
gitlab_api_token: "{{ vault_api_keys.gitlab_token }}"

# Database configuration
database_root_password: "{{ vault_database.root_password }}"
database_app_password: "{{ vault_database.app_password }}"

# Email configuration
smtp_password: "{{ vault_email.smtp_password }}"
notification_email: "{{ vault_email.notification_email }}"
```

### Using in Roles and Tasks

```yaml
---
- name: Configure database with encrypted password
  mysql_user:
    name: app
    password: "{{ database_app_password }}"
    priv: "app_db.*:ALL"

- name: Deploy container with secrets
  docker_container:
    name: myapp
    image: myapp:latest
    env:
      DATABASE_PASSWORD: "{{ vault_container_secrets.postgres_password }}"
      JWT_SECRET: "{{ vault_container_secrets.jwt_secret }}"
```

## Vault Management Commands

### Creating and Editing Vault Files

```bash
# Create a new encrypted file
ansible-vault create group_vars/all/vault.yml

# Edit an existing encrypted file
ansible-vault edit group_vars/all/vault.yml

# View an encrypted file (read-only)
ansible-vault view group_vars/all/vault.yml

# Encrypt an existing plain file
ansible-vault encrypt group_vars/all/plaintext-secrets.yml

# Decrypt a vault file (be careful!)
ansible-vault decrypt group_vars/all/vault.yml
```

### Password Management

```bash
# Change vault password
ansible-vault rekey group_vars/all/vault.yml

# Use a different password file for specific operations
ansible-vault edit --vault-password-file /path/to/different/password group_vars/all/vault.yml
```

### Running Playbooks with Vault

```bash
# Using password file
ansible-playbook -i inventory.yml playbook.yml

# Prompt for password
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass

# Use specific password file
ansible-playbook -i inventory.yml playbook.yml --vault-password-file /path/to/vault-pass
```

## Security Best Practices

### 1. Vault Password Security

```bash
# Store vault password securely
chmod 600 ~/.ansible-vault-pass

# Use environment variables in CI/CD
export ANSIBLE_VAULT_PASSWORD_FILE=/secrets/vault-password

# Or use vault password script for dynamic passwords
# ansible.cfg:
# vault_password_file = /path/to/vault-password-script.py
```

### 2. File Permissions

```bash
# Secure your inventory directory
chmod 700 inventory/
chmod 600 inventory/group_vars/*/vault.yml
chmod 600 inventory/host_vars/*/vault.yml
```

### 3. Git Integration

Add to `.gitignore`:

```gitignore
# Vault password files
.vault-pass
*vault-pass*
*vault_pass*

# Decrypted vault files (if you accidentally decrypt)
*-decrypted.yml

# Backup files created by editors
*~
*.bak
```

### 4. Separate Vault Files

Keep encrypted and plain variables in separate files:

```yaml
# group_vars/all/vars.yml (plain text)
---
app_name: "myapp"
app_port: 8080
app_env: "production"

# Reference vault variables
database_password: "{{ vault_database_password }}"
api_key: "{{ vault_api_key }}"
```

```yaml
# group_vars/all/vault.yml (encrypted)
---
vault_database_password: "secure-password"
vault_api_key: "secret-api-key"
```

## Multiple Vault Passwords

For different environments or teams:

```bash
# Development environment
ansible-vault create --vault-id dev@dev-vault-pass group_vars/dev/vault.yml

# Production environment
ansible-vault create --vault-id prod@prod-vault-pass group_vars/prod/vault.yml

# Run playbook with multiple vault IDs
ansible-playbook playbook.yml --vault-id dev@dev-pass --vault-id prod@prod-pass
```

## Troubleshooting

### Common Issues

1. **"Decryption failed" Error**:
   - Check vault password file exists and is readable
   - Verify the password is correct
   - Ensure the file was actually encrypted with vault

2. **Permission Denied**:
   - Check file permissions on vault files and password files
   - Ensure ansible can read the vault password file

3. **Variable Not Found**:
   - Verify vault variables are properly referenced in plain variable files
   - Check that vault files are in the correct group_vars/host_vars locations

### Debug Vault Issues

```bash
# Check if file is encrypted
file group_vars/all/vault.yml
# Should show: ASCII text (if encrypted properly)

# Test vault password
ansible-vault view group_vars/all/vault.yml

# Verify variable loading
ansible-inventory -i inventory.yml --list --vault-password-file ~/.ansible-vault-pass
```

## Integration with wolskinet.infrastructure Collection

The collection is designed to work seamlessly with vault-encrypted secrets:

```yaml
# In your encrypted vault file
vault_dotfiles_repo: "ssh://git@gitlab.private.com:2222/configs/dotfiles.git"
vault_gitlab_ssh_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [Your SSH private key content here]
  -----END OPENSSH PRIVATE KEY-----

# Reference in plain variables
dotfiles_repo: "{{ vault_dotfiles_repo }}"
gitlab_ssh_key: "{{ vault_gitlab_ssh_key }}"
```

This allows you to keep your private repository URLs and SSH keys secure while using the collection.

## Example: Complete Secure Setup

1. **Create vault password**:
   ```bash
   openssl rand -base64 32 > ~/.ansible-vault-pass
   chmod 600 ~/.ansible-vault-pass
   ```

2. **Create encrypted secrets**:
   ```bash
   ansible-vault create inventory/group_vars/all/vault.yml
   ```

3. **Configure ansible.cfg**:
   ```ini
   [defaults]
   vault_password_file = ~/.ansible-vault-pass
   host_key_checking = False
   ```

4. **Run playbooks securely**:
   ```bash
   ansible-playbook -i inventory/inventory.yml setup-new-machine.yml
   ```

Remember: The security of your infrastructure depends on keeping vault passwords and encrypted files secure. Never commit vault passwords to version control!
