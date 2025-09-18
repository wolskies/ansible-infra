terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "vm_pool" {
  name = "ansible_test_pool"
  type = "dir"
  path = "/var/lib/libvirt/images/ansible-test"
}

resource "libvirt_volume" "debian12_base" {
  name   = "debian12-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu2204_base" {
  name   = "ubuntu2204-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "debian12_vm" {
  name           = "debian12-test.qcow2"
  pool           = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.debian12_base.id
  size           = 10737418240 # 10GB
}

resource "libvirt_volume" "ubuntu2204_vm" {
  name           = "ubuntu2204-test.qcow2"
  pool           = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.ubuntu2204_base.id
  size           = 10737418240 # 10GB
}

resource "libvirt_cloudinit_disk" "debian12_init" {
  name      = "debian12-init.iso"
  pool      = libvirt_pool.vm_pool.name
  user_data = templatefile("${path.module}/cloud-init/user-data-debian12.yml", {
    ssh_public_key = file(pathexpand(var.ssh_public_key))
    hostname       = "debian12-test"
    ansible_user   = var.ansible_user
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yml", {
    vm_ip      = var.debian12_ip
    gateway_ip = var.gateway_ip
  })
}

resource "libvirt_cloudinit_disk" "ubuntu2204_init" {
  name      = "ubuntu2204-init.iso"
  pool      = libvirt_pool.vm_pool.name
  user_data = templatefile("${path.module}/cloud-init/user-data-ubuntu2204.yml", {
    ssh_public_key = file(pathexpand(var.ssh_public_key))
    hostname       = "ubuntu2204-test"
    ansible_user   = var.ansible_user
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yml", {
    vm_ip      = var.ubuntu2204_ip
    gateway_ip = var.gateway_ip
  })
}

resource "libvirt_domain" "debian12_vm" {
  name   = "debian12-test"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  cloudinit = libvirt_cloudinit_disk.debian12_init.id

  network_interface {
    bridge         = var.network_name
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.debian12_vm.id
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

  cpu {
    mode = "host-passthrough"
  }
}

resource "libvirt_domain" "ubuntu2204_vm" {
  name   = "ubuntu2204-test"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  cloudinit = libvirt_cloudinit_disk.ubuntu2204_init.id

  network_interface {
    bridge         = var.network_name
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.ubuntu2204_vm.id
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

  cpu {
    mode = "host-passthrough"
  }
}
