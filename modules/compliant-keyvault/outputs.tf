output "id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.main.name
}

output "uri" {
  description = "URI of the Key Vault — used to access secrets and keys."
  value       = azurerm_key_vault.main.vault_uri
}

output "location" {
  description = "Region where the Key Vault was deployed."
  value       = azurerm_key_vault.main.location
}