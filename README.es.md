# CrossBorder-IaC

🇺🇸 [Read this in English](README.md)

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![OPA](https://img.shields.io/badge/OPA-Conftest-4E5A65?logo=openpolicyagent&logoColor=white)](https://www.conftest.dev/)
[![Azure](https://img.shields.io/badge/Azure-Mexico_Central_|_East_US_2-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Checkov](https://img.shields.io/badge/Checkov-Análisis_Estático-5C4EE5)](https://www.checkov.io/)
[![CI](https://github.com/Esiono/crossborder-iac/actions/workflows/terraform-compliance.yml/badge.svg)](https://github.com/Esiono/crossborder-iac/actions)
[![License: MIT](https://img.shields.io/badge/Licencia-MIT-green.svg)](LICENSE)

> **Plataforma de policy-as-code que implementa los requisitos de residencia de datos de la LFPDPPP (DOF 20 marzo 2025) de México en despliegues Azure entre EE.UU. y México.** Tres capas de enforcement — variables de IaC, gates de políticas en CI, y Azure Policy en runtime — aseguran que los datos personales nunca abandonen su región autorizada.

---

### El Problema: Riesgo Automatizado en un Mercado de $872B

En marzo de 2025, México reescribió completamente su ley de protección de datos (LFPDPPP), introduciendo sanciones penales de hasta 5 años y multas de hasta $3.86M USD (duplicadas para datos sensibles).[¹](#fuentes) Tras los ciberincidentes de enero de 2026, la nueva autoridad de aplicación está señalando acciones agresivas.[²](#fuentes)

El corredor EE.UU.–México está en auge, pero este crecimiento acelerado ha creado una enorme brecha de infraestructura sin mitigar:

- **La Escala:** $872.8 mil millones en comercio de bienes EE.UU.–México en 2025 — la relación comercial bilateral más grande del mundo.[³](#fuentes) Más de 5,200 empresas operan bajo el programa nearshore IMMEX, manejando datos personales regulados diariamente.[⁴](#fuentes)
- **La Brecha de Infraestructura:** Microsoft lanzó Azure Mexico Central en 2024 para residencia de datos en el país,[⁵](#fuentes) pero no existen patrones estandarizados de IaC para aplicar el cumplimiento de la nueva LFPDPPP en despliegues multi-región.
- **La Amenaza:** Un solo archivo Terraform mal configurado — una cuenta de almacenamiento geo-replicada, un peering de VNet no autorizado, o un toggle de replicación cross-tenant — es todo lo que se necesita para disparar una violación de transferencia internacional de datos.

**La Solución:** Este proyecto codifica los mandatos de la LFPDPPP 2025 directamente en infraestructura-como-código, asegurando que las violaciones de datos transfronterizos se detecten en la etapa de Pull Request — no durante una auditoría legal.

#### Fuentes

¹ [Marco de sanciones LFPDPPP](https://clym.io/regulations/mexican-privacy-law-lfpdppp) — Multas de 100 a 320,000 UMA (~$3.86M USD), duplicadas para datos sensibles. Sanciones penales según [Recording Law](https://www.recordinglaw.com/world-laws/world-data-privacy-laws/mexico-data-privacy-laws/).

² [Recording Law — Guía LFPDPPP 2025](https://www.recordinglaw.com/world-laws/world-data-privacy-laws/mexico-data-privacy-laws/) — Sin sanciones formales publicadas bajo la ley 2025 hasta mayo 2026, pero los primeros procedimientos del SABG tras los ciberincidentes de enero 2026 indican que la autoridad aplicará la ley agresivamente.

³ [USTR — Datos comerciales con México](https://ustr.gov/countries-regions/americas/mexico) — El comercio de bienes de EE.UU. con México totalizó $872.8 mil millones en 2025. Confirmado por [datos del U.S. Census Bureau](https://www.freightwaves.com/news/us-mexico-trade-hits-new-high-of-872b-in-2025).

⁴ [Datos del programa IMMEX](https://hub.americanindustriesgroup.com/insights/understanding-nearshoring-benefits-manufacturing-companies-mexico/) — Aproximadamente 5,220 empresas operan bajo IMMEX, empleando un estimado de 2.94 millones de trabajadores.

⁵ [Azure Mexico Central](https://news.microsoft.com/es-xl/microsoft-anuncia-el-inicio-de-operaciones-de-la-primera-region-de-centros-de-datos-de-nube-a-hiper-escala-en-mexico/) — Primera región de nube hiperescala de Microsoft en México, lanzada en mayo 2024.

## Cómo Funciona

Tres capas de enforcement detectan violaciones en diferentes etapas, asegurando que nada llegue a producción sin verificar:

```text
┌──────────────────────────┐    ┌──────────────────────────┐    ┌──────────────────────────┐
│  Capa 1 — IaC            │ →  │  Capa 2 — CI             │ →  │  Capa 3 — Runtime        │
│  Módulos Terraform       │    │  Gate de PR en Actions   │    │  Azure Policy            │
│  Validación de variables │    │  OPA (Conftest) + Checkov│    │  Detección de drift      │
│  Detecta en plan time    │    │  Detecta al hacer merge  │    │  Detecta post-deploy     │
│  modules/                │    │  .github/workflows/      │    │  (planificado — ADR-002) │
└──────────────────────────┘    └──────────────────────────┘    └──────────────────────────┘
```

| Control | Capa de Enforcement | Mecanismo |
|---|---|---|
| Residencia de datos (Art. 35) | IaC | Validación de variables Terraform — solo mexicocentral y eastus2 permitidos |
| Prohibición de geo-replicación (Art. 36) | IaC + CI | Cuentas de almacenamiento forzadas a LRS + regla OPA rechaza cualquier otra |
| Replicación cross-tenant (Art. 36) | IaC + CI | Deshabilitada a nivel de recurso + regla OPA valida la salida del plan |
| Prohibición de VNet peering (Art. 36) | CI | Regla OPA bloquea recursos azurerm_virtual_network_peering por completo |
| Detección de drift en runtime | Runtime | Asignaciones de Azure Policy por entorno (planificado — ver [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md)) |
| Residencia de logs de auditoría (Art. 35) | IaC | Log Analytics Workspace y configuración de diagnósticos co-ubicados con los recursos |

## Requisitos Legales en Código

Las citaciones a la LFPDPPP no están solo en la documentación — se ejecutan en la infraestructura misma. Así es como el Artículo 35 aplica el bloqueo de región:

```hcl
variable "location" {
  description = "Región de Azure donde se creará la cuenta de almacenamiento."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP Art. 35 (DOF 20 marzo 2025): El almacenamiento debe desplegarse solo en mexicocentral o eastus2."
  }
}
```

Y la política OPA que detecta geo-replicación en CI antes de que cualquier PR pueda hacer merge:

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

## Arquitectura

```text
crossborder-iac/
├── modules/
│   ├── compliant-storage/        # Cuenta de almacenamiento — solo LRS, Art. 36
│   ├── compliant-keyvault/       # Key Vault — purge protection, ACLs de red, tenant-locked
│   ├── compliant-network/        # VNet + subnets — sin peering por diseño
│   └── observability-baseline/   # Log Analytics — logs región-local, Art. 35
├── environments/
│   ├── mx-central/               # Mexico Central — data_classification = "personal"
│   └── us-east2/                 # East US 2 — data_classification = "non-personal"
├── policies/
│   └── storage_residency.rego    # 4 reglas OPA que implementan Arts. 35-36
├── tests/
│   └── fixtures/                 # Plan JSON de Terraform para pruebas de políticas
├── scripts/
│   └── bootstrap-state-backend.sh  # Setup idempotente del state storage (West US 2)
├── docs/
│   └── adr/                      # Registros de Decisiones de Arquitectura
├── .github/
│   └── workflows/                # Checks de PR: terraform plan + OPA + Checkov
└── conftest.toml
```

## Módulos

**compliant-storage** — Cuenta de Azure Storage restringida a replicación LRS. La validación de variables rechaza GRS/ZRS/GZRS en tiempo de plan. Replicación cross-tenant deshabilitada. Implementa Art. 36.

**compliant-keyvault** — Azure Key Vault con purge protection habilitado, soft delete de 90 días, ACLs de red que niegan acceso público, y bloqueo a nivel de tenant. Los secretos nunca salen del boundary de tenant autorizado.

**compliant-network** — VNet y subnets con espacios de direcciones no superpuestos por región (México: 10.0.0.0/16, EE.UU.: 10.1.0.0/16). Sin recursos de peering por diseño — la conectividad de red cross-region está prohibida arquitecturalmente, no solo bloqueada por política.

**observability-baseline** — Log Analytics Workspace con configuración de diagnósticos que asegura que los logs de auditoría permanezcan en la misma región que los recursos que monitorean. Implementa la residencia de datos del Art. 35 para evidencia de cumplimiento.

## Reglas de Política OPA

Las cuatro reglas se ejecutan en cada PR vía Conftest contra la salida de terraform plan:

| Regla | Artículo LFPDPPP | Qué Detecta |
|---|---|---|
| Lista blanca de regiones | Art. 35 | Cuentas de almacenamiento fuera de mexicocentral o eastus2 |
| Solo replicación LRS | Art. 36 | Cualquier tipo de replicación diferente a LRS |
| Replicación cross-tenant deshabilitada | Art. 36 | Replicación cross-tenant habilitada |
| VNet peering prohibido | Art. 36 | Cualquier recurso azurerm_virtual_network_peering en el plan |

## Pipeline CI/CD

Cada pull request ejecuta:

1. terraform plan — Genera un plan JSON para el entorno objetivo
2. Conftest OPA check — Ejecuta todas las políticas Rego contra la salida del plan
3. Checkov análisis estático — Escanea el HCL buscando configuraciones de seguridad incorrectas

Branch protection en main requiere que todos los checks pasen. No se permiten pushes directos.

## Registros de Decisiones de Arquitectura

| ADR | Decisión | Justificación |
|---|---|---|
| [ADR-001](docs/adr/ADR-001-local-state-backend.md) | State backend local | Restricciones de autenticación en cuenta personal de Azure impiden backend remoto; el script de bootstrap provisiona state storage para migración futura |
| [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md) | Enforcement dual: OPA + Azure Policy | OPA detecta violaciones pre-deploy en CI; Azure Policy detecta drift post-deploy en runtime |
| [ADR-003](docs/adr/ADR-003-bootstrap-script-outside-terraform.md) | Script de bootstrap fuera de Terraform | El state backend no puede ser gestionado por el Terraform que depende de él — dependencia circular resuelta con script shell idempotente |
| [ADR-004](docs/adr/ADR-004-lfpdppp-2025-article-migration.md) | Migración de artículos LFPDPPP 2025 | La reescritura completa de la ley de México (DOF 20 marzo 2025) renumeró los artículos de residencia y transferencia; las citas de cumplimiento en todo el código y documentación se migraron para mantener precisión legal |

## Prerequisitos

- Terraform >= 1.5
- Azure CLI (az login con suscripción activa)
- Conftest (para checks de políticas OPA)
- Checkov (para análisis estático)

## Inicio Rápido

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

## Ejemplo de Aplicación de Políticas

Esta es la salida real de ejecutar Conftest contra los fixtures no conformes en `tests/fixtures/`: una cuenta de almacenamiento en la región incorrecta con replicación GRS y cross-tenant habilitada, la misma mala configuración pero anidada dentro de un módulo hijo, y un recurso de VNet peering prohibido:

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

Un exit code distinto de cero bloquea el pull request — este es el check que corre en `compliance-mx-central` y `compliance-us-east2` en cada PR.

## Qué Sigue

Esto es una implementación de referencia, no una plataforma terminada. Lo que falta:

- **Azure Policy como Capa 3 de enforcement** — detección de drift en runtime según [ADR-002](docs/adr/ADR-002-dual-enforcement-opa-azure-policy.md). Hoy es la única capa de defensa en profundidad que existe en el papel pero todavía no en Terraform.
- **Migración del state remoto a Azure Blob** — sustituir el backend local en cuanto haya un service principal disponible, según [ADR-001](docs/adr/ADR-001-local-state-backend.md) y [ADR-003](docs/adr/ADR-003-bootstrap-script-outside-terraform.md).
- **Private endpoints para Storage y Key Vault** — ambos recursos ya bloquean el acceso público; falta el private endpoint que permita el acceso legítimo sin reabrir esa puerta.
- **Más reglas OPA para otros tipos de recursos** — las cuatro reglas actuales cubren storage y networking; Key Vault y Log Analytics todavía no tienen drift de configuración verificado por política.
- **Mejoras al pipeline de CI** — agregar `terraform fmt -check`, `terraform validate` y `tflint` como checks rápidos antes del plan/OPA/Checkov.

## Autor

**Eduardo Ayala Siono** · Analista de Datos / Ingeniero de Datos

Más de 6 años asegurando la integridad de datos en producción a escala. Basado en Mexicali, en la frontera EE.UU.–México.

Construí este proyecto después de investigar las brechas operativas que enfrentan las empresas estadounidenses bajo la reforma LFPDPPP 2025 de México: multas de $3.86M USD, sanciones penales, y ningún patrón de infraestructura estandarizado para aplicarlas.

📍 Mexicali, MX · US Pacific · EN/ES C2

[linkedin.com/in/eduardosiono](https://linkedin.com/in/eduardosiono)

---

Licenciado bajo MIT. Esta es una implementación de referencia con fines de portafolio. Los requisitos de cumplimiento de la LFPDPPP (DOF 20 marzo 2025) deben ser validados con asesoría legal para despliegues en producción.