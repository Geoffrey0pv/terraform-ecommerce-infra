# E-commerce Infrastructure with Terraform and GKE

Este proyecto implementa una infraestructura completa para Kubernetes en Google Cloud Platform utilizando Terraform, con una arquitectura modular y soporte para múltiples entornos (devops, staging, production).

## Estructura del Proyecto

```
taller2/
├── README.md
├── main.tf                     # Configuración principal de Terraform
├── variables.tf                # Variables de configuración
├── output.tf                   # Outputs de Terraform
├── provider.tf                 # Configuración de providers
├── terraform.devops.tfvars     # Variables para entorno devops
├── terraform.staging.tfvars    # Variables para entorno staging
├── terraform.prod.tfvars       # Variables para entorno production
├── terraform-sa-key.json       # Service Account key (no versionar)
├── .terraform.lock.hcl         # Lock file de Terraform
├── manage-resources.sh         # Script de gestión de recursos
├── modules/                    # Módulos reutilizables
│   ├── networking/             # Red VPC y subnets
│   ├── cluster/                # Cluster GKE
│   ├── node_pools/             # Pools de nodos
│   └── namespaces/             # Namespaces de Kubernetes
├── environments/               # Archivos de configuración por entorno
│   ├── devops/
│   │   ├── .env                # Variables de entorno devops
│   │   └── devops-sa-key.json  # Service Account devops
│   ├── staging/
│   │   ├── .env                # Variables de entorno staging
│   │   └── staging-sa-key.json # Service Account staging
│   └── prod/
│       ├── .env                # Variables de entorno production
│       └── prod-sa-key.json    # Service Account production
├── scripts/                    # Scripts de utilidad
├── ansible/                    # Configuración de automatización
└── helm/                       # Charts de Helm para aplicaciones
```

## Justificación del Enfoque Arquitectónico

### Decisiones de Diseño y Beneficios

#### 1. Arquitectura Modular
**Justificación**: La separación en módulos independientes (networking, cluster, node_pools, namespaces) permite:
- **Reutilización**: Los mismos módulos pueden ser utilizados en diferentes entornos sin duplicación de código
- **Mantenimiento**: Cambios en un módulo no afectan otros componentes, reduciendo el riesgo de errores
- **Testing**: Cada módulo puede ser probado independientemente
- **Escalabilidad**: Nuevos módulos pueden ser agregados sin modificar la estructura existente

#### 2. Configuración Multi-Entorno
**Justificación**: El uso de archivos `.tfvars` separados por entorno proporciona:
- **Aislamiento**: Cada entorno tiene configuraciones completamente independientes
- **Seguridad**: Credenciales y configuraciones sensibles están separadas por entorno
- **Flexibilidad**: Diferentes configuraciones de red, tamaños de nodos, y recursos por entorno
- **Versionado**: Cada archivo puede ser versionado y auditado independientemente

#### 3. Segregación de CIDR por Entorno
**Justificación**: Rangos IP diferentes (devops: 10.20.x.x, staging: 10.10.x.x, prod: 10.100.x.x) garantizan:
- **Aislamiento de Red**: Previene conflictos de IP entre entornos
- **Seguridad**: Facilita la implementación de reglas de firewall específicas
- **Troubleshooting**: Identificación rápida del entorno por rango IP
- **Peering**: Permite conectividad selectiva entre entornos cuando sea necesario

## Arquitectura

### Componentes de Infraestructura

Esta infraestructura implementa un diseño multi-entorno y modular que soporta entornos DevOps, Staging y Production con recursos y configuraciones dedicadas.

#### Infraestructura Core
- **Redes VPC**: Redes privadas virtuales dedicadas con subredes personalizadas para aislamiento de red
- **Clusters GKE Modulares**: Clusters de Kubernetes específicos por entorno con configuraciones optimizadas
- **Pools de Nodos Multi-Zona**: Pools de nodos configurables con autoescalado y taints específicos de workload
- **Service Accounts**: Service accounts dedicadas con permisos de menor privilegio
- **Servicios API**: Habilitación automática de APIs de Google Cloud requeridas
- **Namespaces de Kubernetes**: Estructura organizada de namespaces para aislamiento de aplicaciones

#### Arquitectura de Red
- **Clusters Privados**: Clusters GKE privados listos para producción con endpoints privados configurables
- **Rangos IP Secundarios**: Asignación IP optimizada para pods y servicios
- **Soporte Multi-Regional**: Regiones y zonas configurables para alta disponibilidad
- **Integración de Firewall**: Reglas de firewall automáticas administradas por GKE

#### Características de Seguridad
- **Workload Identity**: Autenticación segura de pod-a-servicio GCP
- **Service Accounts Dedicadas**: Identidades específicas con permisos mínimos requeridos
- **Redes Privadas**: Aislamiento de red con acceso controlado a internet

## Configuración Multi-Entorno

### Entornos Soportados

| Entorno | CIDR Range | Propósito | Node Pool |
|---------|------------|-----------|-----------|
| **devops** | 10.20.0.0/20 | Desarrollo y testing | n1-standard-1 (1-3 nodos) |
| **staging** | 10.10.0.0/20 | Pre-producción | n1-standard-1 (1-3 nodos) |
| **prod** | 10.100.0.0/20 | Producción | n1-standard-1 (2-5 nodos) |

### Variables por Entorno

Cada entorno tiene su propio archivo `terraform.<env>.tfvars` con configuraciones específicas:

```hcl
# terraform.devops.tfvars
project_id = "mi-proyecto-devops"
region = "us-central1"
node_locations = ["us-central1-a", "us-central1-b"]
repo_name = "taller2-devops"
vpc_cidr = "10.20.0.0/20"
subnet_cidr = "10.20.1.0/24"
secondary_ranges = {
  pods = "10.20.16.0/20"
  services = "10.20.32.0/20"
}
```

## Gestión de Recursos y Costos

### Script de Gestión Inteligente

El script `manage-resources.sh` proporciona gestión eficiente de recursos:

```bash
# Ver estado actual de recursos
./manage-resources.sh status devops

# Pausar recursos (escalar nodos a 0) - Mantiene cluster, ahorra costos
./manage-resources.sh pause devops

# Reanudar recursos (restaura configuración original)
./manage-resources.sh resume devops

# Destruir completamente la infraestructura
./manage-resources.sh destroy devops
```

### Estrategias de Gestión de Costos

#### Opción 1: Pausa de Recursos (Recomendada para desarrollo)
**Ventajas**:
- Mantiene cluster y configuración de red
- Escala node pools a 0 nodos (costo casi nulo)
- Reanudación rápida (2-3 minutos)
- Preserva estado de namespaces y configuraciones

**Cuándo usar**: Durante desarrollo activo, testing intermitente

#### Opción 2: Destroy/Apply Completo
**Ventajas**:
- Costo cero cuando está destruido
- Limpieza completa de recursos
- Ideal para entornos no utilizados por períodos largos

**Desventajas**:
- Tiempo de creación: 10-15 minutos
- Requiere reconfiguración de kubectl
- Pérdida de estado temporal

#### Opción 3: Recursos Compartidos
**Justificación**: Para organizaciones con múltiples proyectos:
- Cluster compartido con namespaces separados
- Reducción significativa de costos
- Gestión centralizada de recursos

## Comandos de Despliegue

### Requisitos Previos

1. **Google Cloud SDK** instalado y configurado
2. **Terraform** >= 1.0 instalado
3. **kubectl** instalado
4. Credenciales de Service Account configuradas

### Inicialización

```bash
# Inicializar Terraform
terraform init

# Validar configuración
terraform validate
```

### Despliegue por Entorno

#### DevOps Environment
```bash
# Planificar cambios
terraform plan -var-file="terraform.devops.tfvars"

# Aplicar cambios
terraform apply -var-file="terraform.devops.tfvars"

# Configurar kubectl
gcloud container clusters get-credentials taller2-devops --region us-central1 --project mi-proyecto-devops
```

#### Staging Environment
```bash
# Planificar cambios
terraform plan -var-file="terraform.staging.tfvars"

# Aplicar cambios
terraform apply -var-file="terraform.staging.tfvars"

# Configurar kubectl
gcloud container clusters get-credentials taller2-staging --region us-central1 --project mi-proyecto-staging
```

#### Production Environment
```bash
# Planificar cambios
terraform plan -var-file="terraform.prod.tfvars"

# Aplicar cambios
terraform apply -var-file="terraform.prod.tfvars"

# Configurar kubectl
gcloud container clusters get-credentials taller2-prod --region us-central1 --project mi-proyecto-prod
```

### Verificación de Estado

```bash
# Ver clusters activos
gcloud container clusters list

# Ver node pools de un cluster
gcloud container node-pools list --cluster=CLUSTER_NAME --region=REGION

# Ver estado de Terraform
terraform state list

# Ver recursos de Kubernetes
kubectl get nodes
kubectl get namespaces
```

### Destrucción de Infraestructura

```bash
# Destruir entorno específico
terraform destroy -var-file="terraform.<env>.tfvars"

# O usar el script de gestión
./manage-resources.sh destroy <env>
```

## Módulos

### Networking Module (`modules/networking/`)
- Crea VPC y subredes
- Configura rangos IP secundarios
- Establece reglas de firewall básicas

### Cluster Module (`modules/cluster/`)
- Despliega cluster GKE regional
- Configura opciones de seguridad
- Habilita APIs necesarias

### Node Pools Module (`modules/node_pools/`)
- Crea pools de nodos configurables
- Implementa autoescalado
- Configura taints y labels

### Namespaces Module (`modules/namespaces/`)
- Crea namespaces de Kubernetes
- Configura resource quotas
- Establece network policies

## Configuración Avanzada

### Service Accounts

Cada entorno utiliza una service account dedicada:

```bash
# Crear service account
gcloud iam service-accounts create terraform-sa-<env> \
    --display-name="Terraform Service Account - <env>"

# Asignar roles necesarios
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:terraform-sa-<env>@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"
```

### Variables de Entorno

Configura las variables en `environments/<env>/.env`:

```bash
# environments/devops/.env
GOOGLE_APPLICATION_CREDENTIALS=./environments/devops/devops-sa-key.json
PROJECT_ID=mi-proyecto-devops
REGION=us-central1
```

## Outputs Importantes

El proyecto proporciona los siguientes outputs:

- `cluster_name`: Nombre del cluster GKE
- `cluster_endpoint`: Endpoint del cluster (sensible)
- `network_name`: Nombre de la red VPC
- `kubectl_connection_command`: Comando para conectar kubectl

## Seguridad

### Mejores Prácticas Implementadas

1. **Principio de Menor Privilegio**: Service accounts con permisos mínimos
2. **Redes Privadas**: Clusters sin IPs públicas en nodos
3. **Workload Identity**: Autenticación segura para workloads
4. **Cifrado**: Cifrado en tránsito y en reposo habilitado
5. **Auditoría**: Logs de auditoría habilitados

### Archivos Sensibles

Asegúrate de no versionar:
- `terraform-sa-key.json`
- `environments/*/\*-sa-key.json`
- `terraform.tfstate`
- `.env` files

## Troubleshooting

### Problemas Comunes

1. **Error de permisos**: Verificar roles de service account
2. **Fallo en creación de nodos**: Verificar quotas de GCP
3. **Problemas de red**: Revisar configuración de firewall
4. **kubectl no conecta**: Verificar configuración de cluster

### Comandos Útiles

```bash
# Verificar estado de recursos
terraform state list

# Ver configuración actual
terraform show

# Verificar conectividad kubectl
kubectl cluster-info

# Ver nodos del cluster
kubectl get nodes

# Ver namespaces creados
kubectl get namespaces

# Verificar costos estimados
./manage-resources.sh status <env>
```

## Comandos Importantes para Gestión de Recursos

### Comandos de Google Cloud (gcloud)

#### Gestión de Clusters
```bash
# Listar todos los clusters GKE
gcloud container clusters list

# Describir un cluster específico
gcloud container clusters describe CLUSTER_NAME --region=REGION

# Obtener credenciales para kubectl
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION --project=PROJECT_ID

# Actualizar un cluster
gcloud container clusters upgrade CLUSTER_NAME --region=REGION

# Eliminar un cluster
gcloud container clusters delete CLUSTER_NAME --region=REGION
```

#### Gestión de Node Pools
```bash
# Listar node pools de un cluster
gcloud container node-pools list --cluster=CLUSTER_NAME --region=REGION

# Describir un node pool específico
gcloud container node-pools describe POOL_NAME --cluster=CLUSTER_NAME --region=REGION

# Escalar un node pool (PAUSA/REANUDACIÓN)
gcloud container clusters resize CLUSTER_NAME --node-pool=POOL_NAME --num-nodes=0 --region=REGION --quiet

# Restaurar node pool
gcloud container clusters resize CLUSTER_NAME --node-pool=POOL_NAME --num-nodes=CANTIDAD --region=REGION --quiet

# Crear un nuevo node pool
gcloud container node-pools create POOL_NAME --cluster=CLUSTER_NAME --region=REGION --machine-type=n1-standard-1 --num-nodes=1

# Eliminar node pool
gcloud container node-pools delete POOL_NAME --cluster=CLUSTER_NAME --region=REGION
```

#### Monitoreo de Recursos y Costos
```bash
# Ver uso de compute resources
gcloud compute instances list

# Ver discos persistentes
gcloud compute disks list

# Ver redes VPC
gcloud compute networks list

# Ver subnets
gcloud compute networks subnets list

# Ver reglas de firewall
gcloud compute firewall-rules list

# Ver quotas del proyecto
gcloud compute project-info describe --project=PROJECT_ID

# Ver facturación (requiere permisos de billing)
gcloud billing budgets list --billing-account=BILLING_ACCOUNT_ID
```

#### Gestión de Service Accounts
```bash
# Listar service accounts
gcloud iam service-accounts list

# Crear service account
gcloud iam service-accounts create SA_NAME --display-name="Display Name"

# Asignar roles
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SA_EMAIL" \
    --role="roles/container.admin"

# Crear y descargar key
gcloud iam service-accounts keys create key.json --iam-account=SA_EMAIL
```

### Comandos de Terraform

#### Operaciones Básicas
```bash
# Inicializar terraform
terraform init

# Validar configuración
terraform validate

# Formatear código
terraform fmt

# Planificar cambios
terraform plan -var-file="terraform.ENV.tfvars"

# Aplicar cambios
terraform apply -var-file="terraform.ENV.tfvars"

# Destruir infraestructura
terraform destroy -var-file="terraform.ENV.tfvars"
```

#### Gestión de Estado
```bash
# Listar recursos en estado
terraform state list

# Mostrar detalles de un recurso
terraform state show RESOURCE_NAME

# Importar recurso existente
terraform import RESOURCE_NAME RESOURCE_ID

# Remover recurso del estado (sin destruir)
terraform state rm RESOURCE_NAME

# Mover recurso en el estado
terraform state mv OLD_NAME NEW_NAME

# Mostrar configuración actual
terraform show

# Ver outputs
terraform output

# Ver output específico
terraform output OUTPUT_NAME
```

#### Debugging
```bash
# Terraform con logs detallados
TF_LOG=DEBUG terraform plan -var-file="terraform.ENV.tfvars"

# Ver plan en formato JSON
terraform plan -var-file="terraform.ENV.tfvars" -out=plan.tfplan
terraform show -json plan.tfplan

# Refrescar estado
terraform refresh -var-file="terraform.ENV.tfvars"
```

### Comandos de Kubernetes (kubectl)

#### Información de Cluster
```bash
# Información del cluster
kubectl cluster-info

# Ver versión
kubectl version

# Ver nodos y su estado
kubectl get nodes -o wide

# Describir un nodo
kubectl describe node NODE_NAME

# Ver uso de recursos de nodos
kubectl top nodes
```

#### Gestión de Namespaces
```bash
# Listar namespaces
kubectl get namespaces

# Crear namespace
kubectl create namespace NAMESPACE_NAME

# Eliminar namespace
kubectl delete namespace NAMESPACE_NAME

# Cambiar contexto a namespace
kubectl config set-context --current --namespace=NAMESPACE_NAME
```

#### Monitoreo de Recursos
```bash
# Ver todos los recursos
kubectl get all --all-namespaces

# Ver pods en todos los namespaces
kubectl get pods --all-namespaces -o wide

# Ver uso de recursos de pods
kubectl top pods --all-namespaces

# Ver events del cluster
kubectl get events --sort-by='.lastTimestamp'

# Ver logs de un pod
kubectl logs POD_NAME -n NAMESPACE_NAME

# Ejecutar comando en pod
kubectl exec -it POD_NAME -n NAMESPACE_NAME -- /bin/bash
```

#### Información de Configuración
```bash
# Ver configuración actual de kubectl
kubectl config view

# Ver contextos disponibles
kubectl config get-contexts

# Cambiar contexto
kubectl config use-context CONTEXT_NAME

# Ver información del cluster actual
kubectl config current-context
```

### Comandos del Script de Gestión (manage-resources.sh)

#### Uso Básico
```bash
# Ver ayuda completa
./manage-resources.sh help

# Ver estado de recursos con costos estimados
./manage-resources.sh status [devops|staging|prod]

# Pausar recursos (escalar a 0 nodos)
./manage-resources.sh pause [devops|staging|prod]

# Reanudar recursos (restaurar configuración)
./manage-resources.sh resume [devops|staging|prod]

# Destruir infraestructura completa
./manage-resources.sh destroy [devops|staging|prod]
```

### Script de Monitoreo Completo (monitor-all.sh)

El script `monitor-all.sh` proporciona una vista completa de todos los recursos GCP y Kubernetes:

```bash
# Monitoreo completo de todos los recursos
./monitor-all.sh

# El script muestra:
# - Clusters GKE y su estado
# - Node pools detallados
# - Instancias de Compute Engine
# - Redes VPC y subnets
# - Discos persistentes
# - Service accounts
# - Estado de Terraform
# - Recursos de Kubernetes
# - Estimación de costos
# - Recomendaciones de optimización
```

#### Ejemplos Prácticos
```bash
# Workflow típico de desarrollo
./manage-resources.sh status devops          # Ver estado actual
./manage-resources.sh pause devops           # Pausar para ahorrar costos
# ... trabajar en código ...
./manage-resources.sh resume devops          # Reanudar para testing
./manage-resources.sh status devops          # Verificar que esté funcionando

# Cambio de entorno
./manage-resources.sh pause devops           # Pausar entorno actual
terraform apply -var-file="terraform.staging.tfvars"  # Desplegar nuevo entorno
gcloud container clusters get-credentials ecommerce-staging-cluster --region us-central1
./manage-resources.sh status staging         # Verificar nuevo entorno
```

## Estrategia Detallada de Gestión de Recursos

### Filosofía de "Pausa Inteligente"

Nuestra estrategia se basa en el principio de **"Infraestructura Efímera con Estado Persistente"**:

#### 1. Componentes que se Mantienen (Persistentes)
- **Cluster GKE**: El control plane se mantiene activo
- **Redes VPC**: La infraestructura de red permanece
- **Configuraciones**: Namespaces, RBAC, ConfigMaps
- **Estado de Terraform**: Se preserva todo el estado

#### 2. Componentes que se Escalan (Efímeros)
- **Node Pools**: Se escalan a 0 nodos cuando no se usan
- **Compute Instances**: Los nodos se terminan completamente
- **Workloads**: Los pods se detienen automáticamente

### Análisis de Costos por Estrategia

#### Estrategia 1: Pausa (RECOMENDADA)
```
Cluster Control Plane: $0.10/hora = $2.40/día
Node Pools (0 nodos): $0.00/hora = $0.00/día
VPC/Networking: $0.01/día (prácticamente gratis)
TOTAL PAUSADO: ~$2.41/día
```

**Tiempo de reanudación**: 2-3 minutos
**Datos preservados**: 100%

#### Estrategia 2: Destroy/Apply
```
Estado destruido: $0.00/día
TOTAL DESTRUIDO: $0.00/día
```

**Tiempo de recreación**: 10-15 minutos
**Datos preservados**: Solo Terraform state

#### Estrategia 3: Running (Sin gestión)
```
Cluster Control Plane: $0.10/hora = $2.40/día
Node Pools (1 nodo n1-standard-1): $0.0475/hora = $1.14/día
VPC/Networking: $0.01/día
TOTAL CORRIENDO: ~$3.55/día
```

### Flujos de Trabajo Optimizados

#### Flujo de Desarrollo Diario
```bash
# Mañana - Iniciar trabajo
./manage-resources.sh resume devops
kubectl get nodes  # Verificar que esté listo

# Durante el día - Desarrollo normal
terraform plan -var-file="terraform.devops.tfvars"
kubectl apply -f deployments/

# Almuerzo - Pausa temporal
./manage-resources.sh pause devops

# Tarde - Continuar trabajo
./manage-resources.sh resume devops

# Fin del día - Pausa nocturna
./manage-resources.sh pause devops
```

#### Flujo de Testing Multi-Entorno
```bash
# Testing en devops
./manage-resources.sh status devops
kubectl apply -f test-deployment.yaml

# Cambio a staging para validación
./manage-resources.sh pause devops
terraform apply -var-file="terraform.staging.tfvars"
gcloud container clusters get-credentials ecommerce-staging-cluster --region us-central1
kubectl apply -f test-deployment.yaml

# Validación exitosa, preparar para prod
./manage-resources.sh pause staging
terraform apply -var-file="terraform.prod.tfvars"
```

### Monitoreo y Alertas

#### Scripts de Monitoreo Automatizado
```bash
# Crear cron job para monitoreo diario
echo "0 9 * * * cd /path/to/taller2 && ./manage-resources.sh status devops >> /var/log/gke-costs.log" | crontab -

# Verificar recursos "olvidados" corriendo
gcloud container clusters list --format="table(name,status,currentNodeCount,location)" | grep RUNNING

# Calcular costos estimados mensuales
./manage-resources.sh status devops | grep "Costo estimado" | awk '{print $5 * 30}'
```

### Mejores Prácticas de Gestión

1. **Automatización**: Usar scripts para evitar errores manuales
2. **Documentación**: Mantener log de cambios y estados
3. **Verificación**: Siempre verificar estado antes de cambios críticos
4. **Backup**: Guardar configuraciones importantes antes de destroy
5. **Monitoreo**: Revisar costos y uso regularmente

## Referencia Rápida de Comandos

### Comandos Esenciales Diarios

```bash
# MONITOREO Y ESTADO
./monitor-all.sh                                    # Monitoreo completo de recursos
./manage-resources.sh status devops                 # Estado específico de un entorno
gcloud container clusters list                      # Ver todos los clusters
kubectl get nodes -o wide                          # Ver nodos activos

# ⏸GESTIÓN DE COSTOS
./manage-resources.sh pause devops                  # Pausar recursos (ahorra ~$3/día)
./manage-resources.sh resume devops                 # Reanudar recursos (2-3 min)
./manage-resources.sh destroy devops                # Destruir completamente

# DESPLIEGUE Y CAMBIOS
terraform plan -var-file="terraform.devops.tfvars" # Planificar cambios
terraform apply -var-file="terraform.devops.tfvars" # Aplicar cambios
terraform state list                                # Ver recursos gestionados

# KUBERNETES
kubectl config get-contexts                         # Ver contextos disponibles
kubectl config use-context CONTEXT_NAME            # Cambiar contexto
kubectl get all --all-namespaces                   # Ver todos los recursos K8s
```

### Comandos de Emergencia y Troubleshooting

```bash
# PROBLEMAS DE CONEXIÓN
gcloud auth list                                    # Verificar autenticación
gcloud config set project PROJECT_ID               # Cambiar proyecto activo
gcloud container clusters get-credentials CLUSTER --region REGION  # Reconfigurar kubectl

# DEBUGGING
TF_LOG=DEBUG terraform plan -var-file="terraform.devops.tfvars"  # Terraform verbose
kubectl describe nodes                              # Detalles de nodos
kubectl get events --sort-by='.lastTimestamp'      # Eventos recientes de K8s
gcloud compute instances list --filter="status:RUNNING"  # Solo instancias corriendo

# COSTOS Y LIMPIEZA
gcloud compute instances list --format="value(name)" | grep gke | wc -l  # Contar nodos GKE
terraform destroy -var-file="terraform.devops.tfvars" -auto-approve     # Destrucción rápida
```

### Flujos de Trabajo Comunes

```bash
# INICIO DEL DÍA
./monitor-all.sh                                    # Ver estado general
./manage-resources.sh resume devops                 # Activar entorno de trabajo
kubectl get nodes                                   # Verificar que esté listo

# CAMBIO DE ENTORNO
./manage-resources.sh pause devops                  # Pausar entorno actual
terraform apply -var-file="terraform.staging.tfvars"  # Desplegar nuevo entorno
gcloud container clusters get-credentials ecommerce-staging-cluster --region us-central1
kubectl config current-context                      # Verificar contexto

# FIN DEL DÍA
./manage-resources.sh pause devops                  # Pausar para ahorrar costos
git add . && git commit -m "Daily changes" && git push  # Guardar cambios

# LIMPIEZA SEMANAL
./monitor-all.sh                                    # Revisar recursos activos
terraform state list | wc -l                       # Contar recursos gestionados
./manage-resources.sh destroy UNUSED_ENV           # Limpiar entornos no usados
```

### Comandos de Monitoreo Avanzado

```bash
# ANÁLISIS DE RECURSOS
gcloud compute instances list --format="table(name,zone,machineType,status,creationTimestamp)"
gcloud container node-pools list --cluster=CLUSTER --region=REGION --format="table(name,machineType,initialNodeCount,status)"
kubectl top nodes                                   # Uso de CPU/Memoria por nodo
kubectl top pods --all-namespaces                  # Uso de recursos por pods

# ANÁLISIS DE COSTOS
gcloud compute instances list --format="value(machineType)" | sort | uniq -c  # Tipos de máquinas en uso
gcloud compute disks list --format="value(sizeGb)" | awk '{sum += $1} END {print "Total GB:", sum}'  # Almacenamiento total
./manage-resources.sh status devops | grep "Costo estimado"  # Costo específico por entorno

# SEGURIDAD Y PERMISOS
gcloud iam service-accounts list                    # Ver service accounts
gcloud projects get-iam-policy PROJECT_ID          # Ver permisos del proyecto
kubectl auth can-i "*" "*" --all-namespaces        # Verificar permisos K8s
```

## Próximos Pasos

1. **Monitoring**: Implementar Prometheus y Grafana
2. **CI/CD**: Integrar con pipelines de despliegue
3. **Backup**: Configurar respaldos automáticos
4. **Scaling**: Implementar HPA y VPA
5. **Security**: Agregar políticas de seguridad adicionales

## Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo LICENSE para más detalles.

---

**Nota**: Este es un proyecto de infraestructura crítica. Siempre ejecuta `terraform plan` antes de aplicar cambios en producción.