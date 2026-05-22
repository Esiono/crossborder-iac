output "id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "location" {
  description = "Region where the storage account was deployed."
  value       = azurerm_storage_account.main.location
}