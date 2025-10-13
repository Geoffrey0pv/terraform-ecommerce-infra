# Production Environment Configuration
project_id   = "ecommerce-backend-1760307199"
region       = "us-central1"
cluster_name = "ecommerce-prod-cluster"

# Multi-zone for high availability
node_locations = ["us-central1-b", "us-central1-c"]

# Network Configuration
network_name        = "ecommerce-prod-vpc"
subnet_name         = "ecommerce-prod-subnet"
subnet_cidr         = "10.30.0.0/24"
pods_cidr           = "10.31.0.0/16"
services_cidr       = "10.32.0.0/16"
pods_range_name     = "prod-pods-range"
services_range_name = "prod-services-range"

# Private cluster settings (fully private for security)
enable_private_nodes    = true
enable_private_endpoint = true
master_ipv4_cidr_block  = "172.16.2.0/28"

# Node pools for Production
node_pools = [
  {
    name               = "prod-web-pool"
    machine_type       = "e2-standard-2"
    node_count         = 3
    min_node_count     = 2
    max_node_count     = 6
    disk_size_gb       = 50
    disk_type          = "pd-ssd"
    image_type         = "COS_CONTAINERD"
    auto_repair        = true
    auto_upgrade       = false
    preemptible        = false
    oauth_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = {
      environment = "production"
      tier        = "web"
      team        = "backend"
    }
    tags = ["production", "web", "backend"]
    taints = []
  },
  {
    name               = "prod-db-pool"
    machine_type       = "e2-highmem-2"
    node_count         = 2
    min_node_count     = 1
    max_node_count     = 3
    disk_size_gb       = 100
    disk_type          = "pd-ssd"
    image_type         = "COS_CONTAINERD"
    auto_repair        = true
    auto_upgrade       = false
    preemptible        = false
    oauth_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = {
      environment = "production"
      tier        = "database"
      team        = "backend"
    }
    tags = ["production", "database", "backend"]
    taints = [
      {
        key    = "database"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
]

# Namespaces for Production environment
namespaces = ["production", "backend-services", "frontend", "database", "monitoring", "logging"]