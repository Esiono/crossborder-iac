# CrossBorder-IaC

🇪🇸 [Lee esto en español](README.es.md)

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![OPA](https://img.shields.io/badge/OPA-Conftest-4E5A65?logo=openpolicyagent&logoColor=white)](https://www.conftest.dev/)
[![Azure](https://img.shields.io/badge/Azure-Mexico_Central_|_East_US_2-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Checkov](https://img.shields.io/badge/Checkov-Static_Analysis-5C4EE5)](https://www.checkov.io/)
[![CI](https://github.com/Esiono/crossborder-iac/actions/workflows/terraform-compliance.yml/badge.svg)](https://github.com/Esiono/crossborder-iac/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Policy-as-code platform enforcing Mexico's LFPDPPP (DOF 20 marzo 2025) data residency law across US–Mexico Azure deployments.** Three enforcement layers — IaC variables, CI policy gates, and runtime Azure Policy — ensure personal data never leaves its authorized region.

---

### The Problem: Automated Risk in a $872B Market

In March 2025, Mexico completely rewrote its data protection law (LFPDPPP), introducing criminal penalties of up to 5 years and fines up to $3.86M USD (doubled for sensitive data).[¹](#sources) Following the January 2026 cyber incidents, the new enforcement authority is signaling aggressive action.[²](#sources)

The US–Mexico corridor is booming, but this rapid growth has created a massive, unmitigated infrastructure gap:

- **The Scale:** $872.8 billion in US–Mexico goods trade in 2025 — the largest bilateral trade relationship in the world.[³](#sources) Over 5,200 companies operate under the IMMEX nearshore program, handling regulated personal data daily.[⁴](#sources)
- **The Infrastructure Gap:** Microsoft launched Azure Mexico Central in 2024 for in-country data residency,[⁵](#sources) but there are no standardized IaC patterns to enforce the new LFPDPPP compliance across multi-region deployments.
- **The Threat:** A single misconfigured Terraform file — a geo-replicated storage account, an unauthorized VNet peering, or a cross-tenant replication toggle — is all it takes to trigger an international data transfer violation.

**The Solution:** This project codifies the 2025 LFPDPPP mandates directly into infrastructure-as-code, ensuring cross-border data violations are caught at the Pull Request stage — not during a legal audit.

#### Sources
¹ [LFPDPPP penalty framework](https://clym.io/regulations/mexican-privacy-law-lfpdppp) — Fines from 100 to 320,000 UMA (~$3.86M USD), doubled for sensitive data. Criminal penalties per [Recording Law](https://www.recordinglaw.com/world-laws/world-data-privacy-laws/mexico-data-privacy-laws/).

² [Recording Law — LFPDPPP 2025 Guide](https://www.recordinglaw.com/world-laws/world-data-privacy-laws/mexico-data-privacy-laws/) — No formal sanctions published yet under the 2025 law as of May 2026, but early SABG proceedings after the January 2026 cyber incidents indicate the authority will enforce aggressively.

³ [USTR — Mexico trade data](https://ustr.gov/countries-regions/americas/mexico) — U.S. goods trade with Mexico totaled $872.8 billion in 2025. Confirmed by [U.S. Census Bureau data](https://www.freightwaves.com/news/us-mexico-trade-hits-new-high-of-872b-in-2025).

⁴ [IMMEX program data](https://hub.americanindustriesgroup.com/insights/understanding-nearshoring-benefits-manufacturing-companies-mexico/) — Approximately 5,220 companies operate under IMMEX, employing an estimated 2.94 million workers.

⁵ [Azure Mexico Central](https://news.microsoft.com/es-xl/microsoft-launches-its-first-hyper-scale-cloud-datacenter-region-in-mexico/) — Microsoft's first hyperscale cloud region in Mexico, launched May 2024.

## How It Works

Three enforcement layers catch violations at different stages, so nothing reaches production unchecked:

```text
┌──────────────────────────┐    ┌──────────────────────────┐    ┌──────────────────────────┐
│  Layer 1 — IaC           │ →  │  Layer 2 — CI            │ →  │  Layer 3 — Runtime       │
│  Terraform modules       │    │  GitHub Actions PR gate  │    │  Azure Policy            │
│  Variable validation     │    │  OPA (Conftest) + Checkov│    │  Drift detection         │
│  Catches at plan time    │    │  Catches at PR merge     │    │  Catches post-deploy     │
│  modules/                │    │  .github/workflows/      │    │  (planned — ADR-002)     │
└──────────────────────────┘    └──────────────────────────┘    └──────────────────────────┘
```

| Control | Enforcement Layer | Mechanism |
|---|---|---|
| Data residency (Art. 35) | IaC | Terraform variable validation — only mexicocentral and eastus2 allowed |
| Geo-replication ban (Art. 36) | IaC + CI | Storage accounts hardcoded to LRS + OPA rule rejects anything else |
| Cross-tenant replication (Art. 36) | IaC + CI | Disabled at resource level + OPA rule validates plan output |
| VNet peering prohibition (Art. 36) | CI | OPA rule blocks azurerm_virtual_network_peering resources entirely |
| Runtime drift detection | Runtime | Azure Policy assignments per environment (planned — see [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md)) |
| Audit log residency (Art. 35) | IaC | Log Analytics Workspace and diagnostic settings co-located with resources |

## Legal Requirements in Code

LFPDPPP citations are enforced in the infrastructure itself. Here is how Article 35 enforces region locking:

```hcl
variable "location" {
  description = "Azure region where the storage account will be created."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP Art. 35 (DOF 20 marzo 2025): storage must be deployed to mexicocentral or eastus2 only."
  }
}
```

And the OPA policy that catches geo-replication in CI before any PR can merge:

```rego
# Real Terraform plans nest resources under root_module.child_modules[_]
# when calling modules — walk() collects them regardless of nesting depth.
all_resources contains resource if {
    walk(input.planned_values.root_module, [path, value])
    path[count(path) - 1] == "resources"
    resource := value[_]
}

deny contains msg if {
    resource := all_resources[_]
    resource.type == "azurerm_storage_account"
    replication := resource.values.account_replication_type
    not allowed_replication_types[replication]
    msg := sprintf(
        "LFPDPPP Art. 36 violation: Storage account '%s' uses replication type '%s'. Only LRS is permitted — geo-replication transfers data across borders without explicit authorization.",
        [resource.name, replication]
    )
}
```

## Architecture

```text
crossborder-iac/
├── modules/
│   ├── compliant-storage/        # Storage account — LRS only, Art. 36
│   ├── compliant-keyvault/       # Key Vault — purge protection, network ACLs, tenant-locked
│   ├── compliant-network/        # VNet + subnets — no peering by design
│   └── observability-baseline/   # Log Analytics — region-local logs, Art. 35
├── environments/
│   ├── mx-central/               # Mexico Central — data_classification = "personal"
│   └── us-east2/                 # East US 2 — data_classification = "non-personal"
├── policies/
│   └── storage_residency.rego    # 4 OPA rules enforcing Arts. 35-36
├── tests/
│   └── fixtures/                 # Terraform plan JSON for policy testing
├── scripts/
│   └── bootstrap-state-backend.sh  # Idempotent state storage setup (West US 2)
├── docs/
│   └── adr/                      # Architecture Decision Records
├── .github/
│   └── workflows/                # PR checks: terraform plan + OPA + Checkov
└── conftest.toml
```

## Modules

**compliant-storage** — Azure Storage Account locked to LRS replication. Variable validation rejects GRS/ZRS/GZRS at plan time. Cross-tenant replication disabled. Enforces Art. 36.

**compliant-keyvault** — Azure Key Vault with purge protection enabled, 90-day soft delete, network ACLs denying public access, and tenant-level locking. Secrets never leave the authorized tenant boundary.

**compliant-network** — VNet and subnets with non-overlapping address spaces per region (Mexico: 10.0.0.0/16, US: 10.1.0.0/16). No peering resources by design — cross-region network connectivity is architecturally prohibited, not just policy-blocked.

**observability-baseline** — Log Analytics Workspace with diagnostic settings ensuring audit logs stay in the same region as the resources they monitor. Enforces Art. 35 data residency for compliance evidence.

## OPA Policy Rules

All four rules run on every PR via Conftest against terraform plan output:

| Rule | LFPDPPP Article | What It Catches |
|---|---|---|
| Region allowlist | Art. 35 | Storage accounts outside mexicocentral or eastus2 |
| LRS replication only | Art. 36 | Any replication type other than LRS |
| Cross-tenant replication disabled | Art. 36 | Cross-tenant replication left enabled |
| VNet peering prohibited | Art. 36 | Any azurerm_virtual_network_peering resource in the plan |

## CI/CD Pipeline

Every pull request triggers:

1. Lint — `terraform fmt -check`, `terraform validate`, and `tflint`; must pass before the jobs below run
2. terraform plan — Generates a plan JSON for the target environment
3. Conftest OPA check — Runs all Rego policies against the plan output
4. Checkov static analysis — Scans HCL for security misconfigurations

Branch protection on main requires all checks to pass. No direct pushes.

### CI Security

CI secrets are scoped to trusted branches only. Pull requests from forks require maintainer approval before workflows execute. All GitHub Actions are pinned to commit SHAs and Checkov is version-locked for supply-chain integrity.

### Pre-commit Hooks

Install once with `pip install pre-commit && pre-commit install`. Hooks then run automatically on every commit — `terraform fmt`, `terraform validate`, `tflint`, and `conftest` against the test fixtures.

## Architecture Decision Records

| ADR | Decision | Rationale |
|---|---|---|
| [ADR-001](docs/adr/ADR-001-local-state-backend.md) | Local state backend | Personal Azure account auth constraints prevent remote backend; bootstrap script provisions state storage for future migration |
| [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md) | Dual enforcement: OPA + Azure Policy | OPA catches violations pre-deploy in CI; Azure Policy detects drift post-deploy at runtime |
| [ADR-003](docs/adr/ADR-003-bootstrap-script-outside-terraform.md) | Bootstrap script outside Terraform | State backend cannot be managed by the Terraform that depends on it — circular dependency resolved with idempotent shell script |
| [ADR-004](docs/adr/ADR-004-lfpdppp-2025-article-migration.md) | LFPDPPP 2025 article migration | Mexico's complete law rewrite (DOF 20 marzo 2025) renumbered the residency and transfer articles; compliance citations across all code and docs were migrated to stay legally accurate |

## Prerequisites

- Terraform >= 1.5
- Azure CLI (az login with active subscription)
- Conftest (for OPA policy checks)
- Checkov (for static analysis)

*Pre-commit hooks require a Unix-like shell (Linux, macOS, or WSL on Windows). They will not run in native Windows PowerShell.*

## Quick Start

Install Conftest: see [conftest.dev](https://www.conftest.dev/) for installation instructions.

```bash
git clone https://github.com/Esiono/crossborder-iac.git
cd crossborder-iac
chmod +x scripts/bootstrap-state-backend.sh
./scripts/bootstrap-state-backend.sh
cd environments/mx-central
terraform init
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
conftest test plan.json -p ../../policies/ --namespace crossborder.storage
```

## Sample Enforcement Output

This is real output from running Conftest against the noncompliant fixtures in `tests/fixtures/` — a storage account in the wrong region with GRS replication and cross-tenant replication enabled, the same misconfiguration nested inside a child module, and a prohibited VNet peering resource:

```text
$ conftest test tests/fixtures/ --policy policies/ --namespace crossborder.storage

FAIL - tests/fixtures/noncompliant_storage.json - crossborder.storage - LFPDPPP Art. 35 violation: Storage account 'bad' is in region 'westeurope'. Allowed regions: {"eastus2", "mexicocentral"}
FAIL - tests/fixtures/noncompliant_storage.json - crossborder.storage - LFPDPPP Art. 36 violation: Storage account 'bad' has cross-tenant replication enabled. This permits data transfer to foreign tenants without explicit authorization.
FAIL - tests/fixtures/noncompliant_storage.json - crossborder.storage - LFPDPPP Art. 36 violation: Storage account 'bad' uses replication type 'GRS'. Only LRS is permitted — geo-replication transfers data across borders without explicit authorization.
FAIL - tests/fixtures/noncompliant_storage_module.json - crossborder.storage - LFPDPPP Art. 35 violation: Storage account 'main' is in region 'westeurope'. Allowed regions: {"eastus2", "mexicocentral"}
FAIL - tests/fixtures/noncompliant_storage_module.json - crossborder.storage - LFPDPPP Art. 36 violation: Storage account 'main' has cross-tenant replication enabled. This permits data transfer to foreign tenants without explicit authorization.
FAIL - tests/fixtures/noncompliant_storage_module.json - crossborder.storage - LFPDPPP Art. 36 violation: Storage account 'main' uses replication type 'GRS'. Only LRS is permitted — geo-replication transfers data across borders without explicit authorization.
FAIL - tests/fixtures/noncompliant_peering.json - crossborder.storage - LFPDPPP Art. 36 violation: VNet peering resource 'mx_to_us' detected. Cross-region VNet peering creates unauthorized data paths across borders. Peering between mexicocentral and eastus2 is prohibited.

12 tests, 5 passed, 0 warnings, 7 failures, 0 exceptions
```

*Output captured from v1.0.0 test fixtures. Run `conftest test tests/fixtures/ --policy policies/ --namespace crossborder.storage` to verify against current rules.*

A non-zero exit code blocks the pull request — this is the check that runs in `compliance-mx-central` and `compliance-us-east2` on every PR.

## What's Next

This is a reference implementation, not a finished platform. Planned work:

- **Azure Policy as enforcement Layer 3** — runtime drift detection per [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md), currently the one layer of defense-in-depth that exists on paper but not in Terraform.
- **Remote state migration to Azure Blob** — replace the local backend once a service principal is in place, per [ADR-001](docs/adr/ADR-001-local-state-backend.md) and [ADR-003](docs/adr/ADR-003-bootstrap-script-outside-terraform.md).
- **Private endpoints for Storage and Key Vault** — both resources already block public network access; private endpoints would close the resulting connectivity gap for legitimate access.
- **Expanded OPA policies for additional resource types** — the current four rules cover storage and networking; Key Vault and Log Analytics configuration drift aren't yet policy-checked.

## Author

**Eduardo Ayala Siono** · Data Analyst / Data Engineer

6+ years ensuring production data integrity at scale. Based in Mexicali, on the US–Mexico border.

Built this project after researching the operational gaps US companies face under Mexico's 2025 LFPDPPP reform: $3.86M fines, criminal penalties, and no standardized infrastructure patterns to enforce them.

📍 Mexicali, MX · US Pacific · EN/ES C2

[linkedin.com/in/eduardosiono](https://linkedin.com/in/eduardosiono)

---

Licensed under MIT. This is a reference implementation for portfolio purposes. LFPDPPP (DOF 20 marzo 2025) compliance requirements should be validated with legal counsel for production deployments.