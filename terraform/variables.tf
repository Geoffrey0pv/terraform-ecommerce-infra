variable "gcp_project_id" {
  description = "El ID de tu proyecto en GCP."
  type        = string
  default     = "ecommerce-backend-1760307199"
}

variable "gcp_region" {
  description = "La región donde se desplegarán los recursos."
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "El nombre para el clúster de Kubernetes."
  type        = string
  default     = "ecommerce-cluster"
}

variable "gke_node_count" {
  description = "Número de nodos en el node pool."
  type        = number
  default     = 2
}

variable "network_name" {
  description = "Nombre de la red VPC."
  type        = string
  default     = "ecommerce-vpc"
}
