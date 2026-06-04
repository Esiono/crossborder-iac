# =============================================================================
# environments/us-east2/main.tf
# East US 2 environment — US jurisdiction for cross-border fintech operations.
# Resources in this environment serve US-side workloads only.
# Personal data of Mexican customers must NOT be stored in this environment.
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-crossborder-us-east2"
  location = "eastus2"

  tags = {
    environment         = "us-east2"
    lfpdppp_compliant   = "true"
    managed_by          = "terraform"
    data_classification = "non-personal"
  }
}

module "storage" {
  source = "../../modules/compliant-storage"

  name                = "stcrossborderus001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "us-east2"
    purpose     = "application-data"
  }
}

module "keyvault" {
  source = "../../modules/compliant-keyvault"

  name                = "kv-crossborder-us-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = "564d7dc7-ad9f-4c53-8635-84684725f19a"

  tags = {
    environment = "us-east2"
    purpose     = "encryption-keys"
  }
}

module "network" {
  source = "../../modules/compliant-network"

  name                = "vnet-crossborder-us-east2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefixes = ["10.1.1.0/24"]
    }
    "snet-data" = {
      address_prefixes = ["10.1.2.0/24"]
    }
  }

  tags = {
    environment = "us-east2"
    purpose     = "application-network"
  }
}

module "observability" {
  source = "../../modules/observability-baseline"

  workspace_name      = "law-crossborder-us-east2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = 90

  diagnostic_targets = {
    "storage"  = module.storage.id
    "keyvault" = module.keyvault.id
    "vnet"     = module.network.vnet_id
  }

  tags = {
    environment = "us-east2"
    purpose     = "compliance-logging"
  }
}