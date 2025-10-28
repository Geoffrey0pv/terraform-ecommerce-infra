#!/bin/bash

# Script para pausar completamente la infraestructura
# Reducirá todos los node pools a 0 nodos para ahorrar costos

set -e

CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"

echo "⏸️  PAUSANDO INFRAESTRUCTURA COMPLETA"
echo "====================================="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Región: $REGION"
echo ""

# Obtener todos los node pools
echo "📋 Obteniendo node pools..."
NODE_POOLS=$(gcloud container node-pools list --cluster=$CLUSTER_NAME --region=$REGION --format="value(name)")

if [ -z "$NODE_POOLS" ]; then
    echo "❌ No se encontraron node pools"
    exit 1
fi

echo "Node pools encontrados:"
echo "$NODE_POOLS"
echo ""

# Pausar cada node pool
for pool in $NODE_POOLS; do
    echo "⏸️  Pausando node pool: $pool"
    gcloud container clusters resize $CLUSTER_NAME \
        --node-pool=$pool \
        --num-nodes=0 \
        --region=$REGION \
        --quiet
    echo "✅ Node pool $pool pausado (0 nodos)"
    echo ""
done

echo "🎉 INFRAESTRUCTURA COMPLETAMENTE PAUSADA"
echo ""
echo "💰 Ahorros estimados:"
echo "   - Costo con nodos: ~$150 USD/mes"
echo "   - Costo pausado: ~$10 USD/mes (solo cluster)"
echo "   - Ahorro: ~$140 USD/mes"
echo ""
echo "📋 Estado actual:"
kubectl get nodes 2>/dev/null || echo "   No hay nodos activos (esperado)"
echo ""
echo "🔄 Para reanudar, ejecuta:"
echo "   ./resume-all.sh"