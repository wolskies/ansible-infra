[workstations:vars]
ansible_user=ansible
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3

[servers:vars]
ansible_user=ansible
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3

[workstations]
%{ for name, config in workstations ~}
${name} ansible_host=${config.ip} ansible_distribution=${config.distro}
%{ endfor ~}

[servers]
%{ for name, config in servers ~}
${name} ansible_host=${config.ip} ansible_distribution=${config.distro}
%{ endfor ~}

[linux:children]
workstations
servers
