# =============================================================================
# environments/mx-central/main.tf
# Mexico Central environment — LFPDPPP primary jurisdiction.
# All resources in this environment are subject to full residency controls.
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-crossborder-mx-central"
  location = "mexicocentral"

  tags = {
    environment       = "mx-central"
    lfpdppp_compliant = "true"
    managed_by        = "terraform"
    data_classification = "personal"
  }
}

module "storage" {
  source = "../../modules/compliant-storage"

  name                = "stcrossbordermx001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "mx-central"
    purpose     = "application-data"
  }
}