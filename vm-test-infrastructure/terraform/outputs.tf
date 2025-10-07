# Output VM information for testing

output "vm_info" {
  description = "VM connection information"
  value = {
    for name, vm in libvirt_domain.test_vms : name => {
      ip_address  = local.vms[name].ip
      os_family   = local.vms[name].os_family
      test_type   = local.vms[name].test_type
      ssh_command = "ssh -F ../ssh-config ed@${local.vms[name].ip}"
    }
  }
}

output "inventory_created" {
  description = "Ansible inventory file location"
  value       = "inventory/hosts.ini"
}

output "ssh_config_created" {
  description = "SSH configuration file location"
  value       = "ssh-config"
}

output "test_summary" {
  description = "Test environment summary"
  value = {
    total_vms = length(local.vms)
    platforms = [for vm in local.vms : "${vm.os_family}"]
    server_vms = [for name, vm in local.vms : name if vm.test_type == "server"]
    workstation_vms = [for name, vm in local.vms : name if vm.test_type == "workstation"]
  }
}
