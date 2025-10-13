#!/bin/bash

# Script de monitoreo completo de recursos GCP y Kubernetes
# Uso: ./monitor-all.sh [environment]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ID="${PROJECT_ID:-ecommerce-backend-1760307199}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar encabezado
show_header() {
    local title=$1
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$title${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para mostrar subencabezado
show_subheader() {
    local title=$1
    echo -e "\n${CYAN}--- $title ---${NC}"
}

# Función principal de monitoreo
monitor_all() {
    local env=${1:-"all"}
    
    show_header "MONITOREO COMPLETO DE RECURSOS GCP"
    echo -e "Proyecto: ${GREEN}$PROJECT_ID${NC}"
    echo -e "Fecha: ${YELLOW}$(date)${NC}"
    
    # 1. Clusters GKE
    show_subheader "CLUSTERS GKE"
    if gcloud container clusters list --format="table(name,status,currentNodeCount,location,currentMasterVersion)" 2>/dev/null; then
        echo -e "${GREEN}✓ Clusters encontrados${NC}"
    else
        echo -e "${RED}✗ No se pudieron listar clusters${NC}"
    fi
    
    # 2. Node pools detallados
    show_subheader "NODE POOLS DETALLADOS"
    local clusters=$(gcloud container clusters list --format="value(name,location)" 2>/dev/null)
    if [ -n "$clusters" ]; then
        while read -r cluster_info; do
            local cluster_name=$(echo $cluster_info | cut -d' ' -f1)
            local location=$(echo $cluster_info | cut -d' ' -f2)
            echo -e "\n${YELLOW}Cluster: $cluster_name (Región: $location)${NC}"
            gcloud container node-pools list --cluster="$cluster_name" --region="$location" --format="table(name,status,machineType,diskSizeGb,initialNodeCount,version)" 2>/dev/null || echo "  No se pudieron obtener node pools"
        done <<< "$clusters"
    else
        echo -e "${RED}No hay clusters para mostrar node pools${NC}"
    fi
    
    # 3. Instancias de Compute Engine
    show_subheader "INSTANCIAS DE COMPUTE ENGINE"
    if gcloud compute instances list --format="table(name,zone,machineType,status,preemptible,creationTimestamp)" 2>/dev/null; then
        echo -e "${GREEN}✓ Instancias listadas${NC}"
    else
        echo -e "${YELLOW}⚠ No hay instancias de compute o error al obtenerlas${NC}"
    fi
    
    # 4. Redes VPC
    show_subheader "REDES VPC"
    if gcloud compute networks list --format="table(name,subnet_mode,bgp_routing_mode)" 2>/dev/null; then
        echo -e "${GREEN}✓ Redes VPC listadas${NC}"
    else
        echo -e "${RED}✗ Error al obtener redes VPC${NC}"
    fi
    
    # 5. Subnets
    show_subheader "SUBNETS"
    if gcloud compute networks subnets list --format="table(name,region,network,range,purpose)" 2>/dev/null; then
        echo -e "${GREEN}✓ Subnets listadas${NC}"
    else
        echo -e "${RED}✗ Error al obtener subnets${NC}"
    fi
    
    # 6. Discos persistentes
    show_subheader "DISCOS PERSISTENTES"
    if gcloud compute disks list --format="table(name,zone,sizeGb,type,status)" 2>/dev/null; then
        echo -e "${GREEN}✓ Discos listados${NC}"
    else
        echo -e "${YELLOW}⚠ No hay discos persistentes o error al obtenerlos${NC}"
    fi
    
    # 7. Service Accounts
    show_subheader "SERVICE ACCOUNTS"
    if gcloud iam service-accounts list --format="table(email,displayName,disabled)" 2>/dev/null; then
        echo -e "${GREEN}✓ Service accounts listadas${NC}"
    else
        echo -e "${RED}✗ Error al obtener service accounts${NC}"
    fi
    
    # 8. Estado de Terraform
    show_subheader "ESTADO DE TERRAFORM"
    if [ -f "$SCRIPT_DIR/terraform.tfstate" ]; then
        local resource_count=$(terraform state list 2>/dev/null | wc -l)
        echo -e "Recursos en estado: ${GREEN}$resource_count${NC}"
        echo "Últimos 5 recursos:"
        terraform state list 2>/dev/null | tail -5 | sed 's/^/  /'
    else
        echo -e "${YELLOW}⚠ No se encontró archivo de estado de Terraform${NC}"
    fi
    
    # 9. Kubernetes (si hay contexto activo)
    show_subheader "RECURSOS DE KUBERNETES"
    if kubectl config current-context >/dev/null 2>&1; then
        echo -e "Contexto actual: ${GREEN}$(kubectl config current-context)${NC}"
        
        echo -e "\n${CYAN}Nodos:${NC}"
        kubectl get nodes -o wide 2>/dev/null || echo "  Error al obtener nodos"
        
        echo -e "\n${CYAN}Namespaces:${NC}"
        kubectl get namespaces 2>/dev/null | grep -v "gke-\|gmp-\|kube-" || echo "  Error al obtener namespaces"
        
        echo -e "\n${CYAN}Pods en namespaces personalizados:${NC}"
        local custom_ns=$(kubectl get namespaces -o name 2>/dev/null | grep -v "namespace/default\|namespace/gke-\|namespace/gmp-\|namespace/kube-" | sed 's/namespace\///')
        if [ -n "$custom_ns" ]; then
            while read -r ns; do
                local pod_count=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
                echo "  $ns: $pod_count pods"
            done <<< "$custom_ns"
        else
            echo "  No hay namespaces personalizados con pods"
        fi
    else
        echo -e "${YELLOW}⚠ No hay contexto activo de kubectl${NC}"
    fi
    
    # 10. Cálculo de costos estimados
    show_subheader "ESTIMACIÓN DE COSTOS"
    local total_nodes=0
    local total_disks=0
    
    # Contar nodos activos
    if command -v gcloud >/dev/null 2>&1; then
        total_nodes=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep -c "gke-" || echo "0")
        total_disks=$(gcloud compute disks list --format="value(sizeGb)" 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    local cost_per_node_day=1.14  # n1-standard-1 aproximado
    local cost_per_gb_disk_day=0.04
    local control_plane_cost_day=2.40
    
    local nodes_cost=$(echo "$total_nodes * $cost_per_node_day" | bc -l 2>/dev/null || echo "0")
    local disks_cost=$(echo "$total_disks * $cost_per_gb_disk_day" | bc -l 2>/dev/null || echo "0")
    local total_daily_cost=$(echo "$nodes_cost + $disks_cost + $control_plane_cost_day" | bc -l 2>/dev/null || echo "0")
    local monthly_cost=$(echo "$total_daily_cost * 30" | bc -l 2>/dev/null || echo "0")
    
    echo -e "Nodos activos: ${YELLOW}$total_nodes${NC}"
    echo -e "Almacenamiento total: ${YELLOW}${total_disks}GB${NC}"
    echo -e "Costo estimado diario: ${GREEN}\$$(printf "%.2f" $total_daily_cost) USD${NC}"
    echo -e "Costo estimado mensual: ${GREEN}\$$(printf "%.2f" $monthly_cost) USD${NC}"
    
    # 11. Recomendaciones
    show_subheader "RECOMENDACIONES"
    if [ "$total_nodes" -gt 0 ]; then
        echo -e "${YELLOW}💡 Tienes $total_nodes nodos corriendo${NC}"
        echo -e "   Para pausar recursos: ${CYAN}./manage-resources.sh pause <env>${NC}"
        echo -e "   Para ver estado detallado: ${CYAN}./manage-resources.sh status <env>${NC}"
    else
        echo -e "${GREEN}✓ No tienes nodos corriendo (recursos pausados)${NC}"
        echo -e "   Para reanudar: ${CYAN}./manage-resources.sh resume <env>${NC}"
    fi
    
    if [ "$total_daily_cost" != "0" ] && [ "$(echo "$total_daily_cost > 5" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
        echo -e "${RED}⚠ Costo diario alto (>\$5). Considera pausar recursos cuando no los uses.${NC}"
    fi
    
    show_header "MONITOREO COMPLETADO"
    echo -e "Para comandos específicos, consulta: ${CYAN}./manage-resources.sh help${NC}"
}

# Ejecutar función principal
monitor_all "$@"