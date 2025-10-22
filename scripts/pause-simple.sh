#!/bin/bash

# Script simple para pausar la infraestructura
# Reduce los node pools a 0 nodos para ahorrar costos

set -e

CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"
PROJECT_ID="ecommerce-backend-1760307199"

echo "🔄 PAUSANDO INFRAESTRUCTURA..."
echo "Cluster: $CLUSTER_NAME"
echo "Región: $REGION"
echo "Proyecto: $PROJECT_ID"
echo ""

# Obtener todos los node pools
echo "📋 Obteniendo node pools actuales..."
NODE_POOLS=$(gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION --format="value(name)")

echo "Node pools encontrados:"
echo "$NODE_POOLS"
echo ""

# Pausar cada node pool (reducir a 0 nodos)
for pool in $NODE_POOLS; do
    echo "⏸️  Pausando node pool: $pool"
    gcloud container clusters resize $CLUSTER_NAME \
        --node-pool=$pool \
        --num-nodes=0 \
        --region=$REGION \
        --quiet
    echo "✅ Node pool $pool pausado (0 nodos)"
done

echo ""
echo "🎉 INFRAESTRUCTURA PAUSADA COMPLETAMENTE"
echo "💰 Esto ahorrará aproximadamente \$200-400 USD/mes"
echo ""
echo "Para reanudar, ejecuta:"
echo "  gcloud container clusters resize $CLUSTER_NAME --node-pool=[POOL_NAME] --num-nodes=1 --region=$REGION"