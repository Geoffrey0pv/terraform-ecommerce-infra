variable "project_id" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
  default     = "ecommerce-backend-1760307199"
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
  default     = "us-central1"
}

variable "node_locations" {
  description = "List of zones within the region where node pools will be created."
  type        = list(string)
  default     = ["us-central1-c"]
}

variable "repo_name" {
  description = "Name of the repository or project."
  type        = string
  default     = "ecommerce-devops"
}

variable "repo_description" {
  description = "Description for the repository or project."
  type        = string
  default     = "Infrastructure for ecommerce DevOps platform"
}

variable "node_pools" {
  description = "Map of node pool names to the number of nodes in each pool."
  type        = map(number)
  default     = {
    general-pool = 4  # Pool único optimizado para Jenkins + microservicios
  }
}

variable "namespaces" {
  description = "List of Kubernetes namespaces to be created in the cluster."
  type        = list(string)
  default     = [
    "tools",       # CI/CD tools (Jenkins)
    "staging",     # Staging environment
    "production"   # Production environment
  ]
}

variable "subnet_cidr" {
  description = "CIDR block for the VPC subnet."
  type        = string
  default     = "10.20.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR block for the Kubernetes pods network."
  type        = string
  default     = "10.21.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for the Kubernetes services network."
  type        = string
  default     = "10.22.0.0/20"
}
