terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Local libvirt provider for all VMs
provider "libvirt" {
  uri = "qemu:///system"
}

# Variables
variable "workstations" {
  description = "Workstation VMs configuration"
  default = {
    arch-workstation = {
      image_url = "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
      ip        = "192.168.100.61"
      distro    = "Archlinux"
    }
    debian13-workstation = {
      image_url = "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2"
      ip        = "192.168.100.62"
      distro    = "Debian"
    }
    ubuntu24-workstation = {
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      ip        = "192.168.100.63"
      distro    = "Ubuntu"
    }
  }
}

variable "servers" {
  description = "Server VMs configuration"
  default = {
    debian12-server = {
      image_url = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
      ip        = "192.168.100.64"
      distro    = "Debian"
    }
    ubuntu22-server = {
      image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
      ip        = "192.168.100.65"
      distro    = "Ubuntu"
    }
  }
}

variable "vm_specs" {
  description = "VM specifications"
  default = {
    cpus   = 4
    memory = 8192  # MB
    disk   = 40    # GB
  }
}

# Storage pool for all VMs
resource "libvirt_pool" "vm_pool" {
  name = "phase3_vm_pool"
  type = "dir"
  path = "/var/lib/libvirt/images/phase3-vms"
}


# Workstation VMs (local)
resource "libvirt_volume" "workstation_base" {
  for_each = var.workstations

  name   = "${each.key}-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = each.value.image_url
  format = "qcow2"
}

resource "libvirt_volume" "workstation_vm" {
  for_each = var.workstations

  name           = "${each.key}.qcow2"
  pool           = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.workstation_base[each.key].id
  size           = var.vm_specs.disk * 1073741824  # Convert GB to bytes
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "workstation_init" {
  for_each = var.workstations

  name = "${each.key}-init.iso"
  pool = libvirt_pool.vm_pool.name

  user_data = templatefile("${path.module}/cloud-init/user-data.yml", {
    hostname = each.key
    ssh_key  = file("~/.ssh/id_rsa.pub")
  })

  network_config = templatefile("${path.module}/cloud-init/network-config-static.yml", {
    ip_address = each.value.ip
    gateway    = "192.168.100.1"
  })
}

resource "libvirt_domain" "workstation_vm" {
  for_each = var.workstations

  name   = each.key
  memory = var.vm_specs.memory
  vcpu   = var.vm_specs.cpus

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.workstation_vm[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.workstation_init[each.key].id

  network_interface {
    bridge = "br0"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Server VMs (now local too)
resource "libvirt_volume" "server_base" {
  for_each = var.servers

  name   = "${each.key}-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = each.value.image_url
  format = "qcow2"
}

resource "libvirt_volume" "server_vm" {
  for_each = var.servers

  name           = "${each.key}.qcow2"
  pool           = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.server_base[each.key].id
  size           = var.vm_specs.disk * 1073741824
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "server_init" {
  for_each = var.servers

  name = "${each.key}-init.iso"
  pool = libvirt_pool.vm_pool.name

  user_data = templatefile("${path.module}/cloud-init/user-data.yml", {
    hostname = each.key
    ssh_key  = file("~/.ssh/id_rsa.pub")
  })

  network_config = templatefile("${path.module}/cloud-init/network-config-static.yml", {
    ip_address = each.value.ip
    gateway    = "192.168.100.1"
  })
}

resource "libvirt_domain" "server_vm" {
  for_each = var.servers

  name   = each.key
  memory = var.vm_specs.memory
  vcpu   = var.vm_specs.cpus

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.server_vm[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.server_init[each.key].id

  network_interface {
    bridge = "br0"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Generate basic Ansible inventory (IPs will be discovered)
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    workstations = var.workstations
    servers      = var.servers
  })

  filename = "${path.module}/inventory.ini"

  depends_on = [
    libvirt_domain.workstation_vm,
    libvirt_domain.server_vm
  ]
}

# Outputs
output "vm_ips" {
  value = {
    workstations = { for k, v in var.workstations : k => v.ip }
    servers      = { for k, v in var.servers : k => v.ip }
  }
}
