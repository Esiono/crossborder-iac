# ADR-001: Local State Backend Instead of Azure Blob Storage

**Date:** 2026-05-28  
**Status:** Accepted  
**Deciders:** Eduardo Siono  

## Context

Terraform requires a remote state backend to support team collaboration,
state locking, and CI/CD pipelines. Azure Blob Storage with lease-based
locking is the standard backend for Azure-based Terraform projects.

During initial setup, all authentication methods to the Azure Blob Storage
backend failed with HTTP 403 errors on a personal Microsoft account
(live.com). Methods attempted:

- Azure CLI OAuth token (default)
- Storage account access key via `ARM_ACCESS_KEY`
- SAS token via `sas_token` backend parameter
- Explicit RBAC role assignment (Storage Blob Data Contributor)

Root cause: personal Microsoft accounts (live.com) have known OAuth token
format incompatibilities with Azure Storage's blob authentication layer
when accessed from WSL2 on certain network configurations.

## Decision

Use a local state backend for this reference implementation. The backend
configuration is excluded from version control via `.gitignore`.

The `scripts/bootstrap-state-backend.sh` script and the Azure Blob
infrastructure (resource group, storage account, containers) remain in
place for when this project is deployed in a production context with a
service principal or managed identity.

## Consequences

**Positive:**
- Unblocks development immediately
- All module logic, OPA policies, and CI/CD remain fully functional
- The bootstrap infrastructure is ready for production use

**Negative:**
- State is not shared — only works on a single machine
- No state locking — concurrent applies could corrupt state
- Not suitable for team use without migrating to remote backend

## Migration Path

To migrate to Azure Blob backend in production:
1. Use a service principal (`az ad sp create-for-rbac`) instead of a
   personal account
2. Assign `Storage Blob Data Contributor` role to the service principal
3. Update `backend.tf` to use `azurerm` backend with service principal
   credentials via environment variables
4. Run `terraform init -migrate-state`