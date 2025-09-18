variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_memory" {
  description = "Memory allocation for each VM in MB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "Number of vCPUs for each VM"
  type        = number
  default     = 2
}

variable "network_name" {
  description = "Libvirt network to use (default or custom bridge)"
  type        = string
  default     = "br0"
}

variable "ansible_user" {
  description = "Ansible user for SSH access"
  type        = string
  default     = "ansible"
}

variable "bridge_network" {
  description = "Use bridged networking (br0) instead of NAT"
  type        = bool
  default     = true
}

variable "debian12_ip" {
  description = "Static IP for Debian 12 VM"
  type        = string
  default     = "192.168.100.51"
}

variable "ubuntu2204_ip" {
  description = "Static IP for Ubuntu 22.04 VM"
  type        = string
  default     = "192.168.100.52"
}

variable "gateway_ip" {
  description = "Gateway IP for static networking"
  type        = string
  default     = "192.168.100.1"
}
