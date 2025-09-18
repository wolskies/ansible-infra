output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    debian12   = var.debian12_ip
    ubuntu2204 = var.ubuntu2204_ip
  }
}

output "ansible_inventory" {
  description = "Ansible inventory for created VMs"
  value = templatefile("${path.module}/templates/inventory.tpl", {
    debian12_ip   = var.debian12_ip
    ubuntu2204_ip = var.ubuntu2204_ip
    ansible_user  = var.ansible_user
  })
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    debian12_ip   = var.debian12_ip
    ubuntu2204_ip = var.ubuntu2204_ip
    ansible_user  = var.ansible_user
  })
  filename = "${path.module}/inventory.ini"
}
