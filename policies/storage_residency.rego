# =============================================================================
# policies/storage_residency.rego
# OPA policy enforcing LFPDPPP data residency for Azure Storage Accounts.
#
# LFPDPPP Article 36: Personal data transfers require adequate protection.
# LFPDPPP Article 37: Cross-border transfers require explicit authorization.
#
# These rules evaluate Terraform plan JSON output via Conftest in CI.
# Violations block the pull request before any terraform apply runs.
# =============================================================================

package crossborder.storage

import rego.v1

# Allowed regions under LFPDPPP jurisdiction mapping
allowed_regions := {"mexicocentral", "eastus2"}

# Allowed replication types — LRS only, no geo-replication
allowed_replication_types := {"LRS"}

# =============================================================================
# RULE 1: Storage accounts must be in approved regions
# LFPDPPP Art. 36 — adequate protection requires approved jurisdictions
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    location := resource.values.location
    not allowed_regions[location]
    msg := sprintf(
        "LFPDPPP Art. 36 violation: Storage account '%s' is in region '%s'. Allowed regions: %v",
        [resource.name, location, allowed_regions]
    )
}

# =============================================================================
# RULE 2: Storage accounts must use LRS — no geo-replication allowed
# LFPDPPP Art. 37 — geo-replication transfers data across borders without
# explicit authorization
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    replication := resource.values.account_replication_type
    not allowed_replication_types[replication]
    msg := sprintf(
        "LFPDPPP Art. 37 violation: Storage account '%s' uses replication type '%s'. Only LRS is permitted — geo-replication transfers data across borders without explicit authorization.",
        [resource.name, replication]
    )
}

# =============================================================================
# RULE 3: Cross-tenant replication must be disabled
# LFPDPPP Art. 37 — data must not flow to foreign tenants
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.values.cross_tenant_replication_enabled == true
    msg := sprintf(
        "LFPDPPP Art. 37 violation: Storage account '%s' has cross-tenant replication enabled. This permits data transfer to foreign tenants without explicit authorization.",
        [resource.name]
    )
}