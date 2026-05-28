variable "name" {
  description = "Name of the Virtual Network."
  type        = string
}

variable "location" {
  description = "Azure region where the VNet will be created."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP compliance: VNet must be deployed to mexicocentral or eastus2 only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the VNet into."
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet in CIDR notation."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets to create inside the VNet."
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to the VNet and subnets."
  type        = map(string)
  default     = {}
}