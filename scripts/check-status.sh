#!/bin/bash

# Script para verificar el estado completo de la arquitectura
# Ejecutar después de autenticarse con: gcloud auth login

set -e

PROJECT_ID="ecommerce-backend-1760307199"
REGION="us-central1"
CLUSTER_NAME="ecommerce-devops-cluster"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   📊 REPORTE COMPLETO DE ESTADO DE ARQUITECTURA${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${GREEN}Proyecto:${NC} $PROJECT_ID"
echo -e "${GREEN}Región:${NC} $REGION"
echo -e "${GREEN}Cluster:${NC} $CLUSTER_NAME"
echo -e "${GREEN}Fecha:${NC} $(date)"
echo ""

# ========================================
# 1. VERIFICAR AUTENTICACIÓN
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🔐 1. AUTENTICACIÓN${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
gcloud auth list
echo ""

# ========================================
# 2. ESTADO DEL CLUSTER GKE
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🔧 2. CLUSTER GKE${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
gcloud container clusters list --format="table(name,location,status,currentNodeCount,currentMasterVersion)"
echo ""

# ========================================
# 3. NODE POOLS
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📦 3. NODE POOLS${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION \
    --format="table(name,machineType,diskSizeGb,nodeCount,status,version)"
echo ""

# ========================================
# 4. NODOS DE KUBERNETES
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🖥️  4. NODOS DE KUBERNETES${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
kubectl get nodes -o wide
echo ""

# ========================================
# 5. USO DE RECURSOS DE NODOS
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📈 5. USO DE RECURSOS (CPU/MEMORIA)${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
if kubectl top nodes 2>/dev/null; then
    :
else
    echo -e "${RED}⚠️  Metrics API no disponible aún. Espera 1-2 minutos.${NC}"
fi
echo ""

# ========================================
# 6. NAMESPACES
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📂 6. NAMESPACES${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
kubectl get namespaces
echo ""

# ========================================
# 7. PODS POR NAMESPACE (Solo aplicaciones)
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🚀 7. PODS DE APLICACIONES${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""

echo -e "${GREEN}Namespace: tools (Jenkins)${NC}"
kubectl get pods -n tools -o wide 2>/dev/null || echo "Sin pods"
echo ""

echo -e "${GREEN}Namespace: staging (Microservicios)${NC}"
kubectl get pods -n staging -o wide 2>/dev/null || echo "Sin pods"
echo ""

echo -e "${GREEN}Namespace: ingress-nginx${NC}"
kubectl get pods -n ingress-nginx -o wide 2>/dev/null || echo "Sin pods"
echo ""

# ========================================
# 8. SERVICIOS
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🌐 8. SERVICIOS (Services)${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
kubectl get services --all-namespaces | grep -v "kube-system\|gmp-system\|gke-managed" || echo "Sin servicios de aplicación"
echo ""

# ========================================
# 9. PERSISTENT VOLUMES
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}💾 9. ALMACENAMIENTO PERSISTENTE${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
echo "PersistentVolumeClaims:"
kubectl get pvc --all-namespaces
echo ""
echo "PersistentVolumes:"
kubectl get pv
echo ""

# ========================================
# 10. DEPLOYMENTS Y STATEFULSETS
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📊 10. DEPLOYMENTS Y STATEFULSETS${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
echo "Deployments:"
kubectl get deployments --all-namespaces | grep -v "kube-system\|gmp-system\|gke-managed" || echo "Sin deployments"
echo ""
echo "StatefulSets:"
kubectl get statefulsets --all-namespaces | grep -v "kube-system\|gmp-system\|gke-managed" || echo "Sin statefulsets"
echo ""

# ========================================
# 11. EVENTOS RECIENTES
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📋 11. EVENTOS RECIENTES (últimos 10)${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
echo ""

# ========================================
# 12. USO DE CUOTA
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📏 12. USO DE CUOTA DE INSTANCIAS${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""
INSTANCE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo -e "Instancias en uso: ${GREEN}$INSTANCE_COUNT/8${NC}"
echo -e "Margen disponible: ${GREEN}$((8 - INSTANCE_COUNT))${NC} instancias"
echo ""

# ========================================
# 13. RESUMEN DE RECURSOS
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}📊 13. RESUMEN DE RECURSOS${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""

TOTAL_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep Running | wc -l)
PENDING_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep Pending | wc -l)
FAILED_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -E "Error|CrashLoopBackOff|Failed" | wc -l)

echo -e "Total de Pods: ${BLUE}$TOTAL_PODS${NC}"
echo -e "  └─ Running: ${GREEN}$RUNNING_PODS${NC}"
echo -e "  └─ Pending: ${YELLOW}$PENDING_PODS${NC}"
echo -e "  └─ Failed/Error: ${RED}$FAILED_PODS${NC}"
echo ""

# ========================================
# 14. SERVICIOS CLAVE
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}🎯 14. ESTADO DE SERVICIOS CLAVE${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""

# Jenkins
if kubectl get pods -n tools 2>/dev/null | grep -q jenkins; then
    JENKINS_STATUS=$(kubectl get pods -n tools | grep jenkins | awk '{print $3}')
    echo -e "✓ Jenkins: ${GREEN}$JENKINS_STATUS${NC}"
else
    echo -e "✗ Jenkins: ${RED}No desplegado${NC}"
fi

# MySQL
if kubectl get pods -n staging 2>/dev/null | grep -q mysql; then
    MYSQL_STATUS=$(kubectl get pods -n staging | grep mysql | awk '{print $3}')
    echo -e "✓ MySQL: ${GREEN}$MYSQL_STATUS${NC}"
else
    echo -e "✗ MySQL: ${YELLOW}No desplegado${NC}"
fi

# Microservicios
for service in user-service product-service order-service; do
    if kubectl get pods -n staging 2>/dev/null | grep -q $service; then
        SVC_STATUS=$(kubectl get pods -n staging | grep $service | head -1 | awk '{print $3}')
        echo -e "✓ $service: ${GREEN}$SVC_STATUS${NC}"
    else
        echo -e "✗ $service: ${YELLOW}No desplegado${NC}"
    fi
done

# API Gateway
if kubectl get pods -n staging 2>/dev/null | grep -q gateway; then
    GW_STATUS=$(kubectl get pods -n staging | grep gateway | awk '{print $3}')
    echo -e "✓ API Gateway: ${GREEN}$GW_STATUS${NC}"
else
    echo -e "✗ API Gateway: ${YELLOW}No desplegado${NC}"
fi

echo ""

# ========================================
# 15. RECOMENDACIONES
# ========================================
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}💡 15. RECOMENDACIONES${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo ""

if [ $FAILED_PODS -gt 0 ]; then
    echo -e "${RED}⚠️  Hay $FAILED_PODS pods con errores. Revisar con:${NC}"
    echo "   kubectl get pods --all-namespaces | grep -E 'Error|CrashLoopBackOff|Failed'"
fi

if [ $PENDING_PODS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Hay $PENDING_PODS pods pendientes. Revisar recursos.${NC}"
fi

if [ $INSTANCE_COUNT -ge 7 ]; then
    echo -e "${RED}⚠️  Uso de cuota alto ($INSTANCE_COUNT/8). Considerar optimización.${NC}"
fi

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}✅ Reporte completado${NC}"
echo -e "${BLUE}================================================================${NC}"