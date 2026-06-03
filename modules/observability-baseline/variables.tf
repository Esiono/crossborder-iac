variable "location" {
  description = "Azure region where the Log Analytics Workspace will be created."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP compliance: Log Analytics Workspace must be in mexicocentral or eastus2 only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the workspace into."
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain logs. Minimum 30, maximum 730."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "diagnostic_targets" {
  description = "Map of resource IDs to send diagnostic logs to this workspace."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the workspace."
  type        = map(string)
  default     = {}
}