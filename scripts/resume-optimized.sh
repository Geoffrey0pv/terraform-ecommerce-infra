#!/bin/bash

# Script para reanudar infraestructura optimizada
# Solo mantiene Jenkins + Grafana

set -e

CLUSTER_NAME="ecommerce-devops-cluster"
REGION="us-central1"

echo "🚀 REANUDANDO INFRAESTRUCTURA OPTIMIZADA..."
echo ""

# Reanudar solo 1 pool con 2 nodos
echo "▶️  Reanudando monitoring-pool con 2 nodos..."
gcloud container clusters resize $CLUSTER_NAME \
    --node-pool=monitoring-pool-pool \
    --num-nodes=2 \
    --region=$REGION \
    --quiet

echo "✅ Infraestructura optimizada reanudada"
echo "📊 Servicios disponibles:"
echo "  - Jenkins: http://[EXTERNAL_IP]:8080"
echo "  - Grafana: http://[EXTERNAL_IP]:3000"
echo ""
echo "💰 Costo estimado: ~$120 USD/mes (vs $400 anterior)"