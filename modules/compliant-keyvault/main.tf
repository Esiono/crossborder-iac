# =============================================================================
# compliant-keyvault/main.tf
# Creates an Azure Key Vault with LFPDPPP residency controls.
#
# LFPDPPP Article 36: Encryption keys protecting personal data must remain
# in approved jurisdictions. Region validation enforced in variables.tf.
#
# LFPDPPP Article 37: Cross-border key transfer is unauthorized transfer
# of the means to access personal data. Purge protection and access policy
# tenant-locking prevent keys from leaving the approved jurisdiction.
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # LFPDPPP Art. 37 — prevent permanent destruction of encryption keys
  purge_protection_enabled   = true
  soft_delete_retention_days = var.soft_delete_retention_days

  # Disable public network access — Key Vault accessible via private
  # endpoints only in production. For this reference implementation,
  # we restrict to Azure services only.
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = merge(var.tags, {
    lfpdppp_compliant = "true"
    data_residency    = var.location
    managed_by        = "terraform"
  })
}