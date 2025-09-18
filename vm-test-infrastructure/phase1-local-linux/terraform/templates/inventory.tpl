[all:vars]
ansible_user=${ansible_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3

[debian]
debian12-test ansible_host=${debian12_ip}

[ubuntu]
ubuntu2204-test ansible_host=${ubuntu2204_ip}

[linux:children]
debian
ubuntu

[debian:vars]
ansible_distribution=Debian
ansible_distribution_major_version=12

[ubuntu:vars]
ansible_distribution=Ubuntu
ansible_distribution_major_version=22
