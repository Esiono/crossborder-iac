# =============================================================================
# environments/mx-central/main.tf
# Mexico Central environment — LFPDPPP primary jurisdiction.
# All resources in this environment are subject to full residency controls.
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-crossborder-mx-central"
  location = "mexicocentral"

  tags = {
    environment         = "mx-central"
    lfpdppp_compliant   = "true"
    managed_by          = "terraform"
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

module "keyvault" {
  source = "../../modules/compliant-keyvault"

  name                = "kv-crossborder-mx-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "mx-central"
    purpose     = "encryption-keys"
  }
}
module "network" {
  source = "../../modules/compliant-network"

  name                = "vnet-crossborder-mx-central"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "snet-data" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  tags = {
    environment = "mx-central"
    purpose     = "application-network"
  }
}
module "observability" {
  source = "../../modules/observability-baseline"

  workspace_name      = "law-crossborder-mx-central"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = 90

  diagnostic_targets = {
    "storage"  = module.storage.id
    "keyvault" = module.keyvault.id
    "vnet"     = module.network.vnet_id
  }

  tags = {
    environment = "mx-central"
    purpose     = "compliance-logging"
  }
}