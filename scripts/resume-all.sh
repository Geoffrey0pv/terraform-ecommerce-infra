#!/bin/bash

# Script para reanudar la infraestructura
# Escalará el node pool principal a 4 nodos

set -e

CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"
NODE_POOL="general-pool"
NUM_NODES=4

echo "▶️  REANUDANDO INFRAESTRUCTURA"
echo "=============================="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Node Pool: $NODE_POOL"
echo "Nodos objetivo: $NUM_NODES"
echo ""

# Reanudar node pool
echo "▶️  Escalando node pool a $NUM_NODES nodos..."
gcloud container clusters resize $CLUSTER_NAME \
    --node-pool=$NODE_POOL \
    --num-nodes=$NUM_NODES \
    --region=$REGION \
    --quiet

echo ""
echo "✅ INFRAESTRUCTURA REANUDADA"
echo ""
echo "⏰ Los nodos tardarán 2-3 minutos en estar completamente listos"
echo ""
echo "📊 Verificando estado de nodos..."
sleep 30
kubectl get nodes
echo ""
echo "💰 Costo estimado activo: ~$150 USD/mes"
echo ""
echo "📋 Para ver el estado completo:"
echo "   ./check-all.sh"