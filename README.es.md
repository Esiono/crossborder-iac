# CrossBorder-IaC

🇺🇸 [Read this in English](README.md)

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![OPA](https://img.shields.io/badge/OPA-Conftest-4E5A65?logo=openpolicyagent&logoColor=white)](https://www.conftest.dev/)
[![Azure](https://img.shields.io/badge/Azure-Mexico_Central_|_East_US_2-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Checkov](https://img.shields.io/badge/Checkov-Análisis_Estático-5C4EE5)](https://www.checkov.io/)
[![CI](https://github.com/Esiono/crossborder-iac/actions/workflows/terraform-compliance.yml/badge.svg)](https://github.com/Esiono/crossborder-iac/actions)
[![License: MIT](https://img.shields.io/badge/Licencia-MIT-green.svg)](LICENSE)

> **Plataforma de policy-as-code que implementa los requisitos de residencia de datos de la LFPDPPP de México en despliegues Azure entre EE.UU. y México.** Tres capas de enforcement — variables de IaC, gates de políticas en CI, y Azure Policy en runtime — aseguran que los datos personales nunca abandonen su región autorizada.

---

## El Problema

México reformó su ley de protección de datos en marzo de 2025. La nueva LFPDPPP reemplazó el marco de 2010, introdujo sanciones penales de hasta 5 años de prisión por violaciones de datos que involucren datos personales, y elevó las multas a ~$3.86M USD — duplicadas cuando se involucran datos sensibles. La aplicación de la ley pasó del disuelto INAI a un nuevo organismo del poder ejecutivo, y se están creando tribunales federales especializados en protección de datos.

Esto importa ahora mismo por lo que está ocurriendo en la frontera:

- Más de 700,000 profesionales de tecnología trabajan en el sector IT de México, la segunda fuerza laboral más grande de América Latina. Las empresas estadounidenses están haciendo nearshoring a un ritmo récord — México atrajo $40.9B USD en IED en los primeros nueve meses de 2025, superando el récord anual previo.
- Azure Mexico Central se lanzó en mayo de 2024 — la primera región de nube hiperescala de Microsoft en América Latina de habla hispana, construida explícitamente para atender la demanda de nearshoring y los requisitos de residencia de datos en el país. AWS y Google Cloud siguieron con sus propias regiones en México.
- Más de 1,100 startups fintech operan en México, convirtiéndolo en el segundo mercado fintech más grande de América Latina. Flujos de pagos transfronterizos, plataformas de remesas y banca digital procesan datos personales a través del corredor EE.UU.–México diariamente.
- La revisión conjunta del T-MEC programada para julio de 2026 se espera que aborde la gobernanza de datos transfronterizos, la cooperación en ciberseguridad y el cumplimiento relacionado con IA — endureciendo los requisitos aún más.

El resultado: toda empresa estadounidense con operaciones nearshore en México ahora maneja datos personales sujetos a la LFPDPPP, frecuentemente a través de regiones Azure en ambos lados de la frontera. Una cuenta de almacenamiento mal configurada con geo-replicación habilitada, un peering de VNet accidental, o un toggle de replicación cross-tenant pueden crear una violación de cumplimiento con consecuencias legales reales.

Las revisiones manuales de cumplimiento no escalan. Este proyecto codifica esos requisitos legales directamente en la infraestructura.

## Cómo Funciona

Tres capas de enforcement detectan violaciones en diferentes etapas, asegurando que nada llegue a producción sin verificar:

| Control | Capa de Enforcement | Mecanismo |
|---|---|---|
| Residencia de datos (Art. 36) | IaC | Validación de variables Terraform — solo mexicocentral y eastus2 permitidos |
| Prohibición de geo-replicación (Art. 37) | IaC + CI | Cuentas de almacenamiento forzadas a LRS + regla OPA rechaza cualquier otra |
| Replicación cross-tenant (Art. 37) | IaC + CI | Deshabilitada a nivel de recurso + regla OPA valida la salida del plan |
| Prohibición de VNet peering (Art. 37) | CI | Regla OPA bloquea recursos azurerm_virtual_network_peering por completo |
| Detección de drift en runtime | Runtime | Asignaciones de Azure Policy por entorno |
| Residencia de logs de auditoría (Art. 36) | IaC | Log Analytics Workspace y configuración de diagnósticos co-ubicados con los recursos |

## Requisitos Legales en Código

Las citaciones a la LFPDPPP no están solo en la documentación — se ejecutan en la infraestructura misma. Así es como el Artículo 36 aplica el bloqueo de región:

```hcl
variable "location" {
  description = "Región de Azure donde se creará la cuenta de almacenamiento."
  type        = string

  validation {
    condition     = contains(["mexicocentral", "eastus2"], var.location)
    error_message = "LFPDPPP Art. 36: El almacenamiento debe desplegarse solo en mexicocentral o eastus2."
  }
}
```

Y la política OPA que detecta geo-replicación en CI antes de que cualquier PR pueda hacer merge:

```rego
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    replication := resource.values.account_replication_type
    not allowed_replication_types[replication]
    msg := sprintf(
        "Violación Art. 37 LFPDPPP: La cuenta de almacenamiento '%s' usa tipo de replicación '%s'. Solo se permite LRS.",
        [resource.name, replication]
    )
}
```

## Arquitectura

crossborder-iac/
├── modules/
│   ├── compliant-storage/        # Cuenta de almacenamiento — solo LRS, Art. 37
│   ├── compliant-keyvault/       # Key Vault — purge protection, ACLs de red, tenant-locked
│   ├── compliant-network/        # VNet + subnets — sin peering por diseño
│   └── observability-baseline/   # Log Analytics — logs region-local, Art. 36
├── environments/
│   ├── mx-central/               # Mexico Central — data_classification = "personal"
│   └── us-east2/                 # East US 2 — data_classification = "non-personal"
├── policies/
│   └── storage_residency.rego    # 4 reglas OPA que implementan Art. 36 + Art. 37
├── tests/
│   └── fixtures/                 # Plan JSON de Terraform para pruebas de políticas
├── scripts/
│   └── bootstrap-state-backend.sh  # Setup idempotente del state storage (West US 2)
├── docs/
│   └── adr/                      # Registros de Decisiones de Arquitectura
├── .github/
│   └── workflows/                # Checks de PR: terraform plan + OPA + Checkov
└── conftest.toml

## Módulos

**compliant-storage** — Cuenta de Azure Storage restringida a replicación LRS. La validación de variables rechaza GRS/ZRS/GZRS en tiempo de plan. Replicación cross-tenant deshabilitada. Implementa Art. 37.

**compliant-keyvault** — Azure Key Vault con purge protection habilitado, soft delete de 90 días, ACLs de red que niegan acceso público, y bloqueo a nivel de tenant. Los secretos nunca salen del boundary de tenant autorizado.

**compliant-network** — VNet y subnets con espacios de direcciones no superpuestos por región (México: 10.0.0.0/16, EE.UU.: 10.1.0.0/16). Sin recursos de peering por diseño — la conectividad de red cross-region está prohibida arquitecturalmente, no solo bloqueada por política.

**observability-baseline** — Log Analytics Workspace con configuración de diagnósticos que asegura que los logs de auditoría permanezcan en la misma región que los recursos que monitorean. Implementa la residencia de datos del Art. 36 para evidencia de cumplimiento.

## Reglas de Política OPA

Las cuatro reglas se ejecutan en cada PR vía Conftest contra la salida de terraform plan:

| Regla | Artículo LFPDPPP | Qué Detecta |
|---|---|---|
| Lista blanca de regiones | Art. 36 | Cuentas de almacenamiento fuera de mexicocentral o eastus2 |
| Solo replicación LRS | Art. 37 | Cualquier tipo de replicación diferente a LRS |
| Replicación cross-tenant deshabilitada | Art. 37 | Replicación cross-tenant habilitada |
| VNet peering prohibido | Art. 37 | Cualquier recurso azurerm_virtual_network_peering en el plan |

## Pipeline CI/CD

Cada pull request ejecuta:

1. terraform plan — Genera un plan JSON para el entorno objetivo
2. Conftest OPA check — Ejecuta todas las políticas Rego contra la salida del plan
3. Checkov análisis estático — Escanea el HCL buscando configuraciones de seguridad incorrectas

Branch protection en main requiere que todos los checks pasen. No se permiten pushes directos.

## Registros de Decisiones de Arquitectura

| ADR | Decisión | Justificación |
|---|---|---|
| ADR-001 | State backend local | Restricciones de autenticación en cuenta personal de Azure impiden backend remoto; el script de bootstrap provisiona state storage para migración futura |
| ADR-002 | Enforcement dual: OPA + Azure Policy | OPA detecta violaciones pre-deploy en CI; Azure Policy detecta drift post-deploy en runtime |
| ADR-003 | Script de bootstrap fuera de Terraform | El state backend no puede ser gestionado por el Terraform que depende de él — dependencia circular resuelta con script shell idempotente |

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
conftest test plan.json -p ../../policies/
```

## Autor

**Eduardo Ayala Siono**

Construí esto porque el problema está en mi patio trasero. Estoy basado en Mexicali — una ciudad fronteriza donde empresas estadounidenses han hecho nearshoring de operaciones por décadas, y donde la brecha entre "cumplimos con la ley mexicana de datos" y lo que la infraestructura realmente aplica es algo que veo ocurrir en la práctica. Seis años de trabajo en calidad de datos me enseñaron que las brechas de cumplimiento no vienen de la mala intención — vienen de la mala configuración, los procesos manuales, y la infraestructura que nadie auditó.

Cuando México reescribió la LFPDPPP en 2025 con sanciones penales y multas de $3.86M USD, y Azure lanzó Mexico Central el año anterior específicamente para residencia de datos, vi una necesidad clara: alguien tiene que construir los patrones de infraestructura que apliquen estas reglas por defecto, no por documento de política.

Mexicali, México · Zona horaria US Pacific · Bilingüe EN/ES (C2)

linkedin.com/in/eduardosiono

---

Licenciado bajo MIT. Esta es una implementación de referencia con fines de portafolio. Los requisitos de cumplimiento de la LFPDPPP deben ser validados con asesoría legal para despliegues en producción.