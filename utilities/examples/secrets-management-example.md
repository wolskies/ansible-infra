# Secrets Management with Discovery Utility

The discovery utility **never captures sensitive data** but provides comprehensive templates for secure secrets management.

## 🛡️ Security Design

### What is NOT Captured (By Design)
❌ SSH private/public keys  
❌ User password hashes  
❌ API keys and tokens  
❌ Database credentials  
❌ TLS/SSL certificates  
❌ Application secrets  
❌ Environment variables with secrets  

### What IS Generated
✅ **Secrets template** with placeholders for all needed secrets  
✅ **Configuration structure** for proper vault organization  
✅ **Usage examples** for referencing vault variables  
✅ **Security guidance** for each type of secret  

## Generated Secrets Template

When you run discovery, you get a comprehensive secrets template:

```
discovered-infrastructure/
├── arch-workstation-secrets-template.yml  # Complete secrets template
├── DISCOVERY-REPORT.md                    # Includes security checklist
└── host_vars/arch-workstation.yml         # References vault variables
```

## Example: Generated Secrets Template

### For an Arch Linux Workstation with Docker

```yaml
# arch-workstation-secrets-template.yml
# ⚠️  POPULATE WITH REAL VALUES AND ENCRYPT WITH ANSIBLE-VAULT!

---
# USER MANAGEMENT SECRETS
vault_user_credentials:
  # Current user: admin (discovered)
  admin:
    # Generate with: python3 -c "import crypt; print(crypt.crypt('your-password', crypt.mksalt(crypt.METHOD_SHA512)))"
    password_hash: "$6$REPLACE_WITH_REAL_PASSWORD_HASH$"

# SSH KEY MANAGEMENT
vault_ssh_keys:
  admin_ssh:
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      REPLACE_WITH_YOUR_ACTUAL_SSH_PRIVATE_KEY_CONTENT
      -----END OPENSSH PRIVATE KEY-----
    public_key: "ssh-rsa REPLACE_WITH_YOUR_ACTUAL_SSH_PUBLIC_KEY admin@arch-workstation"

  # Dotfiles repository deploy key (detected ~/.dotfiles)
  dotfiles_deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    REPLACE_WITH_DOTFILES_REPOSITORY_DEPLOY_KEY
    -----END OPENSSH PRIVATE KEY-----

# REPOSITORY ACCESS
vault_repositories:
  dotfiles:
    url: "REPLACE_WITH_YOUR_DOTFILES_REPOSITORY_URL"
    ssh_key: "{{ vault_ssh_keys.dotfiles_deploy_key }}"

# DOCKER REGISTRY SECRETS (Docker detected with 5 containers)
vault_docker:
  docker_hub:
    username: "REPLACE_WITH_DOCKER_HUB_USERNAME"
    password: "REPLACE_WITH_DOCKER_HUB_PASSWORD"
    email: "REPLACE_WITH_DOCKER_HUB_EMAIL"
  
  container_secrets:
    # Database container secrets for postgres:13
    database:
      root_password: "REPLACE_WITH_DATABASE_ROOT_PASSWORD"
      user_password: "REPLACE_WITH_DATABASE_USER_PASSWORD"
    
    # Grafana secrets for grafana:latest
    grafana:
      admin_password: "REPLACE_WITH_GRAFANA_ADMIN_PASSWORD"

# API KEYS AND TOKENS
vault_api_keys:
  github:
    token: "ghp_REPLACE_WITH_YOUR_GITHUB_PERSONAL_ACCESS_TOKEN"
```

## Step-by-Step Setup

### 1. Copy and Populate Template

```bash
# Copy template to proper location
cp discovered-infrastructure/arch-workstation-secrets-template.yml \
   discovered-infrastructure/group_vars/all/vault.yml

# Edit with real values
vim discovered-infrastructure/group_vars/all/vault.yml
```

### 2. Generate Required Secrets

```bash
# Generate password hash
python3 -c "import crypt; print(crypt.crypt('your-password', crypt.mksalt(crypt.METHOD_SHA512)))"

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "admin@arch-workstation" -f ~/.ssh/arch-workstation

# Generate application secret
openssl rand -base64 32
```

### 3. Populate Real Values

```yaml
# Replace placeholders with real values
vault_user_credentials:
  admin:
    password_hash: "$6$rounds=656000$YourRealSalt$YourRealHashHere"

vault_ssh_keys:
  admin_ssh:
    private_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAA...
      -----END OPENSSH PRIVATE KEY-----
    public_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... admin@arch-workstation"

vault_repositories:
  dotfiles:
    url: "git@github.com:yourusername/dotfiles.git"

vault_docker:
  docker_hub:
    username: "yourdockerhubuser"
    password: "your-docker-hub-password"
```

### 4. Encrypt with Ansible Vault

```bash
# Create vault password
echo "your-secure-vault-password" > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass

# Encrypt secrets file
ansible-vault encrypt discovered-infrastructure/group_vars/all/vault.yml

# Configure ansible.cfg
cat >> ansible.cfg << EOF
[defaults]
vault_password_file = ~/.ansible-vault-pass
EOF
```

## Using Vault Variables

### In Generated Host Variables

The discovery utility creates proper references:

```yaml
# host_vars/arch-workstation.yml
ansible_user: "admin"

# User configuration (references vault)
user_details:
  - name: "admin"
    uid: 1000
    gid: 1000
    password: "{{ vault_user_credentials.admin.password_hash }}"

# Repository configuration (references vault)
dotfiles_repository_url: "{{ vault_repositories.dotfiles.url }}"

# Docker configuration (references vault)
docker_registries:
  - registry: "registry.hub.docker.com"
    username: "{{ vault_docker.docker_hub.username }}"
    password: "{{ vault_docker.docker_hub.password }}"
```

### In Generated Playbooks

The replication playbook automatically uses vault variables:

```yaml
# replicate-arch-workstation.yml
- name: Configure SSH keys
  ansible.posix.authorized_key:
    user: "{{ ansible_user }}"
    key: "{{ vault_ssh_keys.admin_ssh.public_key }}"

- name: Configure Docker registry login
  community.docker.docker_login:
    registry_url: "{{ item.registry }}"
    username: "{{ item.username }}"
    password: "{{ item.password }}"
  loop: "{{ docker_registries }}"
  no_log: true
```

## Security Best Practices

### 1. Vault Password Security

```bash
# Generate strong vault password
openssl rand -base64 32 > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass

# Or use password manager integration
cat ~/.config/pass/ansible-vault | ansible-vault encrypt group_vars/all/vault.yml
```

### 2. Key Management

```bash
# Generate dedicated SSH keys per environment
ssh-keygen -t ed25519 -C "infrastructure-key" -f ~/.ssh/infrastructure-ed25519

# Use different keys for different purposes
ssh-keygen -t rsa -b 4096 -C "dotfiles-deploy-key" -f ~/.ssh/dotfiles-deploy
```

### 3. Secrets Rotation

```yaml
# Version your secrets for rotation
vault_api_keys:
  github:
    current: "ghp_current_token_here"
    previous: "ghp_previous_token_for_rollback"
    rotation_date: "2024-01-15"
```

### 4. Environment Separation

```bash
# Different vault files per environment
discovered-infrastructure/
├── group_vars/
│   ├── all/
│   │   └── vault.yml           # Production secrets
│   ├── development/
│   │   └── vault.yml           # Development secrets
│   └── staging/
│       └── vault.yml           # Staging secrets
```

## Advanced Secrets Management

### 1. External Secret Managers

```yaml
# Integration with external systems
vault_external:
  hashicorp_vault:
    url: "https://vault.company.com"
    token: "{{ lookup('env', 'VAULT_TOKEN') }}"
  
  aws_secrets_manager:
    region: "us-west-2"
    secret_name: "infrastructure-secrets"
```

### 2. Dynamic Secrets

```yaml
# Secrets that change frequently
vault_dynamic:
  database_passwords:
    rotation_interval: "30d"
    last_rotation: "{{ ansible_date_time.epoch }}"
  
  api_tokens:
    github: "{{ lookup('hashivault', 'secret/github', 'token') }}"
```

### 3. Conditional Secrets

```yaml
# Different secrets per environment
vault_environment_secrets:
  development:
    database_url: "postgres://dev-user:dev-pass@dev-db:5432/myapp"
  production:
    database_url: "postgres://prod-user:{{ vault_db_password }}@prod-db:5432/myapp"
```

## Validation and Testing

### 1. Secrets Validation

```bash
# Test vault decryption
ansible-vault view group_vars/all/vault.yml

# Test variable resolution
ansible-playbook -i inventory.yml --check \
  replicate-arch-workstation.yml

# Validate secrets are not logged
ansible-playbook -i inventory.yml \
  replicate-arch-workstation.yml -v | grep -i password
```

### 2. Security Audit

```bash
# Check for unencrypted secrets
find . -name "*.yml" -exec grep -l "password\|key\|secret" {} \;

# Verify vault files are encrypted
file group_vars/all/vault.yml  # Should show "data"

# Test SSH key authentication
ssh -i ~/.ssh/infrastructure-ed25519 admin@192.168.1.100
```

## Common Secret Types by Discovered Components

### For Docker Hosts
- Container registry credentials
- Database passwords
- Application API keys
- SSL certificates
- Backup encryption keys

### For Development Workstations
- Git repository SSH keys
- IDE license keys
- Cloud service credentials
- VPN certificates

### For Servers
- SSL/TLS certificates
- Service account credentials
- Monitoring tokens
- Backup passwords
- Email/SMTP credentials

## Troubleshooting

### Common Issues

1. **Vault decryption fails**:
   ```bash
   # Check vault password file
   cat ~/.ansible-vault-pass
   
   # Test decryption manually
   ansible-vault decrypt --output=- group_vars/all/vault.yml
   ```

2. **SSH key authentication fails**:
   ```bash
   # Test key manually
   ssh -i ~/.ssh/infrastructure-ed25519 -o PasswordAuthentication=no admin@192.168.1.100
   
   # Check key permissions
   chmod 600 ~/.ssh/infrastructure-ed25519
   ```

3. **Variables not resolving**:
   ```bash
   # Debug variable resolution
   ansible-inventory -i inventory.yml --host arch-workstation
   
   # Check for syntax errors
   ansible-playbook --syntax-check replicate-arch-workstation.yml
   ```

## Security Checklist

After setup, verify:

- [ ] Vault password file is secured (chmod 600)
- [ ] All secrets files are encrypted
- [ ] SSH keys have proper permissions
- [ ] No secrets appear in logs
- [ ] Backup passwords are documented securely
- [ ] Secret rotation schedule is planned
- [ ] Environment separation is implemented
- [ ] External secret manager integration (if applicable)

Remember: **The discovery utility provides the structure, you provide the secrets!** 🔐