#!/bin/bash

# Script para verificar el estado completo de la infraestructura
# Muestra clusters, node pools, nodos, namespaces y pods

set -e

CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   📊 ESTADO COMPLETO DE LA INFRAESTRUCTURA${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# 1. Cluster
echo -e "${YELLOW}🔧 CLUSTER GKE${NC}"
echo "─────────────────────────────────────────"
gcloud container clusters list --format="table(name,location,status,currentNodeCount)" 2>/dev/null || echo "No autenticado o sin permisos"
echo ""

# 2. Node Pools
echo -e "${YELLOW}📦 NODE POOLS${NC}"
echo "─────────────────────────────────────────"
gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION \
    --format="table(name,machineType,nodeCount,status)" 2>/dev/null || echo "No autenticado o cluster no encontrado"
echo ""

# 3. Nodos
echo -e "${YELLOW}🖥️  NODOS DE KUBERNETES${NC}"
echo "─────────────────────────────────────────"
kubectl get nodes -o wide 2>/dev/null || echo "No hay nodos o kubectl no configurado"
echo ""

# 4. Namespaces
echo -e "${YELLOW}📂 NAMESPACES CONFIGURADOS${NC}"
echo "─────────────────────────────────────────"
kubectl get namespaces 2>/dev/null | grep -E "NAME|tools|staging|production" || echo "kubectl no configurado"
echo ""

# 5. Pods por namespace
echo -e "${YELLOW}🚀 PODS POR NAMESPACE${NC}"
echo "─────────────────────────────────────────"
echo ""
echo -e "${GREEN}Namespace: tools${NC}"
kubectl get pods -n tools -o wide 2>/dev/null || echo "Sin pods o namespace no existe"
echo ""
echo -e "${GREEN}Namespace: staging${NC}"
kubectl get pods -n staging -o wide 2>/dev/null || echo "Sin pods o namespace no existe"
echo ""
echo -e "${GREEN}Namespace: production${NC}"
kubectl get pods -n production -o wide 2>/dev/null || echo "Sin pods o namespace no existe"
echo ""

# 6. Servicios
echo -e "${YELLOW}🌐 SERVICIOS EXPUESTOS${NC}"
echo "─────────────────────────────────────────"
kubectl get services --all-namespaces 2>/dev/null | grep -v "kube-system\|gmp-system\|gke-managed" || echo "Sin servicios"
echo ""

# 7. Resumen
echo -e "${YELLOW}📊 RESUMEN${NC}"
echo "─────────────────────────────────────────"
NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
PODS_TOOLS=$(kubectl get pods -n tools --no-headers 2>/dev/null | wc -l)
PODS_STAGING=$(kubectl get pods -n staging --no-headers 2>/dev/null | wc -l)
PODS_PROD=$(kubectl get pods -n production --no-headers 2>/dev/null | wc -l)

echo -e "Nodos activos: ${GREEN}$NODES/4${NC}"
echo -e "Pods en tools: ${GREEN}$PODS_TOOLS${NC}"
echo -e "Pods en staging: ${GREEN}$PODS_STAGING${NC}"
echo -e "Pods en production: ${GREEN}$PODS_PROD${NC}"
echo ""

# 8. Cuota
echo -e "${YELLOW}📏 USO DE CUOTA${NC}"
echo "─────────────────────────────────────────"
echo -e "Instancias usadas: ${GREEN}$NODES/8${NC}"
echo -e "Margen disponible: ${GREEN}$((8 - NODES))${NC} instancias"
echo ""

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}✅ Verificación completa${NC}"
echo -e "${BLUE}================================================================${NC}"