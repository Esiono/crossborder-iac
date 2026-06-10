# =============================================================================
# compliant-storage/main.tf
# Creates an Azure Storage Account with LFPDPPP residency controls.
#
# LFPDPPP (DOF 20 marzo 2025), Art. 35: Personal data may only be processed
# in jurisdictions with adequate protection levels. This module enforces
# deployment to pre-approved regions only (see variables.tf location validation).
#
# LFPDPPP (DOF 20 marzo 2025), Art. 36: Cross-border transfers require explicit
# authorization. Geo-replication is disabled to prevent unauthorized transfers.
# =============================================================================

resource "azurerm_storage_account" "main" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # LFPDPPP Art. 36 — disable all cross-region replication
  cross_tenant_replication_enabled = false

  # Security baseline
  # HTTPS-only traffic is enforced by default in azurerm v4 — no explicit flag needed
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
  }

  tags = merge(var.tags, {
    lfpdppp_compliant = "true"
    data_residency    = var.location
    managed_by        = "terraform"
  })
}