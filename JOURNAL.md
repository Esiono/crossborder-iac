# JOURNAL.md

## Day 1 — May 14, 2026 — Environment Setup & Project Scaffold

### What I built
Set up a complete local development environment from scratch on WSL2 Ubuntu:
installed Terraform v1.15.3 and Azure CLI v2.86.0, authenticated to Azure,
created the GitHub repository for CrossBorder-IaC, and established the full
directory structure for the project (modules, environments, policies, tests,
docs/adr, scripts). First commit pushed to GitHub. Branch protection enabled
on main — all future changes go through pull requests.

### What I learned
Git doesn't track empty directories — only files. The .gitkeep convention
solves this: an empty file whose only purpose is to make Git aware the
directory exists. Small thing, but it matters for communicating project
structure to anyone who clones the repo before any real code exists.

### What surprised me
The bootstrap problem: Terraform needs Azure Blob Storage to store its state
file, but you can't use Terraform to create that storage account because
Terraform has nowhere to store state yet. The solution is a one-time bash
script that runs outside Terraform. It's the one piece of infrastructure
intentionally not managed by IaC — and that's the correct decision, not a
shortcut.

### What I'd do differently
Install Windows Terminal before starting. The default WSL2 terminal window
doesn't support Ctrl+Shift+V for paste — I lost time figuring out that
right-click was the workaround. Windows Terminal handles this correctly
out of the box.

## Day 2 — May 15, 2026 — Bootstrap Script & Terraform Init

### What I built
Wrote `scripts/bootstrap-state-backend.sh` — an idempotent bash script that
creates the Azure infrastructure Terraform needs before it can run: a resource
group in West US 2, a storage account with a globally unique random suffix,
and two containers (one per environment). Then wrote the first real Terraform
files — `versions.tf` and `backend.tf` for `environments/mx-central` — and
ran `terraform init` successfully against the live Azure backend.

### What I learned
Azure requires explicit resource provider registration before you can use
certain services. `Microsoft.Storage` wasn't registered on my subscription,
which caused `az storage account create` to fail. The fix was
`az provider register --namespace Microsoft.Storage` followed by a polling
loop to wait for registration to complete. The bootstrap script now handles
this automatically so anyone cloning the repo won't hit the same issue.

### What surprised me
The `SubscriptionNotFound` error was a misleading message — it had nothing
to do with the subscription. Azure reported the wrong root cause. In
infrastructure work, error messages often describe a symptom rather than
the actual problem. Debugging means questioning the error message, not
just reading it.

### The bootstrap problem in practice
The circular dependency is real: Terraform needs Azure Blob Storage to store
its state file, but you can't use Terraform to create that storage account
because Terraform has nowhere to store state yet. The bash script exists to
break that circle — it runs once, manually, before Terraform ever touches
anything. The storage account it creates is permanent, not temporary, and
lives in a neutral region (West US 2) deliberately outside the LFPDPPP
residency scope.

### What I'd do differently
Register required Azure resource providers at the start of any new subscription
setup before running any infrastructure commands. Five minutes of provider
registration upfront would have saved thirty minutes of debugging.