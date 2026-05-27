variable "name" {
  description = "Name of the storage account. Must be globally unique, lowercase, 3-24 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region where the storage account will be created."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP compliance: storage must be deployed to mexicocentral or eastus2 only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the storage account into."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the storage account."
  type        = map(string)
  default     = {}
}