#!/bin/bash
set -euo pipefail
# =============================================================================
# bootstrap-state-backend.sh
# Creates the Azure storage account used by Terraform for remote state.
#
# WHY THIS SCRIPT EXISTS:
# Terraform cannot create its own state backend — circular dependency.
# This script runs ONCE, manually, before any Terraform command.
# After this runs, everything else is managed by Terraform.
#
# LFPDPPP NOTE:
# The state backend lives in West US 2 (neutral region) intentionally.
# It contains Terraform metadata, not customer PII.
# Residency constraints apply to mx-central and us-east2 only.
#
# IDEMPOTENT: safe to run multiple times — will not create duplicates.
# =============================================================================
# --- Configuration -----------------------------------------------------------
RESOURCE_GROUP="rg-tfstate-westus2"
LOCATION="westus2"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_MX="tfstate-mx-central"
CONTAINER_US="tfstate-us-east2"
SUBSCRIPTION_ID="REDACTED_SUBSCRIPTION_ID"
# --- Provider Registration ---------------------------------------------------
echo "Ensuring required Azure resource providers are registered..."
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights

echo "Waiting for Microsoft.Storage registration..."
while [[ $(az provider show --namespace Microsoft.Storage \
  --query "registrationState" -o tsv) != "Registered" ]]; do
  echo "  Still registering... waiting 10 seconds"
  sleep 10
done
echo "All providers ready."
# --- Resource Group ----------------------------------------------------------
echo "Creating resource group: $RESOURCE_GROUP"

if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"
  echo "Resource group created."
else
  echo "Resource group already exists. Skipping."
fi
# --- Storage Account ---------------------------------------------------------
echo "Creating storage account: $STORAGE_ACCOUNT"

if ! az storage account show --name "$STORAGE_ACCOUNT" \
     --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --subscription "$SUBSCRIPTION_ID" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --enable-hierarchical-namespace false
  echo "Storage account created: $STORAGE_ACCOUNT"
else
  echo "Storage account already exists. Skipping."
fi
# --- Containers --------------------------------------------------------------
echo "Creating state containers..."

for CONTAINER in "$CONTAINER_MX" "$CONTAINER_US"; do
  if ! az storage container show \
       --name "$CONTAINER" \
       --account-name "$STORAGE_ACCOUNT" \
       --auth-mode login &>/dev/null; then
    az storage container create \
      --name "$CONTAINER" \
      --account-name "$STORAGE_ACCOUNT" \
      --auth-mode login
    echo "Container created: $CONTAINER"
  else
    echo "Container already exists: $CONTAINER. Skipping."
  fi
done

# --- Summary -----------------------------------------------------------------
echo ""
echo "Bootstrap complete. Add these values to your backend configuration:"
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER_MX\" (for mx-central)"
echo "  container_name       = \"$CONTAINER_US\" (for us-east2)"