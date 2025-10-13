# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_id              = var.project_id
  region                  = var.region
  network_name            = var.network_name
  subnet_name             = var.subnet_name
  subnet_cidr             = var.subnet_cidr
  pods_cidr               = var.pods_cidr
  services_cidr           = var.services_cidr
  pods_range_name         = var.pods_range_name
  services_range_name     = var.services_range_name
}

# GKE Cluster Module
module "cluster" {
  source = "../../modules/cluster"

  project_id                 = var.project_id
  region                     = var.region
  name                       = var.cluster_name
  vpc_name                   = module.networking.network_name
  subnet_name                = var.subnet_name
  network_id                 = module.networking.network_id
  subnet_id                  = module.networking.subnet_id
  pods_range_name            = var.pods_range_name
  services_range_name        = var.services_range_name
  enable_private_nodes       = var.enable_private_nodes
  enable_private_endpoint    = var.enable_private_endpoint
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block

  depends_on = [module.networking]
}

# Node Pools Module
module "node_pools" {
  source = "../../modules/node_pools"

  project_id         = var.project_id
  region             = var.region
  cluster_name       = module.cluster.cluster_name
  stable_gke_version = module.cluster.stable_gke_version
  node_pools         = var.node_pools

  depends_on = [module.cluster]
}

# Namespaces Module
module "namespaces" {
  source = "../../modules/namespaces"

  namespaces = var.namespaces

  depends_on = [module.node_pools]
}