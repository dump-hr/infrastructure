output "vm1-username" {
  value = azurerm_linux_virtual_machine.vm1.admin_username
}

output "vm1-password" {
  value = azurerm_linux_virtual_machine.vm1.admin_password
  sensitive = true
}