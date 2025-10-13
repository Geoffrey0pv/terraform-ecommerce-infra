variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "pods_cidr" {
  description = "The CIDR block for pods"
  type        = string
}

variable "services_cidr" {
  description = "The CIDR block for services"
  type        = string
}

variable "pods_range_name" {
  description = "The name of the pods IP range"
  type        = string
}

variable "services_range_name" {
  description = "The name of the services IP range"
  type        = string
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The CIDR block for the master network"
  type        = string
  default     = null
}

variable "node_pools" {
  description = "Node pools configuration"
  type        = map(number)
  default     = {}
}

variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
  default     = []
}