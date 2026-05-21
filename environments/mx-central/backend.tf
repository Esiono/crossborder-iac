terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-westus2"
    storage_account_name = "stterraformstate08926aad"
    container_name       = "tfstate-mx-central"
    key                  = "mx-central.terraform.tfstate"
  }
}