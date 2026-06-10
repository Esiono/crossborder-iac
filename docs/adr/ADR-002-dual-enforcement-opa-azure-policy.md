# ADR-002: Dual Enforcement — OPA in CI + Azure Policy at Runtime

**Date:** 2026-05-28  
**Status:** Accepted  
**Deciders:** Eduardo Siono  

## Context

LFPDPPP (DOF 20 marzo 2025) Arts. 35-36 require that data residency controls
be enforced continuously — not just at deployment time. Two enforcement options exist:

**Option A: OPA in CI only**  
Run Conftest against `terraform plan` output on every pull request.
Violations block the PR before merge.

**Option B: Azure Policy only**  
Deploy Azure Policy definitions that deny non-compliant resource
configurations at the Azure control plane level.

**Option C: Both layers (defense in depth)**  
OPA in CI catches violations at PR time. Azure Policy catches drift
from any source — Portal clicks, ARM templates, other IaC tools, or
misconfigured pipelines that bypass the CI workflow.

## Decision

Implement both layers (Option C).

OPA in CI provides fast feedback to engineers — violations appear in
the pull request before merge, not after deployment. Azure Policy
provides runtime enforcement that cannot be bypassed regardless of
how a resource is created.

The OPA rules and Azure Policy definitions share a common compliance
rationale — both cite the same LFPDPPP articles — making the policy
intent traceable from legal requirement to code to runtime enforcement.

## Consequences

**Positive:**
- CI layer: engineers see violations in seconds, not minutes
- Runtime layer: catches drift from Portal, ARM, or other tools
- Dual audit trail: both CI logs and Azure Policy compliance reports
- Defense in depth: one layer failing does not remove all protection

**Negative:**
- Two policy systems to maintain — OPA Rego and Azure Policy JSON
- Risk of drift between the two layers if not kept in sync
- Azure Policy deployment requires elevated permissions

## Implementation Notes

OPA policies live in `policies/` and are evaluated by Conftest in
`.github/workflows/terraform-compliance.yml`.

Azure Policy definitions are the next implementation milestone —
they will be deployed via Terraform and reference the same LFPDPPP
articles as the OPA rules.