output "workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.name
}

output "primary_shared_key" {
  description = "Primary shared key for the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "location" {
  description = "Region where the workspace was deployed."
  value       = azurerm_log_analytics_workspace.main.location
}