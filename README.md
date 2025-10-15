# Infraestructura de E-commerce con GKE y Terraform

## Resumen Ejecutivo

Esta infraestructura implementa una plataforma de e-commerce completa utilizando Google Kubernetes Engine (GKE) con Terraform como Infrastructure as Code. La arquitectura está diseñada para soportar múltiples ambientes (devops, staging, production) con alta disponibilidad, seguridad y escalabilidad.

## Arquitectura General

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

## Ambientes Configurados

### 1. **DevOps Environment**
- **Región**: us-central1-a
- **Propósito**: Desarrollo, CI/CD y herramientas de DevOps
- **Node Pools**: security, elk, database, monitoring
- **Namespaces**: security, elk, database, monitoring, tools, ingress-nginx

### 2. **Staging Environment**
- **Región**: us-central1-b
- **Propósito**: Pruebas y validación antes de producción
- **Node Pools**: core, backend, database, monitoring
- **Namespaces**: core, backend, database, monitoring

### 3. **Production Environment**
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

## Namespaces y su Propósito

### Namespaces por Ambiente

#### **DevOps Environment**
- **security**: Herramientas de seguridad (Falco, OPA, etc.)
- **elk**: Stack ELK (Elasticsearch, Logstash, Kibana)
- **database**: Bases de datos de desarrollo
- **monitoring**: Prometheus, Grafana, AlertManager
- **tools**: Jenkins, ArgoCD, herramientas de CI/CD
- **ingress-nginx**: Controlador de ingress para routing

#### **Staging Environment**
- **core**: Aplicaciones core del e-commerce
- **backend**: Servicios backend (APIs, microservicios)
- **database**: Bases de datos de staging
- **monitoring**: Monitoreo y observabilidad

#### **Production Environment**
- **core**: Aplicaciones core de producción
- **backend**: Servicios backend de producción
- **database**: Bases de datos de producción
- **monitoring**: Monitoreo de producción

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

### Características de Seguridad
- **Shielded Instances**: Secure Boot e Integrity Monitoring
- **Workload Identity**: Integración con IAM de GCP
- **Private Nodes**: Sin IPs públicas
- **Network Policies**: Control de tráfico entre pods

## Componentes de la Infraestructura

### 1. **Módulo de Networking**
- **VPC**: Red privada virtual
- **Subnet**: Subred con rangos secundarios
- **Firewall Rules**: Reglas de seguridad
- **Cloud Router**: Enrutamiento de red
- **NAT Gateway**: Acceso a internet

### 2. **Módulo de Cluster**
- **GKE Cluster**: Cluster de Kubernetes
- **Private Cluster**: Configuración de seguridad
- **Workload Identity**: Autenticación con GCP
- **Network Policy**: Políticas de red
- **Addons**: HTTP Load Balancing, HPA, Network Policy

### 3. **Módulo de Node Pools**
- **Node Pools Especializados**: Por función y ambiente
- **Auto Repair**: Reparación automática de nodos
- **Labels**: Etiquetado para organización
- **Taints/Tolerations**: Aislamiento de workloads

### 4. **Módulo de Namespaces**
- **Namespaces**: Separación lógica de recursos
- **RBAC**: Control de acceso basado en roles
- **Resource Quotas**: Límites de recursos

## Monitoreo y Observabilidad

### Stack de Monitoreo
- **Prometheus**: Métricas y alertas
- **Grafana**: Dashboards y visualización
- **AlertManager**: Gestión de alertas
- **ELK Stack**: Logging centralizado
  - **Elasticsearch**: Almacenamiento de logs
  - **Logstash**: Procesamiento de logs
  - **Kibana**: Visualización de logs

### Métricas Clave
- **Cluster Health**: Estado del cluster
- **Node Metrics**: CPU, memoria, disco
- **Pod Metrics**: Recursos por pod
- **Application Metrics**: Métricas de aplicación
- **Network Metrics**: Tráfico de red

## Seguridad

### Medidas de Seguridad Implementadas
- **Private Cluster**: Nodos sin IPs públicas
- **Network Policies**: Control de tráfico entre pods
- **Workload Identity**: Autenticación segura con GCP
- **Shielded Instances**: Protección a nivel de VM
- **RBAC**: Control de acceso granular
- **Resource Quotas**: Límites de recursos por namespace

### Herramientas de Seguridad
- **Falco**: Detección de amenazas en tiempo real
- **OPA (Open Policy Agent)**: Políticas de seguridad
- **Network Security**: Firewall rules y network policies
- **Image Security**: Escaneo de vulnerabilidades

## CI/CD y DevOps

### Herramientas de DevOps
- **Jenkins**: Automatización de CI/CD
- **ArgoCD**: GitOps para deployment
- **Helm**: Gestión de paquetes de Kubernetes
- **Terraform**: Infrastructure as Code

### Flujo de CI/CD
1. **Desarrollo**: Código en repositorio Git
2. **Build**: Jenkins construye y testea
3. **Package**: Creación de imágenes Docker
4. **Deploy**: ArgoCD despliega en ambientes
5. **Monitor**: Prometheus y Grafana monitorean

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
- **Backup Strategy**: Estrategia de respaldos

## Análisis de la Infraestructura

### Fortalezas
- **Arquitectura Modular**: Separación clara de responsabilidades
- **Multi-Environment**: Soporte para múltiples ambientes
- **Seguridad**: Implementación de mejores prácticas
- **Observabilidad**: Stack completo de monitoreo
- **Escalabilidad**: Diseño para crecimiento
- **Infrastructure as Code**: Gestión versionada

### Áreas de Mejora

#### Componentes Faltantes
1. **Service Mesh**: Istio o Linkerd para comunicación entre servicios
2. **API Gateway**: Kong, Ambassador o Istio Gateway
3. **Message Queue**: RabbitMQ, Apache Kafka o Google Pub/Sub
4. **Cache Layer**: Redis Cluster para caching
5. **CDN**: Google Cloud CDN para contenido estático
6. **Backup Solution**: Velero para backup de Kubernetes
7. **Secrets Management**: HashiCorp Vault o Google Secret Manager
8. **Image Registry**: Google Container Registry o Artifact Registry

#### Mejoras Arquitectónicas
1. **Multi-Region**: Distribución en múltiples regiones
2. **Disaster Recovery**: Plan de recuperación ante desastres
3. **Blue-Green Deployment**: Estrategia de deployment
4. **Canary Releases**: Implementación gradual
5. **Chaos Engineering**: Pruebas de resistencia

#### Seguridad Adicional
1. **Pod Security Standards**: Políticas de seguridad de pods
2. **Network Segmentation**: Micro-segmentación de red
3. **Encryption**: Cifrado en tránsito y en reposo
4. **Compliance**: Cumplimiento de estándares (SOC2, PCI-DSS)
5. **Vulnerability Scanning**: Escaneo continuo de vulnerabilidades

## Decisiones Arquitectónicas Justificadas

### 1. **Private Cluster**
**Decisión**: Nodos privados sin IPs públicas
**Justificación**: Mayor seguridad, control de acceso, cumplimiento de políticas

### 2. **Node Pools Especializados**
**Decisión**: Pools separados por función
**Justificación**: Optimización de recursos, aislamiento, escalabilidad independiente

### 3. **Multi-Environment**
**Decisión**: Ambientes separados (devops, staging, prod)
**Justificación**: Aislamiento, testing, deployment pipeline

### 4. **Workload Identity**
**Decisión**: Integración con IAM de GCP
**Justificación**: Seguridad, gestión de permisos, eliminación de service accounts

### 5. **Network Policies**
**Decisión**: Control de tráfico entre pods
**Justificación**: Seguridad, micro-segmentación, compliance

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

## Scripts de Automatización

### Scripts Disponibles

#### 1. Script de Monitoreo (`scripts/monitor-all.sh`)
```bash
# Ejecutar monitoreo completo
./scripts/monitor-all.sh

# El script verifica:
# - Estado del cluster GKE
# - Estado de los nodos
# - Estado de los pods por namespace
# - Estado de los servicios
# - Métricas de recursos
# - Conectividad de red
```

#### 2. Script de Gestión de Infraestructura (`scripts/manage-infra.sh`)
```bash
# Aplicar infraestructura
./scripts/manage-infra.sh apply

# Destruir infraestructura
./scripts/manage-infra.sh destroy

# Planificar cambios
./scripts/manage-infra.sh plan
```

#### 3. Script de Gestión de Recursos (`scripts/manage-resources.sh`)
```bash
# Crear recursos de Kubernetes
./scripts/manage-resources.sh create

# Eliminar recursos de Kubernetes
./scripts/manage-resources.sh delete

# Listar recursos
./scripts/manage-resources.sh list
```

#### 4. Script de Aplicación de Terraform (`scripts/apply_terraform.sh`)
```bash
# Aplicar cambios de Terraform
./scripts/apply_terraform.sh

# Especificar ambiente
./scripts/apply_terraform.sh devops
./scripts/apply_terraform.sh staging
./scripts/apply_terraform.sh production
```

#### 5. Script de Destrucción (`scripts/destroy_terraform.sh`)
```bash
# Destruir infraestructura
./scripts/destroy_terraform.sh

# Especificar ambiente
./scripts/destroy_terraform.sh devops
```

### Script para Pausar Recursos (Nuevo)
```bash
# Crear script para pausar recursos y ahorrar costos
./scripts/pause-resources.sh

# Reanudar recursos
./scripts/resume-resources.sh
```

## NAT Gateway y Cloud Router - Explicación Técnica

### NAT Gateway
**Propósito**: Permite que los nodos privados de GKE accedan a internet de forma segura.

**Cómo funciona**:
- Los nodos del cluster no tienen IPs públicas (private cluster)
- El NAT Gateway actúa como intermediario entre los nodos privados e internet
- Traduce las IPs privadas a una IP pública para salida a internet
- Permite descargar imágenes de contenedores, actualizaciones, etc.

**Beneficios**:
- **Seguridad**: Los nodos no están expuestos directamente a internet
- **Control**: Todo el tráfico saliente pasa por el NAT Gateway
- **Logging**: Se pueden registrar las conexiones salientes
- **Cumplimiento**: Cumple con políticas de seguridad corporativas

### Cloud Router
**Propósito**: Gestiona el enrutamiento de red y proporciona conectividad.

**Funciones**:
- **Enrutamiento**: Determina cómo se envían los paquetes entre redes
- **NAT Gateway**: Proporciona la funcionalidad de NAT
- **BGP**: Protocolo de enrutamiento para conectividad híbrida
- **VPN**: Conectividad con redes on-premises

**Configuración en tu infraestructura**:
```hcl
# Cloud Router para NAT Gateway
resource "google_compute_router" "nat_router" {
  name    = "${var.network_name}-nat-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# NAT Gateway para acceso a internet
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.network_name}-nat-gateway"
  router                            = google_compute_router.nat_router.name
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

## KEDA - Kubernetes Event-Driven Autoscaling

### ¿Qué es KEDA?
KEDA (Kubernetes Event-Driven Autoscaling) es un componente que permite escalar aplicaciones basándose en eventos externos, no solo en métricas de CPU/memoria.

### ¿Deberías implementar KEDA?

**SÍ, te recomiendo implementar KEDA porque**:

1. **Autoscaling Inteligente**: Escala basándose en colas de mensajes, métricas de base de datos, etc.
2. **Pruebas de Rendimiento**: Perfecto para simular carga real en microservicios
3. **Eficiencia de Recursos**: Escala a 0 cuando no hay trabajo
4. **Múltiples Escaladores**: Soporta 50+ tipos de escaladores (Kafka, Redis, PostgreSQL, etc.)

### Casos de Uso para tu E-commerce
- **Colas de Pedidos**: Escalar procesadores de pedidos basándose en cola de mensajes
- **Procesamiento de Pagos**: Escalar basándose en métricas de transacciones
- **Análisis de Logs**: Escalar procesadores de logs basándose en volumen
- **Pruebas de Carga**: Simular carga real para testing

### Implementación Recomendada
```yaml
# Ejemplo de escalador para cola de pedidos
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor-scaler
spec:
  scaleTargetRef:
    name: order-processor
  minReplicaCount: 0
  maxReplicaCount: 10
  triggers:
  - type: rabbitmq
    metadata:
      queueName: orders
      queueLength: '5'
```

## Comandos Útiles

### Conexión al Cluster
```bash
gcloud container clusters get-credentials ecommerce-devops-cluster --region us-central1 --project ecommerce-backend-1760307199
```

### Aplicar Terraform
```bash
# DevOps
terraform workspace select devops
terraform apply -var-file="terraform.devops.tfvars"

# Staging
terraform workspace select staging
terraform apply -var-file="terraform.staging.tfvars"

# Production
terraform workspace select production
terraform apply -var-file="terraform.prod.tfvars"
```

### Monitoreo
```bash
# Ver pods por namespace
kubectl get pods --all-namespaces

# Ver servicios
kubectl get services --all-namespaces

# Ver nodos
kubectl get nodes
```

### Verificar Estado de la Arquitectura
```bash
# Estado del cluster
kubectl cluster-info

# Estado de los nodos
kubectl get nodes -o wide

# Estado de los namespaces
kubectl get namespaces

# Estado de los pods por namespace
kubectl get pods --all-namespaces -o wide

# Estado de los servicios
kubectl get services --all-namespaces

# Estado de los ingress
kubectl get ingress --all-namespaces

# Verificar recursos del cluster
kubectl top nodes
kubectl top pods --all-namespaces
```

## Contacto y Soporte

Para preguntas sobre la infraestructura o mejoras, contactar al equipo de DevOps.

---

**Última actualización**: Enero 2025
**Versión**: 1.0
**Mantenido por**: Equipo de DevOps