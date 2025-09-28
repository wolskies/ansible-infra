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
locals {
  vms = {
    ubuntu2204-server = {
      image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
      os_family = "Ubuntu"
      memory    = 4096
      vcpu      = 2
      test_type = "server"
    }
    ubuntu2404-workstation = {
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      os_family = "Ubuntu"
      memory    = 4096
      vcpu      = 2
      test_type = "workstation"
    }
    debian12-server = {
      image_url = "https://cloud-images.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
      os_family = "Debian"
      memory    = 4096
      vcpu      = 2
      test_type = "server"
    }
    arch-workstation = {
      image_url = "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
      os_family = "Archlinux"
      memory    = 4096
      vcpu      = 2
      test_type = "workstation"
    }
  }
}

# Download and cache VM images
resource "libvirt_volume" "base_images" {
  for_each = local.vms
  name     = "${each.key}-base.qcow2"
  source   = each.value.image_url
  pool     = "default"
  format   = "qcow2"
}

# Create VM disk volumes
resource "libvirt_volume" "vm_disks" {
  for_each       = local.vms
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.base_images[each.key].id
  pool           = "default"
  size           = 21474836480 # 20GB
}

# Cloud-init configuration
resource "libvirt_cloudinit_disk" "vm_cloudinit" {
  for_each  = local.vms
  name      = "${each.key}-cloudinit.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud-init/user-data.yml", {
    hostname = each.key
  })
  network_config = file("${path.module}/cloud-init/network-config.yml")
}

# Create VMs
resource "libvirt_domain" "test_vms" {
  for_each = local.vms
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  # Boot configuration
  cloudinit = libvirt_cloudinit_disk.vm_cloudinit[each.key].id

  # Network configuration
  network_interface {
    bridge         = "br0"
    wait_for_lease = true
    addresses      = []
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

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = {
      for name, vm in libvirt_domain.test_vms : name => {
        ip_address = vm.network_interface[0].addresses[0]
        os_family  = local.vms[name].os_family
        test_type  = local.vms[name].test_type
      }
    }
  })
  filename        = "${path.module}/../inventory/hosts.ini"
  file_permission = "0644"
}

# SSH configuration helper
resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/templates/ssh-config.tpl", {
    vms = {
      for name, vm in libvirt_domain.test_vms : name => {
        ip_address = vm.network_interface[0].addresses[0]
      }
    }
  })
  filename        = "${path.module}/../ssh-config"
  file_permission = "0644"
}
