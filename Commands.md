# Guía de Comandos Importantes

## Comandos de Terraform

### Inicialización y Configuración
```bash
# Inicializar Terraform
terraform init

# Verificar configuración
terraform validate

# Formatear archivos
terraform fmt

# Ver plan de cambios
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy
```

### Gestión de Workspaces
```bash
# Listar workspaces
terraform workspace list

# Crear workspace
terraform workspace new devops

# Seleccionar workspace
terraform workspace select devops

# Mostrar workspace actual
terraform workspace show
```

### Aplicar por Ambiente
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

## Comandos de Google Cloud

### Autenticación y Configuración
```bash
# Autenticarse
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Ver configuración actual
gcloud config list

# Configurar región
gcloud config set compute/region us-central1
```

### Gestión de Clusters
```bash
# Listar clusters
gcloud container clusters list

# Obtener credenciales
gcloud container clusters get-credentials CLUSTER_NAME --region REGION --project PROJECT_ID

# Describir cluster
gcloud container clusters describe CLUSTER_NAME --region REGION

# Ver nodos del cluster
gcloud compute instances list --filter="name~gke-"
```

### Gestión de Red
```bash
# Listar VPCs
gcloud compute networks list

# Listar subnets
gcloud compute networks subnets list

# Listar firewall rules
gcloud compute firewall-rules list

# Listar routers
gcloud compute routers list

# Listar NAT gateways
gcloud compute routers nats list --router=ROUTER_NAME --region=REGION
```

## Comandos de Kubernetes

### Información General
```bash
# Ver información del cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Ver nodos con detalles
kubectl get nodes -o wide

# Describir nodo
kubectl describe node NODE_NAME
```

### Gestión de Namespaces
```bash
# Listar namespaces
kubectl get namespaces

# Crear namespace
kubectl create namespace NAMESPACE_NAME

# Eliminar namespace
kubectl delete namespace NAMESPACE_NAME

# Describir namespace
kubectl describe namespace NAMESPACE_NAME
```

### Gestión de Pods
```bash
# Listar pods en todos los namespaces
kubectl get pods --all-namespaces

# Listar pods en namespace específico
kubectl get pods -n NAMESPACE_NAME

# Describir pod
kubectl describe pod POD_NAME -n NAMESPACE_NAME

# Ver logs de pod
kubectl logs POD_NAME -n NAMESPACE_NAME

# Ver logs con seguimiento
kubectl logs -f POD_NAME -n NAMESPACE_NAME

# Ejecutar comando en pod
kubectl exec -it POD_NAME -n NAMESPACE_NAME -- /bin/bash

# Eliminar pod
kubectl delete pod POD_NAME -n NAMESPACE_NAME
```

### Gestión de Servicios
```bash
# Listar servicios
kubectl get services --all-namespaces

# Describir servicio
kubectl describe service SERVICE_NAME -n NAMESPACE_NAME

# Crear servicio
kubectl expose deployment DEPLOYMENT_NAME --port=PORT --target-port=TARGET_PORT -n NAMESPACE_NAME

# Eliminar servicio
kubectl delete service SERVICE_NAME -n NAMESPACE_NAME
```

### Gestión de Ingress
```bash
# Listar ingress
kubectl get ingress --all-namespaces

# Describir ingress
kubectl describe ingress INGRESS_NAME -n NAMESPACE_NAME

# Aplicar ingress
kubectl apply -f ingress.yaml

# Eliminar ingress
kubectl delete ingress INGRESS_NAME -n NAMESPACE_NAME
```

### Gestión de Deployments
```bash
# Listar deployments
kubectl get deployments --all-namespaces

# Describir deployment
kubectl describe deployment DEPLOYMENT_NAME -n NAMESPACE_NAME

# Escalar deployment
kubectl scale deployment DEPLOYMENT_NAME --replicas=3 -n NAMESPACE_NAME

# Actualizar deployment
kubectl set image deployment/DEPLOYMENT_NAME CONTAINER_NAME=IMAGE:TAG -n NAMESPACE_NAME

# Ver historial de rollout
kubectl rollout history deployment/DEPLOYMENT_NAME -n NAMESPACE_NAME

# Revertir deployment
kubectl rollout undo deployment/DEPLOYMENT_NAME -n NAMESPACE_NAME
```

### Gestión de ConfigMaps y Secrets
```bash
# Listar configmaps
kubectl get configmaps --all-namespaces

# Crear configmap
kubectl create configmap CONFIG_NAME --from-literal=key=value -n NAMESPACE_NAME

# Listar secrets
kubectl get secrets --all-namespaces

# Crear secret
kubectl create secret generic SECRET_NAME --from-literal=key=value -n NAMESPACE_NAME

# Ver secret
kubectl get secret SECRET_NAME -n NAMESPACE_NAME -o yaml
```

## Comandos de Monitoreo

### Recursos del Sistema
```bash
# Ver uso de recursos de nodos
kubectl top nodes

# Ver uso de recursos de pods
kubectl top pods --all-namespaces

# Ver uso de recursos por namespace
kubectl top pods -n NAMESPACE_NAME
```

### Eventos y Logs
```bash
# Ver eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver eventos por namespace
kubectl get events -n NAMESPACE_NAME

# Ver logs de todos los pods
kubectl logs --all-containers=true --all-namespaces=true
```

### Estado de la Infraestructura
```bash
# Ver estado de todos los recursos
kubectl get all --all-namespaces

# Ver estado de recursos específicos
kubectl get pods,services,ingress --all-namespaces

# Ver estado de recursos por namespace
kubectl get all -n NAMESPACE_NAME
```

## Comandos de Port Forwarding

### Acceso a Servicios
```bash
# Port forward a servicio
kubectl port-forward svc/SERVICE_NAME PORT:PORT -n NAMESPACE_NAME

# Port forward a pod
kubectl port-forward pod/POD_NAME PORT:PORT -n NAMESPACE_NAME

# Port forward en background
kubectl port-forward svc/SERVICE_NAME PORT:PORT -n NAMESPACE_NAME &

# Ver port forwards activos
lsof -i :PORT
```

### Ejemplos de Port Forwarding
```bash
# Jenkins
kubectl port-forward svc/jenkins 8080:8080 -n tools

# Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

## Comandos de Debugging

### Diagnóstico de Problemas
```bash
# Ver logs de todos los contenedores
kubectl logs --all-containers=true --all-namespaces=true

# Ver logs de un contenedor específico
kubectl logs -c CONTAINER_NAME POD_NAME -n NAMESPACE_NAME

# Ver logs anteriores
kubectl logs --previous POD_NAME -n NAMESPACE_NAME

# Describir recurso para debugging
kubectl describe pod POD_NAME -n NAMESPACE_NAME
```

### Verificación de Conectividad
```bash
# Probar conectividad a servicio
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- SERVICE_NAME.NAMESPACE_NAME.svc.cluster.local:PORT

# Probar DNS
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup SERVICE_NAME.NAMESPACE_NAME.svc.cluster.local

# Probar conectividad externa
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- http://google.com
```

## Comandos de Limpieza

### Limpiar Recursos
```bash
# Eliminar todos los pods en namespace
kubectl delete pods --all -n NAMESPACE_NAME

# Eliminar todos los servicios en namespace
kubectl delete services --all -n NAMESPACE_NAME

# Eliminar todos los deployments en namespace
kubectl delete deployments --all -n NAMESPACE_NAME

# Eliminar namespace completo
kubectl delete namespace NAMESPACE_NAME
```

### Limpiar Recursos Huérfanos
```bash
# Ver recursos huérfanos
kubectl get all --all-namespaces | grep -v Running

# Eliminar recursos huérfanos
kubectl delete pods --field-selector=status.phase=Failed --all-namespaces
```

## Comandos de Scripts

### Usar Scripts de Automatización
```bash
# Monitoreo completo
./scripts/monitor-all.sh

# Gestión de infraestructura
./scripts/manage-infra.sh apply
./scripts/manage-infra.sh destroy
./scripts/manage-infra.sh plan

# Gestión de recursos
./scripts/manage-resources.sh create
./scripts/manage-resources.sh list
./scripts/manage-resources.sh delete

# Aplicar Terraform
./scripts/apply_terraform.sh

# Destruir Terraform
./scripts/destroy_terraform.sh

# Pausar recursos
./scripts/pause-resources.sh
```

## Comandos de Verificación Rápida

### Estado del Cluster
```bash
# Verificar estado general
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get ingress --all-namespaces

# Verificar recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Verificar eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Estado de la Infraestructura
```bash
# Verificar clusters GKE
gcloud container clusters list

# Verificar VPCs
gcloud compute networks list

# Verificar subnets
gcloud compute networks subnets list

# Verificar firewall rules
gcloud compute firewall-rules list
```

## Comandos de Backup y Restore

### Backup de Configuración
```bash
# Exportar configuración de namespace
kubectl get namespace NAMESPACE_NAME -o yaml > namespace-backup.yaml

# Exportar configuración de recursos
kubectl get all -n NAMESPACE_NAME -o yaml > resources-backup.yaml

# Exportar configuración de ingress
kubectl get ingress --all-namespaces -o yaml > ingress-backup.yaml
```

### Restore de Configuración
```bash
# Aplicar configuración de namespace
kubectl apply -f namespace-backup.yaml

# Aplicar configuración de recursos
kubectl apply -f resources-backup.yaml

# Aplicar configuración de ingress
kubectl apply -f ingress-backup.yaml
```

---

**Nota**: Reemplaza los valores en MAYÚSCULAS con los valores reales de tu infraestructura.
