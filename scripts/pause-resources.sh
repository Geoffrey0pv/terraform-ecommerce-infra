#!/bin/bash

# Script para pausar recursos y ahorrar costos
# Uso: ./pause-resources.sh [environment] [action]
# Actions: pause, resume, status

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

# Función para pausar recursos
pause_resources() {
    local env=${1:-"devops"}
    
    show_header "PAUSANDO RECURSOS - AMBIENTE: $env"
    echo -e "Proyecto: ${GREEN}$PROJECT_ID${NC}"
    echo -e "Fecha: ${YELLOW}$(date)${NC}"
    
    # 1. Reducir node pools a 0 nodos
    show_subheader "PAUSANDO NODE POOLS"
    local clusters=$(gcloud container clusters list --format="value(name,location)" 2>/dev/null)
    if [ -n "$clusters" ]; then
        while read -r cluster_info; do
            local cluster_name=$(echo $cluster_info | cut -d' ' -f1)
            local location=$(echo $cluster_info | cut -d' ' -f2)
            
            if [[ "$cluster_name" == *"$env"* ]]; then
                echo -e "Pausando cluster: ${YELLOW}$cluster_name${NC}"
                
                # Obtener node pools del cluster
                local node_pools=$(gcloud container node-pools list --cluster="$cluster_name" --region="$location" --format="value(name)" 2>/dev/null)
                if [ -n "$node_pools" ]; then
                    while read -r pool_name; do
                        echo -e "  Reduciendo node pool: ${CYAN}$pool_name${NC} a 0 nodos"
                        gcloud container clusters resize "$cluster_name" \
                            --node-pool="$pool_name" \
                            --num-nodes=0 \
                            --region="$location" \
                            --quiet 2>/dev/null || echo "    Error al pausar $pool_name"
                    done <<< "$node_pools"
                fi
            fi
        done <<< "$clusters"
    else
        echo -e "${YELLOW}No se encontraron clusters para pausar${NC}"
    fi
    
    # 2. Pausar instancias de Compute Engine (si las hay)
    show_subheader "PAUSANDO INSTANCIAS DE COMPUTE ENGINE"
    local instances=$(gcloud compute instances list --format="value(name,zone)" 2>/dev/null | grep -v "gke-" || true)
    if [ -n "$instances" ]; then
        while read -r instance_info; do
            local instance_name=$(echo $instance_info | cut -d' ' -f1)
            local zone=$(echo $instance_info | cut -d' ' -f2)
            echo -e "Pausando instancia: ${YELLOW}$instance_name${NC}"
            gcloud compute instances stop "$instance_name" --zone="$zone" --quiet 2>/dev/null || echo "  Error al pausar $instance_name"
        done <<< "$instances"
    else
        echo -e "${GREEN}No hay instancias de Compute Engine para pausar${NC}"
    fi
    
    # 3. Mostrar ahorro estimado
    show_subheader "AHORRO ESTIMADO"
    local daily_savings=10.00  # Estimación basada en 4 nodos n1-standard-1
    local monthly_savings=$(echo "$daily_savings * 30" | bc -l 2>/dev/null || echo "300")
    
    echo -e "Ahorro diario estimado: ${GREEN}\$$(printf "%.2f" $daily_savings) USD${NC}"
    echo -e "Ahorro mensual estimado: ${GREEN}\$$(printf "%.2f" $monthly_savings) USD${NC}"
    
    show_header "RECURSOS PAUSADOS"
    echo -e "Para reanudar recursos: ${CYAN}./pause-resources.sh resume $env${NC}"
    echo -e "Para ver estado: ${CYAN}./pause-resources.sh status $env${NC}"
}

# Función para reanudar recursos
resume_resources() {
    local env=${1:-"devops"}
    
    show_header "REANUDANDO RECURSOS - AMBIENTE: $env"
    echo -e "Proyecto: ${GREEN}$PROJECT_ID${NC}"
    echo -e "Fecha: ${YELLOW}$(date)${NC}"
    
    # 1. Reanudar node pools
    show_subheader "REANUDANDO NODE POOLS"
    local clusters=$(gcloud container clusters list --format="value(name,location)" 2>/dev/null)
    if [ -n "$clusters" ]; then
        while read -r cluster_info; do
            local cluster_name=$(echo $cluster_info | cut -d' ' -f1)
            local location=$(echo $cluster_info | cut -d' ' -f2)
            
            if [[ "$cluster_name" == *"$env"* ]]; then
                echo -e "Reanudando cluster: ${YELLOW}$cluster_name${NC}"
                
                # Obtener node pools del cluster
                local node_pools=$(gcloud container node-pools list --cluster="$cluster_name" --region="$location" --format="value(name)" 2>/dev/null)
                if [ -n "$node_pools" ]; then
                    while read -r pool_name; do
                        # Determinar número de nodos basándose en el nombre del pool
                        local node_count=1
                        if [[ "$pool_name" == *"backend"* ]]; then
                            node_count=2
                        elif [[ "$pool_name" == *"core"* ]]; then
                            node_count=1
                        fi
                        
                        echo -e "  Reanudando node pool: ${CYAN}$pool_name${NC} a $node_count nodos"
                        gcloud container clusters resize "$cluster_name" \
                            --node-pool="$pool_name" \
                            --num-nodes=$node_count \
                            --region="$location" \
                            --quiet 2>/dev/null || echo "    Error al reanudar $pool_name"
                    done <<< "$node_pools"
                fi
            fi
        done <<< "$clusters"
    else
        echo -e "${YELLOW}No se encontraron clusters para reanudar${NC}"
    fi
    
    # 2. Reanudar instancias de Compute Engine (si las hay)
    show_subheader "REANUDANDO INSTANCIAS DE COMPUTE ENGINE"
    local instances=$(gcloud compute instances list --format="value(name,zone)" 2>/dev/null | grep -v "gke-" || true)
    if [ -n "$instances" ]; then
        while read -r instance_info; do
            local instance_name=$(echo $instance_info | cut -d' ' -f1)
            local zone=$(echo $instance_info | cut -d' ' -f2)
            echo -e "Reanudando instancia: ${YELLOW}$instance_name${NC}"
            gcloud compute instances start "$instance_name" --zone="$zone" --quiet 2>/dev/null || echo "  Error al reanudar $instance_name"
        done <<< "$instances"
    else
        echo -e "${GREEN}No hay instancias de Compute Engine para reanudar${NC}"
    fi
    
    show_header "RECURSOS REANUDADOS"
    echo -e "Para pausar recursos: ${CYAN}./pause-resources.sh pause $env${NC}"
    echo -e "Para ver estado: ${CYAN}./pause-resources.sh status $env${NC}"
}

# Función para mostrar estado
show_status() {
    local env=${1:-"devops"}
    
    show_header "ESTADO DE RECURSOS - AMBIENTE: $env"
    echo -e "Proyecto: ${GREEN}$PROJECT_ID${NC}"
    echo -e "Fecha: ${YELLOW}$(date)${NC}"
    
    # 1. Estado de clusters
    show_subheader "ESTADO DE CLUSTERS"
    local clusters=$(gcloud container clusters list --format="value(name,status,currentNodeCount,location)" 2>/dev/null)
    if [ -n "$clusters" ]; then
        while read -r cluster_info; do
            local cluster_name=$(echo $cluster_info | cut -d' ' -f1)
            local status=$(echo $cluster_info | cut -d' ' -f2)
            local node_count=$(echo $cluster_info | cut -d' ' -f3)
            local location=$(echo $cluster_info | cut -d' ' -f4)
            
            if [[ "$cluster_name" == *"$env"* ]]; then
                if [ "$node_count" -eq 0 ]; then
                    echo -e "Cluster: ${YELLOW}$cluster_name${NC} - ${RED}PAUSADO${NC} (0 nodos)"
                else
                    echo -e "Cluster: ${YELLOW}$cluster_name${NC} - ${GREEN}ACTIVO${NC} ($node_count nodos)"
                fi
            fi
        done <<< "$clusters"
    else
        echo -e "${YELLOW}No se encontraron clusters${NC}"
    fi
    
    # 2. Estado de instancias
    show_subheader "ESTADO DE INSTANCIAS"
    local instances=$(gcloud compute instances list --format="value(name,zone,status)" 2>/dev/null | grep -v "gke-" || true)
    if [ -n "$instances" ]; then
        while read -r instance_info; do
            local instance_name=$(echo $instance_info | cut -d' ' -f1)
            local zone=$(echo $instance_info | cut -d' ' -f2)
            local status=$(echo $instance_info | cut -d' ' -f3)
            
            if [ "$status" = "RUNNING" ]; then
                echo -e "Instancia: ${YELLOW}$instance_name${NC} - ${GREEN}ACTIVA${NC}"
            else
                echo -e "Instancia: ${YELLOW}$instance_name${NC} - ${RED}PAUSADA${NC}"
            fi
        done <<< "$instances"
    else
        echo -e "${GREEN}No hay instancias de Compute Engine${NC}"
    fi
    
    # 3. Costos actuales
    show_subheader "COSTOS ACTUALES"
    local total_nodes=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep -c "gke-" || echo "0")
    local cost_per_node_day=1.14
    local daily_cost=$(echo "$total_nodes * $cost_per_node_day" | bc -l 2>/dev/null || echo "0")
    local monthly_cost=$(echo "$daily_cost * 30" | bc -l 2>/dev/null || echo "0")
    
    echo -e "Nodos activos: ${YELLOW}$total_nodes${NC}"
    echo -e "Costo diario: ${GREEN}\$$(printf "%.2f" $daily_cost) USD${NC}"
    echo -e "Costo mensual: ${GREEN}\$$(printf "%.2f" $monthly_cost) USD${NC}"
    
    if [ "$total_nodes" -eq 0 ]; then
        echo -e "${GREEN}✓ Todos los recursos están pausados - Ahorrando costos${NC}"
    else
        echo -e "${YELLOW}⚠ Tienes $total_nodes nodos activos - Generando costos${NC}"
    fi
}

# Función de ayuda
show_help() {
    echo -e "${BLUE}Script para Pausar/Reanudar Recursos${NC}"
    echo -e ""
    echo -e "${CYAN}Uso:${NC}"
    echo -e "  ./pause-resources.sh [environment] [action]"
    echo -e ""
    echo -e "${CYAN}Ambientes disponibles:${NC}"
    echo -e "  devops    - Ambiente de DevOps"
    echo -e "  staging   - Ambiente de Staging"
    echo -e "  production - Ambiente de Producción"
    echo -e ""
    echo -e "${CYAN}Acciones disponibles:${NC}"
    echo -e "  pause     - Pausar recursos (reducir a 0 nodos)"
    echo -e "  resume    - Reanudar recursos (restaurar nodos)"
    echo -e "  status    - Mostrar estado actual"
    echo -e "  help      - Mostrar esta ayuda"
    echo -e ""
    echo -e "${CYAN}Ejemplos:${NC}"
    echo -e "  ./pause-resources.sh devops pause"
    echo -e "  ./pause-resources.sh staging resume"
    echo -e "  ./pause-resources.sh production status"
    echo -e ""
    echo -e "${YELLOW}Nota: Pausar recursos puede ahorrar hasta \$300+ USD mensuales${NC}"
}

# Función principal
main() {
    local action=${1:-"help"}
    local env=${2:-"devops"}
    
    case $action in
        "pause")
            pause_resources "$env"
            ;;
        "resume")
            resume_resources "$env"
            ;;
        "status")
            show_status "$env"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
