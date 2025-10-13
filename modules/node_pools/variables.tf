variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region where node pools will be created"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "stable_gke_version" {
  description = "The GKE version to use for node pools"
  type        = string
}

variable "node_pools" {
  description = "Map of node pool names to the number of nodes in each pool"
  type        = map(number)
  default     = { default = 1 }
  
  validation {
    condition = alltrue([
      for k, v in var.node_pools : v >= 0 && v <= 20
    ])
    error_message = "Each pool size must be between 0 and 20 nodes."
  }
}
