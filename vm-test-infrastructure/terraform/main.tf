# Final Release Testing VM Infrastructure
# Provisions 4 VMs for comprehensive collection validation

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# VM Configuration Matrix
# Static IPs: 192.168.100.50-59 on br0 bridge
locals {
  vms = {
    ubuntu2204-server = {
      image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
      os_family = "Ubuntu"
      memory    = 4096
      vcpu      = 2
      test_type = "server"
      ip        = "192.168.100.50"
    }
    ubuntu2404-workstation = {
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      os_family = "Ubuntu"
      memory    = 4096
      vcpu      = 2
      test_type = "workstation"
      ip        = "192.168.100.51"
    }
    debian12-server = {
      image_url = "https://cdimage.debian.org/cdimage/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
      os_family = "Debian"
      memory    = 4096
      vcpu      = 2
      test_type = "server"
      ip        = "192.168.100.52"
    }
  }

  arch_vms = {
    arch-workstation = {
      image_url = "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
      os_family = "Archlinux"
      memory    = 4096
      vcpu      = 2
      test_type = "workstation"
      ip        = "192.168.100.53"
    }
  }

  all_vms = merge(local.vms, local.arch_vms)

  # Network configuration for br0 bridge
  bridge_name    = "br0"
  network_cidr   = "192.168.100.0/24"
  gateway_ip     = "192.168.100.1"
  dns_servers    = ["192.168.100.1", "8.8.8.8", "1.1.1.1"]
}

# Download and cache VM images
resource "libvirt_volume" "base_images" {
  for_each = local.all_vms
  name     = "${each.key}-base.qcow2"
  source   = each.value.image_url
  pool     = "default"
  format   = "qcow2"
}

# Create VM disk volumes
resource "libvirt_volume" "vm_disks" {
  for_each       = local.all_vms
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.base_images[each.key].id
  pool           = "default"
  size           = 32212254720 # 30GB
}

# Cloud-init configuration
resource "libvirt_cloudinit_disk" "vm_cloudinit" {
  for_each  = local.vms
  name      = "${each.key}-cloudinit.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud-init/user-data.yml", {
    hostname = each.key
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yml", {
    ip_address = each.value.ip
  })
}

# Create VMs
resource "libvirt_domain" "test_vms" {
  for_each = local.vms
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  # Boot configuration with cloud-init
  cloudinit = libvirt_cloudinit_disk.vm_cloudinit[each.key].id

  # Network configuration - bridged to br0 with static IP
  network_interface {
    bridge = local.bridge_name
    # Static IP configured via cloud-init, not libvirt
    wait_for_lease = false
  }

  # Disk configuration
  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }

  # Console configuration
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  # Graphics configuration
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  # VM metadata
  xml {
    xslt = file("${path.module}/domain.xsl")
  }
}

# Cloud-init configuration for Arch VMs
resource "libvirt_cloudinit_disk" "arch_cloudinit" {
  for_each  = local.arch_vms
  name      = "${each.key}-cloudinit.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud-init/arch-user-data.yml", {
    hostname = each.key
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yml", {
    ip_address = each.value.ip
  })
  depends_on = [libvirt_domain.test_vms]
}

# Create Arch VMs after Debian/Ubuntu VMs are up
resource "libvirt_domain" "arch_vms" {
  for_each = local.arch_vms
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.arch_cloudinit[each.key].id

  network_interface {
    bridge = local.bridge_name
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  xml {
    xslt = file("${path.module}/domain.xsl")
  }

  depends_on = [libvirt_domain.test_vms]
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = {
      for name, vm_config in local.all_vms : name => {
        ip_address = vm_config.ip
        os_family  = vm_config.os_family
        test_type  = vm_config.test_type
      }
    }
  })
  filename        = "${path.module}/../inventory/hosts.ini"
  file_permission = "0644"
  depends_on      = [libvirt_domain.test_vms, libvirt_domain.arch_vms]
}

# SSH configuration helper
resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/templates/ssh-config.tpl", {
    vms = {
      for name, vm_config in local.all_vms : name => {
        ip_address = vm_config.ip
      }
    }
  })
  filename        = "${path.module}/../ssh-config"
  file_permission = "0644"
  depends_on      = [libvirt_domain.test_vms, libvirt_domain.arch_vms]
}
