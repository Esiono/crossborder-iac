# =============================================================================
# compliant-network/main.tf
# Creates an Azure VNet with LFPDPPP residency controls.
#
# LFPDPPP (DOF 20 marzo 2025), Art. 35: Network infrastructure processing
# personal data must remain within approved jurisdictions.
# Region validation enforced in variables.tf.
#
# LFPDPPP (DOF 20 marzo 2025), Art. 36: VNet peering between MX and US regions
# is prohibited — it creates a direct data path across borders without explicit
# authorization. Peering is not defined in this module by design.
# No peering resources are created here. OPA enforces this at CI time.
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = merge(var.tags, {
    lfpdppp_compliant = "true"
    data_residency    = var.location
    managed_by        = "terraform"
  })
}

resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}