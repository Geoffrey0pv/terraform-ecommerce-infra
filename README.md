# Infraestructura de E-commerce con GKE y Terraform

## Propósito y Justificación

Esta infraestructura implementa una plataforma de e-commerce completa utilizando Google Kubernetes Engine (GKE) con Terraform como Infrastructure as Code. La arquitectura está diseñada para soportar múltiples ambientes (devops, staging, production) con alta disponibilidad, seguridad y escalabilidad.

### Justificación de la Arquitectura

**Por qué GKE**: Google Kubernetes Engine proporciona un servicio de Kubernetes completamente gestionado que elimina la complejidad de administrar el plano de control, permitiendo enfocarse en el desarrollo de aplicaciones.

**Por qué Terraform**: Infrastructure as Code permite versionar, reproducir y gestionar la infraestructura de manera consistente y automatizada, reduciendo errores humanos y facilitando la colaboración.

**Por qué Multi-Environment**: La separación en ambientes (devops, staging, production) permite un flujo de desarrollo seguro con validación progresiva antes de llegar a producción.

**Por qué Private Cluster**: Los nodos privados sin IPs públicas proporcionan mayor seguridad al eliminar la exposición directa a internet, requiriendo tráfico a través de NAT Gateway.

## Arquitectura de la Infraestructura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           GOOGLE CLOUD PLATFORM                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           VPC NETWORK                                   │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    SUBNET (10.x.0.0/20)                        │   │   │
│  │  │                                                                 │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              GKE CLUSTER                               │   │   │   │
│  │  │  │                                                         │   │   │   │
│  │  │  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │   │   │
│  │  │  │  │   NODE     │ │   NODE     │ │   NODE     │       │   │   │   │
│  │  │  │  │   POOL     │ │   POOL     │ │   POOL     │       │   │   │   │
│  │  │  │  │            │ │            │ │            │       │   │   │   │
│  │  │  │  │ ┌─────────┐│ │ ┌─────────┐│ │ ┌─────────┐│       │   │   │   │
│  │  │  │  │ │  PODS   ││ │ │  PODS   ││ │ │  PODS   ││       │   │   │   │
│  │  │  │  │ │         ││ │ │         ││ │ │         ││       │   │   │   │
│  │  │  │  │ └─────────┘│ │ └─────────┘│ │ └─────────┘│       │   │   │   │
│  │  │  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        NAT GATEWAY                                     │   │
│  │                    (Internet Access)                                   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      CLOUD ROUTER                                      │   │
│  │                    (Network Routing)                                   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Componentes de la Infraestructura

### 1. Módulo de Networking
- **VPC**: Red privada virtual que aísla los recursos
- **Subnet**: Subred con rangos secundarios para pods y servicios de Kubernetes
- **Firewall Rules**: Reglas de seguridad que controlan el tráfico de red
- **Cloud Router**: Gestiona el enrutamiento de red y proporciona conectividad
- **NAT Gateway**: Permite que los nodos privados accedan a internet de forma segura

### 2. Módulo de Cluster
- **GKE Cluster**: Cluster de Kubernetes completamente gestionado
- **Private Cluster**: Configuración de seguridad con nodos sin IPs públicas
- **Workload Identity**: Integración con IAM de GCP para autenticación segura
- **Network Policy**: Políticas de red para control de tráfico entre pods
- **Addons**: HTTP Load Balancing, HPA, Network Policy habilitados

### 3. Módulo de Node Pools
- **Node Pools Especializados**: Pools separados por función (database, elk, monitoring, security)
- **Auto Repair**: Reparación automática de nodos para alta disponibilidad
- **Labels**: Etiquetado para organización y selección de nodos
- **Shielded Instances**: Protección a nivel de VM con Secure Boot

### 4. Módulo de Namespaces
- **Namespaces**: Separación lógica de recursos por ambiente y función
- **RBAC**: Control de acceso basado en roles para seguridad granular
- **Resource Quotas**: Límites de recursos por namespace para control de costos

## Ambientes Configurados

### DevOps Environment
- **Región**: us-central1-a
- **Propósito**: Desarrollo, CI/CD y herramientas de DevOps
- **Node Pools**: security, elk, database, monitoring
- **Namespaces**: security, elk, database, monitoring, tools, ingress-nginx

### Staging Environment
- **Región**: us-central1-b
- **Propósito**: Pruebas y validación antes de producción
- **Node Pools**: core, backend, database, monitoring
- **Namespaces**: core, backend, database, monitoring

### Production Environment
- **Región**: us-central1-c
- **Propósito**: Ambiente de producción con alta disponibilidad
- **Node Pools**: core (2), backend (4), database, monitoring
- **Namespaces**: core, backend, database, monitoring

## Configuración de Red

### VPC y Subnets
Cada ambiente tiene su propia VPC con la siguiente configuración:

| Ambiente | Subnet CIDR | Pods CIDR | Services CIDR |
|----------|-------------|-----------|---------------|
| DevOps   | 10.20.0.0/20 | 10.21.0.0/16 | 10.22.0.0/20 |
| Staging  | 10.10.0.0/20 | 10.11.0.0/16 | 10.12.0.0/20 |
| Production | 10.100.0.0/20 | 10.101.0.0/16 | 10.102.0.0/20 |

### Características de Red
- **Private Cluster**: Nodos privados para mayor seguridad
- **NAT Gateway**: Acceso a internet para nodos privados
- **Secondary IP Ranges**: Separación de pods y servicios
- **Firewall Rules**: Comunicación interna y SSH controlado

## Node Pools y Especialización

### Configuración de Node Pools

| Node Pool | Propósito | Configuración | Uso |
|-----------|-----------|---------------|-----|
| **database-pool** | Bases de datos | n1-standard-1, 20GB SSD | PostgreSQL, MySQL, Redis |
| **elk-pool** | Logging y Analytics | n1-standard-1, 20GB SSD | Elasticsearch, Logstash, Kibana |
| **monitoring-pool** | Observabilidad | n1-standard-1, 20GB SSD | Prometheus, Grafana, AlertManager |
| **security-pool** | Seguridad | n1-standard-1, 20GB SSD | Falco, OPA, Security scanners |
| **core-pool** | Aplicaciones core | n1-standard-1, 20GB SSD | Frontend, API Gateway |
| **backend-pool** | Microservicios | n1-standard-1, 20GB SSD | APIs, Business Logic |

## Decisiones Arquitectónicas Justificadas

### 1. Private Cluster
**Decisión**: Nodos privados sin IPs públicas
**Justificación**: Mayor seguridad, control de acceso, cumplimiento de políticas de seguridad corporativas

### 2. Node Pools Especializados
**Decisión**: Pools separados por función
**Justificación**: Optimización de recursos, aislamiento de workloads, escalabilidad independiente

### 3. Multi-Environment
**Decisión**: Ambientes separados (devops, staging, prod)
**Justificación**: Aislamiento de recursos, testing seguro, pipeline de deployment

### 4. Workload Identity
**Decisión**: Integración con IAM de GCP
**Justificación**: Seguridad mejorada, gestión centralizada de permisos, eliminación de service accounts

### 5. Network Policies
**Decisión**: Control de tráfico entre pods
**Justificación**: Micro-segmentación de red, cumplimiento de seguridad, aislamiento de servicios

## Monitoreo y Observabilidad

### Stack de Monitoreo
- **Prometheus**: Métricas y alertas del sistema
- **Grafana**: Dashboards y visualización de métricas
- **AlertManager**: Gestión y notificación de alertas
- **ELK Stack**: Logging centralizado
  - **Elasticsearch**: Almacenamiento de logs
  - **Logstash**: Procesamiento de logs
  - **Kibana**: Visualización de logs

## Seguridad

### Medidas de Seguridad Implementadas
- **Private Cluster**: Nodos sin IPs públicas
- **Network Policies**: Control de tráfico entre pods
- **Workload Identity**: Autenticación segura con GCP
- **Shielded Instances**: Protección a nivel de VM
- **RBAC**: Control de acceso granular
- **Resource Quotas**: Límites de recursos por namespace

## Escalabilidad y Alta Disponibilidad

### Estrategias de Escalabilidad
- **Horizontal Pod Autoscaler (HPA)**: Escalado automático de pods
- **Cluster Autoscaler**: Escalado automático de nodos
- **Load Balancing**: Distribución de carga
- **Multi-Zone**: Distribución en múltiples zonas

### Alta Disponibilidad
- **Multi-Zone Deployment**: Distribución en zonas
- **Health Checks**: Verificación de salud
- **Rolling Updates**: Actualizaciones sin downtime
- **Auto Repair**: Reparación automática de nodos

## Scripts de Automatización

### Scripts Disponibles

#### 1. Script de Monitoreo (`scripts/monitor-all.sh`)
Verifica el estado completo de la infraestructura:
- Estado del cluster GKE
- Estado de los nodos
- Estado de los pods por namespace
- Estado de los servicios
- Métricas de recursos
- Conectividad de red

#### 2. Script de Gestión de Infraestructura (`scripts/manage-infra.sh`)
Gestiona la infraestructura de Terraform:
- Aplicar cambios
- Destruir infraestructura
- Planificar cambios

#### 3. Script de Gestión de Recursos (`scripts/manage-resources.sh`)
Gestiona recursos de Kubernetes:
- Crear recursos
- Eliminar recursos
- Listar recursos

#### 4. Script de Aplicación de Terraform (`scripts/apply_terraform.sh`)
Aplica cambios de Terraform por ambiente:
- DevOps
- Staging
- Production

#### 5. Script de Destrucción (`scripts/destroy_terraform.sh`)
Destruye la infraestructura de forma controlada

#### 6. Script de Pausa de Recursos (`scripts/pause-resources.sh`)
Pausa recursos para ahorrar costos en desarrollo

## Getting Started

### Prerrequisitos
- Terraform >= 1.0
- Google Cloud SDK
- kubectl
- Acceso a proyecto de GCP

### Desplegar Infraestructura

1. **Configurar autenticación**:
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

2. **Inicializar Terraform**:
```bash
terraform init
```

3. **Seleccionar ambiente**:
```bash
# Para DevOps
terraform workspace select devops

# Para Staging
terraform workspace select staging

# Para Production
terraform workspace select production
```

4. **Aplicar infraestructura**:
```bash
# Usando script
./scripts/apply_terraform.sh

# O manualmente
terraform apply -var-file="terraform.devops.tfvars"
```

5. **Conectar al cluster**:
```bash
gcloud container clusters get-credentials ecommerce-devops-cluster --region us-central1 --project YOUR_PROJECT_ID
```

6. **Verificar estado**:
```bash
./scripts/monitor-all.sh
```

### Usar Scripts de Automatización

#### Monitoreo
```bash
# Verificar estado completo
./scripts/monitor-all.sh
```

#### Gestión de Infraestructura
```bash
# Aplicar cambios
./scripts/manage-infra.sh apply

# Destruir infraestructura
./scripts/manage-infra.sh destroy

# Planificar cambios
./scripts/manage-infra.sh plan
```

#### Gestión de Recursos
```bash
# Crear recursos
./scripts/manage-resources.sh create

# Listar recursos
./scripts/manage-resources.sh list

# Eliminar recursos
./scripts/manage-resources.sh delete
```

#### Pausar Recursos
```bash
# Pausar para ahorrar costos
./scripts/pause-resources.sh

# Reanudar recursos
./scripts/resume-resources.sh
```

## Próximos Pasos Recomendados

### Fase 1: Completar Stack Básico
1. Implementar Service Mesh (Istio)
2. Agregar API Gateway
3. Configurar Message Queue
4. Implementar Cache Layer

### Fase 2: Mejoras de Seguridad
1. Implementar Pod Security Standards
2. Configurar Network Segmentation
3. Agregar Vulnerability Scanning
4. Implementar Secrets Management

### Fase 3: Optimización y Escalabilidad
1. Configurar Multi-Region
2. Implementar Disaster Recovery
3. Agregar Chaos Engineering
4. Optimizar Costos

---

**Última actualización**: Enero 2025
**Versión**: 1.0
**Mantenido por**: Equipo de DevOps