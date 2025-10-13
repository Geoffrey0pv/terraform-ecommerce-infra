# DevOps Environment Configuration
project_id     = "ecommerce-backend-1760307199"
region         = "us-central1"
node_locations = ["us-central1-c"]
cluster_name   = "ecommerce-devops-cluster"

# Network Configuration
network_name        = "ecommerce-devops-vpc"
subnet_name         = "ecommerce-devops-subnet"
subnet_cidr         = "10.10.0.0/24"
pods_cidr           = "10.11.0.0/16"
services_cidr       = "10.12.0.0/16"
pods_range_name     = "devops-pods-range" 
services_range_name = "devops-services-range"

# Private cluster settings (disabled for DevOps environment for easier access)
enable_private_nodes    = false
enable_private_endpoint = false

# Node pools for DevOps (simplified structure using map)
node_pools = {
  devops = 1
}

# Namespaces for DevOps environment
namespaces = ["devops", "monitoring", "ci-cd", "tools"]