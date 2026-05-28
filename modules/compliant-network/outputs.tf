output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet names to their resource IDs."
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}

output "location" {
  description = "Region where the VNet was deployed."
  value       = azurerm_virtual_network.main.location
}