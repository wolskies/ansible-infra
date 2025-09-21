terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Variables for remote Mac connection
variable "mac_host" {
  description = "Remote Mac IP address"
  default     = "207.254.38.250"
}

variable "mac_user" {
  description = "Remote Mac username"
  default     = "ed"
}

variable "vm_name" {
  description = "Name for the Tart VM"
  default     = "sonoma-ansible-test"
}

variable "vm_cpu" {
  description = "Number of CPUs for VM"
  default     = 4
}

variable "vm_memory" {
  description = "Memory for VM in GB"
  default     = 8192  # Tart expects memory in MB
}

variable "vm_disk" {
  description = "Disk size for VM in GB"
  default     = 50
}

# Create and start Tart VM on remote Mac
resource "null_resource" "tart_vm" {
  # Create VM from base image
  provisioner "remote-exec" {
    inline = [
      # Set PATH for Homebrew
      "export PATH=/opt/homebrew/bin:$PATH",

      # Debug: Show what we have
      "echo 'Available Tart VMs:'",
      "/opt/homebrew/bin/tart list",

      # Delete existing VM if present
      "if /opt/homebrew/bin/tart list | grep -q ${var.vm_name}; then",
      "  echo 'Cleaning up existing VM...'",
      "  /opt/homebrew/bin/tart stop ${var.vm_name} 2>/dev/null || true",
      "  /opt/homebrew/bin/tart delete ${var.vm_name} 2>/dev/null || true",
      "fi",

      # Clone from the OCI image directly
      "echo 'Creating VM from Sonoma base...'",
      "/opt/homebrew/bin/tart clone ghcr.io/cirruslabs/macos-sonoma-base:latest ${var.vm_name}",

      # Configure VM resources
      "echo 'Configuring VM resources...'",
      "/opt/homebrew/bin/tart set ${var.vm_name} --cpu ${var.vm_cpu} --memory ${var.vm_memory}",

      # Start the VM
      "echo 'Starting VM...'",
      "/opt/homebrew/bin/tart run ${var.vm_name} --no-graphics &",

      # Give it more time to boot
      "echo 'Waiting for VM to boot (90 seconds)...'",
      "sleep 90",

      # Try to get IP multiple times
      "for i in {1..10}; do",
      "  IP=$(/opt/homebrew/bin/tart ip ${var.vm_name} 2>/dev/null || echo '')",
      "  if [ ! -z \"$IP\" ]; then",
      "    echo \"$IP\" > /tmp/${var.vm_name}_ip.txt",
      "    echo \"VM IP acquired: $IP\"",
      "    break",
      "  fi",
      "  echo \"Attempt $i - waiting for IP...\"",
      "  sleep 10",
      "done",

      # Verify we got an IP
      "if [ -f /tmp/${var.vm_name}_ip.txt ]; then",
      "  cat /tmp/${var.vm_name}_ip.txt",
      "else",
      "  echo 'ERROR: Could not get VM IP'",
      "  exit 1",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = var.mac_user
      host        = var.mac_host
      private_key = file("~/.ssh/id_rsa")
    }
  }

  triggers = {
    always_run = timestamp()
  }
}

# Get VM IP from remote Mac
resource "null_resource" "get_vm_ip" {
  depends_on = [null_resource.tart_vm]

  provisioner "local-exec" {
    command = "ssh ${var.mac_user}@${var.mac_host} 'cat /tmp/${var.vm_name}_ip.txt' > ${path.module}/vm_ip.txt"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Read the local copy of VM IP
data "local_file" "vm_ip" {
  depends_on = [null_resource.get_vm_ip]
  filename   = "${path.module}/vm_ip.txt"
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.get_vm_ip]

  content = templatefile("${path.module}/templates/inventory.tpl", {
    mac_host  = var.mac_host
    mac_user  = var.mac_user
    vm_name   = var.vm_name
    vm_ip     = chomp(data.local_file.vm_ip.content)
  })

  filename = "${path.module}/inventory.ini"
}

# Cleanup on destroy
resource "null_resource" "cleanup" {
  triggers = {
    vm_name  = var.vm_name
    mac_host = var.mac_host
    mac_user = var.mac_user
  }

  provisioner "remote-exec" {
    when = destroy

    inline = [
      "/opt/homebrew/bin/tart stop ${self.triggers.vm_name} || true",
      "/opt/homebrew/bin/tart delete ${self.triggers.vm_name} || true"
    ]

    connection {
      type        = "ssh"
      user        = self.triggers.mac_user
      host        = self.triggers.mac_host
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

output "vm_status" {
  value = {
    vm_name  = var.vm_name
    mac_host = var.mac_host
    vm_ip    = chomp(data.local_file.vm_ip.content)
  }

  description = "Status of the Tart VM deployment"
}
