# Staging Environment Configuration
project_id   = "ecommerce-backend-1760307199"
region       = "us-central1"
cluster_name = "ecommerce-staging-cluster"

# Network Configuration
network_name        = "ecommerce-staging-vpc"
subnet_name         = "ecommerce-staging-subnet"
subnet_cidr         = "10.20.0.0/24"
pods_cidr           = "10.21.0.0/16"
services_cidr       = "10.22.0.0/16"
pods_range_name     = "staging-pods-range"
services_range_name = "staging-services-range"

# Private cluster settings
enable_private_nodes    = true
enable_private_endpoint = false
master_ipv4_cidr_block  = "172.16.1.0/28"

# Node pools for Staging
node_pools = [
  {
    name               = "staging-pool"
    machine_type       = "e2-medium"
    node_count         = 2
    min_node_count     = 1
    max_node_count     = 4
    disk_size_gb       = 20
    disk_type          = "pd-standard"
    image_type         = "COS_CONTAINERD"
    auto_repair        = true
    auto_upgrade       = true
    preemptible        = false
    oauth_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = {
      environment = "staging"
      team        = "backend"
    }
    tags   = ["staging", "backend"]
    taints = []
  }
]

# Namespaces for Staging environment
namespaces = ["staging", "backend-services", "frontend", "database"]