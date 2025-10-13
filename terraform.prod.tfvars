credentials_file = "terraform-sa-key.json"
project_id       = "ecommerce-backend-1760307199"
region           = "us-central1"
node_locations   = ["us-central1-c"]
repo_name        = "ecommerce-prod"
# CIDR ranges for production environment
subnet_cidr      = "10.100.0.0/20"
pods_cidr        = "10.101.0.0/16"
services_cidr    = "10.102.0.0/20"

node_pools = {
  core       = 2
  backend    = 4
  database   = 1
  monitoring = 1
}

namespaces = [
  "core",
  "backend", 
  "database",
  "monitoring"
]