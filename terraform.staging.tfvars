credentials_file = "terraform-sa-key.json"
project_id       = "ecommerce-backend-1760307199"
region           = "us-central1"
node_locations   = ["us-central1-b"]
repo_name        = "ecommerce-staging"
# CIDR ranges for staging environment
subnet_cidr      = "10.10.0.0/20"
pods_cidr        = "10.11.0.0/16"
services_cidr    = "10.12.0.0/20"

node_pools = {
  core       = 1
  backend    = 2
  database   = 1
  monitoring = 1
}

namespaces = [
  "core",
  "backend",
  "database",
  "monitoring"
]