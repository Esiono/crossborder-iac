# =============================================================================
# observability-baseline/main.tf
# Creates a Log Analytics Workspace with LFPDPPP residency controls.
#
# LFPDPPP Article 36: Audit logs describing access to personal data must
# remain in the same jurisdiction as the data itself. Diagnostic settings
# route logs to a region-local workspace only — never cross-region.
#
# All resources monitored by this workspace must be in the same region.
# Cross-region diagnostic routing is prohibited by design.
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  tags = merge(var.tags, {
    lfpdppp_compliant = "true"
    data_residency    = var.location
    managed_by        = "terraform"
  })
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = var.diagnostic_targets

  name                       = "diag-${each.key}-to-${var.workspace_name}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}