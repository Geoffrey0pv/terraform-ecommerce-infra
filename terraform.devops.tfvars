credentials_file = "terraform-sa-key.json"
project_id       = "ecommerce-backend-1760307199"
region           = "us-central1"
node_locations   = ["us-central1-a"]
repo_name        = "ecommerce-devops"
# CIDR ranges for devops environment
subnet_cidr      = "10.20.0.0/20"
pods_cidr        = "10.21.0.0/16"
services_cidr    = "10.22.0.0/20"

node_pools = {
  security   = 1
  elk        = 1
  database   = 1
  monitoring = 1
}

namespaces = [
  "security",
  "elk", 
  "database",
  "monitoring",
  "tools",
  "ingress-nginx"
]

# Contraseña para Jenkins (sensible, no la subas a git en un proyecto real)
jenkins_admin_password = "MiPasswordSeguroParaJenkins2025!"