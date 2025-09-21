[all:vars]
# Tart Sonoma images use 'admin' user with 'admin' password by default
ansible_user=admin
ansible_ssh_pass=admin
ansible_become_pass=admin
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p ${mac_user}@${mac_host}"'
ansible_python_interpreter=/usr/bin/python3

[macos]
${vm_name} ansible_host=${vm_ip}

[macos:vars]
ansible_distribution=MacOSX
ansible_distribution_major_version=14
