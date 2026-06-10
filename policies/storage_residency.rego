# =============================================================================
# policies/storage_residency.rego
# OPA policy enforcing LFPDPPP data residency for Azure Storage Accounts.
#
# LFPDPPP (DOF 20 marzo 2025), Art. 35: Personal data may only be processed
# in jurisdictions with adequate protection levels.
# LFPDPPP (DOF 20 marzo 2025), Art. 36: Cross-border transfers require
# explicit authorization — geo-replication and VNet peering are prohibited.
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
# LFPDPPP Art. 35 — adequate protection requires approved jurisdictions
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    location := resource.values.location
    not allowed_regions[location]
    msg := sprintf(
        "LFPDPPP Art. 35 violation: Storage account '%s' is in region '%s'. Allowed regions: %v",
        [resource.name, location, allowed_regions]
    )
}

# =============================================================================
# RULE 2: Storage accounts must use LRS — no geo-replication allowed
# LFPDPPP Art. 36 — geo-replication transfers data across borders without
# explicit authorization
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    replication := resource.values.account_replication_type
    not allowed_replication_types[replication]
    msg := sprintf(
        "LFPDPPP Art. 36 violation: Storage account '%s' uses replication type '%s'. Only LRS is permitted — geo-replication transfers data across borders without explicit authorization.",
        [resource.name, replication]
    )
}

# =============================================================================
# RULE 3: Cross-tenant replication must be disabled
# LFPDPPP Art. 36 — data must not flow to foreign tenants
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    resource.values.cross_tenant_replication_enabled == true
    msg := sprintf(
        "LFPDPPP Art. 36 violation: Storage account '%s' has cross-tenant replication enabled. This permits data transfer to foreign tenants without explicit authorization.",
        [resource.name]
    )
}
# =============================================================================
# RULE 4: VNet peering between MX and US regions is prohibited
# LFPDPPP Art. 36 — peering creates a direct data path across borders
# without explicit authorization, violating cross-border transfer rules.
# =============================================================================
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_virtual_network_peering"
    msg := sprintf(
        "LFPDPPP Art. 36 violation: VNet peering resource '%s' detected. Cross-region VNet peering creates unauthorized data paths across borders. Peering between mexicocentral and eastus2 is prohibited.",
        [resource.name]
    )
}
