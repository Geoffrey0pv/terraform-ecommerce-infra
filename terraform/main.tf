# Configure Terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com"
  ])
  
  service            = each.key
  disable_on_destroy = false
  project            = var.project_id
}

# Create service account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.cluster_name}-sa"
  display_name = "GKE Service Account for ${var.cluster_name}"
  project      = var.project_id
}

# Assign necessary roles to the service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Networking module
module "networking" {
  source = "./modules/networking"
  
  project_id          = var.project_id
  region              = var.region
  network_name        = var.network_name
  subnet_name         = var.subnet_name
  subnet_cidr         = var.subnet_cidr
  pods_cidr           = var.pods_cidr
  services_cidr       = var.services_cidr
  pods_range_name     = var.pods_range_name
  services_range_name = var.services_range_name
  
  depends_on = [google_project_service.apis]
}

# Cluster module
module "cluster" {
  source = "./modules/cluster"
  
  project_id             = var.project_id
  name                   = var.cluster_name
  region                 = var.region
  node_locations         = var.node_locations
  vpc_name               = module.networking.network_name
  subnet_name            = module.networking.subnet_name
  network_id             = module.networking.network_id
  subnet_id              = module.networking.subnet_id
  pods_range_name        = module.networking.pods_range_name
  services_range_name    = module.networking.services_range_name
  gke_version_prefix     = var.gke_version_prefix
  enable_private_nodes   = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  
  depends_on = [module.networking]
}

# Node pools module
module "node_pools" {
  source = "./modules/node_pools"
  
  region             = var.region
  project_id         = var.project_id
  stable_gke_version = module.cluster.stable_gke_version
  cluster_name       = module.cluster.cluster_name
  node_pools         = var.node_pools
  
  depends_on = [module.cluster]
}

# Namespaces module  
module "namespaces" {
  source = "./modules/namespaces"
  
  namespaces = var.namespaces
  
  depends_on = [module.node_pools]
}