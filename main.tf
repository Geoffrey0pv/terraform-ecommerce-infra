terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get cluster info for kubernetes provider
data "google_container_cluster" "primary" {
  name     = module.cluster.cluster_name
  location = var.region
  depends_on = [module.cluster]
}

# Provider para Kubernetes - Se autentica usando la información del cluster GKE
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

# Provider para Helm - Usa la configuración del provider de Kubernetes
provider "helm" {
  kubernetes {
    host                   = data.google_container_cluster.primary.endpoint
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

# Data source para obtener el token de autenticación de gcloud
data "google_client_config" "default" {}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_id      = var.project_id
  region          = var.region
  network_name    = "${var.repo_name}-vpc"
  subnet_name     = "${var.repo_name}-subnet"
  subnet_cidr     = var.subnet_cidr
  pods_cidr       = var.pods_cidr
  services_cidr   = var.services_cidr
  pods_range_name = "pods-range"
  services_range_name = "services-range"
}

# GKE Cluster Module
module "cluster" {
  source = "./modules/cluster"

  project_id                 = var.project_id
  region                     = var.region
  name                       = "${var.repo_name}-cluster"
  vpc_name                   = module.networking.network_name
  subnet_name                = module.networking.subnet_name
  network_id                 = module.networking.network_id
  subnet_id                  = module.networking.subnet_id
  node_locations             = var.node_locations
  pods_range_name            = "pods-range"
  services_range_name        = "services-range"
  enable_private_nodes       = true
  enable_private_endpoint    = false
  master_ipv4_cidr_block     = "172.16.0.0/28"

  depends_on = [module.networking]
}

# Node Pools Module  
module "node_pools" {
  source = "./modules/node_pools"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = module.cluster.cluster_name
  stable_gke_version  = module.cluster.stable_gke_version
  node_pools          = var.node_pools

  depends_on = [module.cluster]
}

# Namespaces Module
module "namespaces" {
  source = "./modules/namespaces"

  namespaces = var.namespaces

  depends_on = [module.node_pools]
}

# ------------------------------------------------------------------------------
# PLATFORM APPLICATIONS (HELM)
# ------------------------------------------------------------------------------

module "platform_apps" {
  source = "./modules/platform_apps"

  # Variables para Jenkins
  jenkins_admin_password = var.jenkins_admin_password
  jenkins_namespace      = "tools" # Desplegamos en el namespace 'tools'

  # Variables para NGINX Ingress
  ingress_namespace = "ingress-nginx"

  # Asegurarnos de que los namespaces existan antes de desplegar
  namespace_dependency = module.namespaces.namespace_names
}