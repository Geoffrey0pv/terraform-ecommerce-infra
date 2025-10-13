# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "ecommerce-backend-1760307199"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "ecommerce-cluster"
}

variable "node_locations" {
  description = "List of zones within the region where node pools will be created"
  type        = list(string)
  default     = ["us-central1-c"]
}

variable "gke_version_prefix" {
  description = "GKE version prefix"
  type        = string
  default     = "1.27"
}

# Network Configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "ecommerce-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "ecommerce-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.11.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.12.0.0/16"
}

variable "pods_range_name" {
  description = "Name of the pods secondary IP range"
  type        = string
  default     = "pods-range"
}

variable "services_range_name" {
  description = "Name of the services secondary IP range"
  type        = string
  default     = "services-range"
}

# Private cluster configuration
variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master network"
  type        = string
  default     = "172.16.0.0/28"
}

# Node pools configuration - simplified
variable "node_pools" {
  description = "Map of node pool names to the number of nodes in each pool"
  type        = map(number)
  default     = { testing = 1 }
  
  validation {
    condition = alltrue([
      for k, v in var.node_pools : v >= 0 && v <= 20
    ])
    error_message = "Each pool size must be between 0 and 20 nodes."
  }
}

# Namespaces configuration
variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
  default     = ["devops", "staging", "production"]
}
