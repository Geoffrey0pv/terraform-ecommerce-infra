# Configuración de Infraestructura GKE - E-commerce
# Última actualización: 27 Oct 2025

# Google Cloud Project
project_id = "ecommerce-backend-1760307199"
region     = "us-central1"

# Node Locations (zonas dentro de la región)
node_locations = ["us-central1-c"]

# Repositorio/Proyecto
repo_name        = "ecommerce-devops"
repo_description = "Infrastructure for ecommerce DevOps platform"

# Node Pools - Configuración optimizada
# Pool único con 4 nodos e2-standard-2 (2 vCPU, 8 GB RAM cada uno)
# Total: 8 vCPUs, 32 GB RAM
node_pools = {
  general-pool = 4  # Para Jenkins + staging + production
}

# Namespaces de Kubernetes
namespaces = [
  "tools",      # CI/CD (Jenkins)
  "staging",    # Entorno de staging
  "production"  # Entorno de producción
]

# Configuración de Red
subnet_cidr    = "10.20.0.0/20"  # 4,096 IPs para VPC
pods_cidr      = "10.21.0.0/16"  # 65,536 IPs para Pods
services_cidr  = "10.22.0.0/20"  # 4,096 IPs para Services
