#!/bin/bash

# Script de gestión de recursos GKE
# Uso: ./manage-resources.sh [pause|resume|status|destroy] [environment]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ID="${PROJECT_ID:-ecommerce-backend-1760307199}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "Gestión de Recursos GKE"
    echo ""
    echo "Uso: $0 [ACCIÓN] [ENTORNO]"
    echo ""
    echo "ACCIONES:"
    echo "  pause     - Escala los node pools a 0 (pausa recursos)"
    echo "  resume    - Restaura los node pools al tamaño original"
    echo "  status    - Muestra el estado actual de clusters y nodos"
    echo "  destroy   - Destruye completamente la infraestructura"
    echo ""
    echo "ENTORNOS:"
    echo "  devops    - Entorno de desarrollo"
    echo "  staging   - Entorno de staging"
    echo "  prod      - Entorno de producción"
    echo ""
    echo "Ejemplos:"
    echo "  $0 status devops"
    echo "  $0 pause devops"
    echo "  $0 resume devops"
    echo "  $0 destroy devops"
}

# Función para obtener configuración del entorno
get_env_config() {
    local env=$1
    case $env in
        "devops")
            CLUSTER_NAME="ecommerce-devops-cluster"
            REGION="us-central1"
            TFVARS_FILE="terraform.devops.tfvars"
            ;;
        "staging")
            CLUSTER_NAME="ecommerce-staging-cluster"
            REGION="us-central1"
            TFVARS_FILE="terraform.staging.tfvars"
            ;;
        "prod")
            CLUSTER_NAME="ecommerce-prod-cluster"
            REGION="us-central1"
            TFVARS_FILE="terraform.prod.tfvars"
            ;;
        *)
            echo -e "${RED}Error: Entorno '$env' no válido${NC}"
            echo "Entornos válidos: devops, staging, prod"
            exit 1
            ;;
    esac
}

# Función para verificar si el cluster existe
cluster_exists() {
    local cluster_name=$1
    local region=$2
    
    if gcloud container clusters describe "$cluster_name" --region="$region" --project="$PROJECT_ID" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para mostrar estado
show_status() {
    local env=$1
    get_env_config "$env"
    
    echo -e "${BLUE}=== Estado de Recursos - Entorno: $env ===${NC}"
    
    if cluster_exists "$CLUSTER_NAME" "$REGION"; then
        echo -e "${GREEN}Cluster encontrado: $CLUSTER_NAME${NC}"
        
        # Mostrar información del cluster
        echo ""
        echo "Información del Cluster:"
        gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" \
            --format="table(name,status,currentMasterVersion,location,currentNodeCount)"
        
        echo ""
        echo "Node Pools:"
        gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" \
            --format="table(name,status,machineType,diskSizeGb,nodeCount,version)"
        
        # Calcular costo aproximado
        local total_nodes=$(gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(initialNodeCount)" | awk '{sum += $1} END {print sum}')
        local estimated_cost=$(echo "$total_nodes * 24 * 0.0475" | bc -l | xargs printf "%.2f")
        echo ""
        echo -e "${YELLOW}Costo estimado por día: \$${estimated_cost} USD (${total_nodes} nodos)${NC}"
        
    else
        echo -e "${RED}Cluster no encontrado: $CLUSTER_NAME${NC}"
        echo "Puede que esté destruido o no se haya creado aún."
    fi
}

# Función para pausar recursos
pause_resources() {
    local env=$1
    get_env_config "$env"
    
    echo -e "${YELLOW}Pausando recursos del entorno: $env${NC}"
    
    if ! cluster_exists "$CLUSTER_NAME" "$REGION"; then
        echo -e "${RED}Error: Cluster $CLUSTER_NAME no existe${NC}"
        exit 1
    fi
    
    # Obtener todos los node pools
    local node_pools=$(gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(name)")
    
    # Guardar configuración actual antes de pausar
    local config_file="${SCRIPT_DIR}/.${env}-node-config.tmp"
    echo "# Configuración de nodos guardada el $(date)" > "$config_file"
    
    for pool in $node_pools; do
        local current_size=$(gcloud container node-pools describe "$pool" --cluster="$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(initialNodeCount)")
        echo "${pool}=${current_size}" >> "$config_file"
        
        echo "Escalando node pool '$pool' de $current_size a 0 nodos..."
        gcloud container clusters resize "$CLUSTER_NAME" --node-pool="$pool" --num-nodes=0 --region="$REGION" --project="$PROJECT_ID" --quiet
    done
    
    echo -e "${GREEN}Recursos pausados exitosamente${NC}"
    echo -e "${BLUE}Para reanudar: $0 resume $env${NC}"
}

# Función para reanudar recursos
resume_resources() {
    local env=$1
    get_env_config "$env"
    
    echo -e "${YELLOW}Reanudando recursos del entorno: $env${NC}"
    
    if ! cluster_exists "$CLUSTER_NAME" "$REGION"; then
        echo -e "${RED}Error: Cluster $CLUSTER_NAME no existe${NC}"
        exit 1
    fi
    
    # Leer configuración guardada
    local config_file="${SCRIPT_DIR}/.${env}-node-config.tmp"
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: No se encontró configuración guardada${NC}"
        echo "Archivo esperado: $config_file"
        echo "Especifica manualmente el número de nodos o usa 'terraform apply'"
        exit 1
    fi
    
    echo "Restaurando configuración desde: $config_file"
    
    while IFS='=' read -r pool size; do
        # Saltar líneas de comentario
        [[ $pool =~ ^#.*$ ]] && continue
        [[ -z $pool ]] && continue
        
        echo "Escalando node pool '$pool' a $size nodos..."
        gcloud container clusters resize "$CLUSTER_NAME" --node-pool="$pool" --num-nodes="$size" --region="$REGION" --project="$PROJECT_ID" --quiet
    done < "$config_file"
    
    echo -e "${GREEN}Recursos reanudados exitosamente${NC}"
    
    # Limpiar archivo temporal
    rm -f "$config_file"
}

# Función para destruir recursos
destroy_resources() {
    local env=$1
    get_env_config "$env"
    
    echo -e "${RED}ADVERTENCIA: Esto destruirá completamente la infraestructura del entorno $env${NC}"
    echo -e "${YELLOW}Esta acción NO es reversible${NC}"
    echo ""
    
    read -p "¿Estás seguro? Escribe 'SI' para confirmar: " confirmation
    
    if [ "$confirmation" != "SI" ]; then
        echo "Destrucción cancelada"
        exit 0
    fi
    
    echo -e "${YELLOW}Destruyendo infraestructura...${NC}"
    
    # Cambiar al directorio del script para ejecutar terraform
    cd "$SCRIPT_DIR"
    
    terraform destroy -var-file="$TFVARS_FILE" -auto-approve
    
    # Limpiar archivos temporales
    rm -f ".${env}-node-config.tmp"
    
    echo -e "${GREEN}Infraestructura destruida exitosamente${NC}"
}

# Función principal
main() {
    if [ $# -lt 1 ]; then
        show_help
        exit 1
    fi
    
    local action=$1
    local env=${2:-"devops"}
    
    case $action in
        "help"|"-h"|"--help")
            show_help
            ;;
        "status")
            show_status "$env"
            ;;
        "pause")
            pause_resources "$env"
            ;;
        "resume")
            resume_resources "$env"
            ;;
        "destroy")
            destroy_resources "$env"
            ;;
        *)
            echo -e "${RED}Error: Acción '$action' no válida${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"