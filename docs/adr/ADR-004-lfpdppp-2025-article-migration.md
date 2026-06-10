# ADR-004: LFPDPPP 2025 Article Number Migration

**Date:** 2026-06-06
**Status:** Accepted
**Deciders:** Eduardo Siono

## Context

Mexico's data protection framework changed fundamentally on 20 March 2025
when the Diario Oficial de la Federación (DOF) published a complete rewrite
of the Ley Federal de Protección de Datos Personales en Posesión de los
Particulares (LFPDPPP). The 2025 reform introduced three changes that
directly affect this project:

**1. Article renumbering.**
The residency and cross-border transfer articles were renumbered:

| Obligation | 2010 law | 2025 law (DOF 20 marzo 2025) |
|---|---|---|
| Adequate protection requirement (data residency) | Art. 36 | **Art. 35** |
| Cross-border transfer authorization | Art. 37 | **Art. 36** |

**2. Enforcement authority replaced.**
The Instituto Nacional de Transparencia, Acceso a la Información y
Protección de Datos Personales (INAI) was dissolved. Enforcement authority
transferred to the **Secretaría Anticorrupción y Buen Gobierno (SABG)**.
SABG issued its first formal proceedings following the January 2026
cyber incidents, signaling active enforcement of the 2025 framework.

**3. Increased penalties.**
Criminal penalties of up to 5 years and fines up to 320,000 UMA
(~$3.86M USD, doubled for sensitive data categories) now apply under
the revised sanction framework in Arts. 142-148.

## Decision

Migrate all LFPDPPP article citations throughout the codebase from the
2010 numbering (Arts. 36-37) to the 2025 numbering (Arts. 35-36), and
replace all references to INAI with SABG.

All citations now qualify the law version explicitly as
`LFPDPPP (DOF 20 marzo 2025)` to distinguish from the superseded 2010 text
and to make the legal basis auditable — a reviewer can trace any violation
message back to the specific published law version.

**Files updated:**
- `policies/storage_residency.rego` — header and all 4 violation messages
- `modules/compliant-storage/main.tf` and `variables.tf`
- `modules/compliant-keyvault/main.tf` and `variables.tf`
- `modules/compliant-network/main.tf`
- `modules/observability-baseline/main.tf`
- `README.md` and `README.es.md` — all prose, table, and code-block citations
- `docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md`

## Consequences

**Positive:**
- All citations are accurate against the live regulatory text
- The explicit `(DOF 20 marzo 2025)` qualifier makes violation messages
  auditable against the published statute
- Git history documents when the migration occurred, serving as a
  compliance audit trail for the article renumbering event

**Negative:**
- Any external references to this project's violation messages (dashboards,
  runbooks, incident tickets) that cited the old article numbers are now
  stale and must be updated

## Broader Implication: Compliance-as-Code Is Not Static

This ADR illustrates a fundamental property of compliance-as-code:
**legal citations embedded in infrastructure code are not stable constants —
they are living references to a changing regulatory landscape.**

The 2025 LFPDPPP rewrite is not a hypothetical. The article numbers changed.
Without this migration:
- OPA violation messages would cite articles that do not exist in the 2025 text
- A legal reviewer comparing the code to the statute would find no match
  for "Art. 36" (residency) in the 2025 law
- The compliance audit trail would reference a superseded law version

Compliance-as-code platforms must include a process for tracking regulatory
changes and propagating them through the codebase — the same discipline
applied to dependency version upgrades. This project treats regulatory
citations as first-class dependencies that require maintenance.
