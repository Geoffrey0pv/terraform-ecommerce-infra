# Ejemplos Prácticos de Uso - Infraestructura GKE

Este documento proporciona ejemplos paso a paso para tareas comunes de gestión de infraestructura.

## Escenario 1: Inicio de un Día de Desarrollo

```bash
# 1. Verificar estado general de recursos
./monitor-all.sh

# 2. Si los recursos están pausados, reanudarlos
./manage-resources.sh resume devops

# 3. Esperar a que los nodos estén listos (2-3 minutos)
watch "kubectl get nodes"

# 4. Verificar que todo esté funcionando
kubectl get all --all-namespaces
```

## Escenario 2: Cambio de Entorno (DevOps → Staging)

```bash
# 1. Pausar entorno actual para ahorrar costos
./manage-resources.sh pause devops

# 2. Desplegar entorno staging
terraform plan -var-file="terraform.staging.tfvars"
terraform apply -var-file="terraform.staging.tfvars"

# 3. Configurar kubectl para staging
gcloud container clusters get-credentials ecommerce-staging-cluster --region us-central1

# 4. Verificar que el contexto cambió
kubectl config current-context

# 5. Confirmar que staging está activo
./manage-resources.sh status staging
```

## Escenario 3: Fin del Día - Ahorro de Costos

```bash
# 1. Guardar trabajo en git
git add .
git commit -m "End of day - $(date)"
git push

# 2. Pausar recursos para ahorrar costos
./manage-resources.sh pause devops

# 3. Verificar que se pausaron correctamente
gcloud compute instances list --filter="name:gke"

# 4. Confirmar ahorro de costos
./monitor-all.sh | grep "Costo estimado"
```

## Escenario 4: Debugging de Problemas de Conectividad

```bash
# 1. Verificar contexto de kubectl
kubectl config current-context

# 2. Si no puedes conectarte, reconfigurar credenciales
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# 3. Verificar que el cluster esté corriendo
gcloud container clusters list

# 4. Ver eventos recientes del cluster
kubectl get events --sort-by='.lastTimestamp' | head -20

# 5. Si los nodos no están Ready, verificar detalles
kubectl describe nodes
```

## Escenario 5: Análisis de Costos Semanales

```bash
# 1. Monitoreo completo
./monitor-all.sh > weekly-report-$(date +%Y%m%d).txt

# 2. Ver recursos que están consumiendo
gcloud compute instances list --format="table(name,zone,machineType,status)"

# 3. Calcular almacenamiento total
gcloud compute disks list --format="value(sizeGb)" | awk '{sum += $1} END {print "Total GB:", sum}'

# 4. Identificar recursos no utilizados
terraform state list | grep -v "data\." | wc -l
```

## Escenario 6: Preparación para Producción

```bash
# 1. Verificar que staging esté estable
./manage-resources.sh status staging
kubectl get nodes -o wide

# 2. Hacer backup de configuraciones importantes
cp terraform.staging.tfvars terraform.staging.tfvars.backup-$(date +%Y%m%d)

# 3. Desplegar a producción
terraform plan -var-file="terraform.prod.tfvars"
terraform apply -var-file="terraform.prod.tfvars"

# 4. Configurar kubectl para producción
gcloud container clusters get-credentials ecommerce-prod-cluster --region us-central1

# 5. Verificar que producción esté saludable
kubectl get nodes
kubectl get all --all-namespaces
```

## Escenario 7: Limpieza de Recursos No Utilizados

```bash
# 1. Ver todos los entornos activos
gcloud container clusters list

# 2. Identificar entornos que no necesitas
./manage-resources.sh status devops
./manage-resources.sh status staging
./manage-resources.sh status prod

# 3. Destruir entornos no utilizados
./manage-resources.sh destroy UNUSED_ENV

# 4. Limpiar archivos temporales
rm -f .*.tmp
terraform state list | grep -c "resource"
```

## Escenario 8: Monitoreo Automatizado con Cron

```bash
# 1. Crear script de monitoreo diario
cat > daily-monitor.sh << 'EOF'
#!/bin/bash
cd /path/to/taller2
./monitor-all.sh >> /var/log/gke-daily-$(date +%Y%m).log
if [ $(gcloud compute instances list --format="value(name)" | grep gke | wc -l) -gt 0 ]; then
  echo "WARNING: GKE nodes running - Daily cost: ~$3-4 USD" | mail -s "GKE Cost Alert" your-email@domain.com
fi
EOF

# 2. Hacer ejecutable
chmod +x daily-monitor.sh

# 3. Agregar a crontab (ejecutar cada día a las 9 AM)
echo "0 9 * * * /path/to/daily-monitor.sh" | crontab -

# 4. Verificar que se agregó
crontab -l
```

## Comandos de Troubleshooting por Problema

### Problema: "kubectl: command not found"
```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Problema: "Error: cluster not found"
```bash
# Verificar que el cluster existe
gcloud container clusters list

# Si existe, reconfigurar credenciales
gcloud container clusters get-credentials CLUSTER_NAME --region REGION
```

### Problema: "Nodos en estado NotReady"
```bash
# Ver detalles del nodo
kubectl describe node NODE_NAME

# Ver pods del sistema que pueden estar fallando
kubectl get pods -n kube-system

# Reiniciar node pool si es necesario
gcloud container clusters resize CLUSTER --node-pool=POOL --num-nodes=0 --region=REGION
gcloud container clusters resize CLUSTER --node-pool=POOL --num-nodes=1 --region=REGION
```

### Problema: "Terraform state lock"
```bash
# Ver el lock
terraform force-unlock LOCK_ID

# Si no funciona, eliminar el lock manualmente
rm -f .terraform.tfstate.lock.info
```

### Problema: "Costos muy altos"
```bash
# Identificar recursos costosos
./monitor-all.sh | grep -A 5 "ESTIMACIÓN DE COSTOS"

# Pausar todos los entornos
./manage-resources.sh pause devops
./manage-resources.sh pause staging
./manage-resources.sh pause prod

# Verificar que no hay nodos corriendo
gcloud compute instances list --format="value(name)" | grep gke
```

## Tips de Optimización de Costos

1. **Pausa Diaria**: Pausa recursos al final del día (~70% ahorro)
2. **Monitoreo Semanal**: Revisa costos semanalmente con `./monitor-all.sh`
3. **Entornos Bajo Demanda**: Solo despliega staging/prod cuando necesites
4. **Cleanup Regular**: Destruye entornos no utilizados mensualmente
5. **Automatización**: Usa cron jobs para pausar recursos automáticamente

## Métricas de Éxito

- **Tiempo de despliegue**: < 15 minutos para crear entorno completo
- **Tiempo de pausa/reanudación**: < 3 minutos
- **Ahorro de costos**: > 60% con gestión adecuada
- **Disponibilidad**: 99%+ cuando los recursos están activos