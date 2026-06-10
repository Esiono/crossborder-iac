variable "name" {
  description = "Name of the Key Vault. 3-24 chars, alphanumeric and hyphens only."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault name must be 3-24 chars, start with a letter, end with a letter or digit, and contain only alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region where the Key Vault will be created."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP Art. 35 (DOF 20 marzo 2025): Key Vault must be deployed to mexicocentral or eastus2 only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the Key Vault into."
  type        = string
}

variable "soft_delete_retention_days" {
  description = "Days to retain deleted Key Vault and its contents. Minimum 7, maximum 90."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "tags" {
  description = "Tags to apply to the Key Vault."
  type        = map(string)
  default     = {}
}