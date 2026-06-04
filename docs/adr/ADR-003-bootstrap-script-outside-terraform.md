# ADR-003: Bootstrap Script Outside Terraform for State Backend

**Date:** 2026-05-28  
**Status:** Accepted  
**Deciders:** Eduardo Siono  

## Context

Terraform requires a state backend before it can run. The standard
Azure state backend uses Azure Blob Storage. This creates a circular
dependency:

- Terraform needs Azure Blob Storage to store state
- Creating Azure Blob Storage with Terraform requires state storage
- Therefore Terraform cannot create its own state backend

Three options exist to resolve this:

**Option A: Manual portal clicks**  
Create the storage account manually via the Azure portal. Not
reproducible, not auditable, not scriptable.

**Option B: Terraform with local state first, then migrate**  
Use local state to create the storage account, then migrate state
to the remote backend. Complex, error-prone, and requires careful
sequencing.

**Option C: Dedicated bootstrap bash script**  
A one-time idempotent bash script using Azure CLI creates the
state backend infrastructure before Terraform runs. Terraform then
uses the remote backend for all subsequent operations.

## Decision

Implement Option C — a dedicated bootstrap script at
`scripts/bootstrap-state-backend.sh`.

The script is:
- **Idempotent**: safe to run multiple times without creating
  duplicate resources
- **Self-documenting**: comments explain why each resource exists
  and why the state backend lives in West US 2 (neutral region,
  outside LFPDPPP residency scope)
- **Provider-aware**: registers required Azure resource providers
  before attempting resource creation
- **Auditable**: lives in version control with full Git history

## Consequences

**Positive:**
- Clean separation: bootstrap infrastructure vs. managed infrastructure
- Reproducible: any engineer can recreate the state backend from scratch
- Transparent: the circular dependency is explicitly documented
- West US 2 placement keeps state backend outside LFPDPPP scope

**Negative:**
- One piece of infrastructure exists outside Terraform's control
- State backend must be created before onboarding new engineers
- If bootstrap script and Terraform drift, manual reconciliation needed

## Implementation Notes

The bootstrap script must be run once before any `terraform init`.
It is not part of the normal Terraform workflow and should not be
run again unless the state backend needs to be recreated from scratch.

The script is documented in README.md with explicit instructions on
when and how to run it.