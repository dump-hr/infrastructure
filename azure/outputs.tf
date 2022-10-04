output "vm_username" {
  value = azurerm_linux_virtual_machine.vm.admin_username
}

output "vm_password" {
  value = azurerm_linux_virtual_machine.vm.admin_password
  sensitive = true
}