variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "node_locations" {
  description = "List of zones where nodes can be created"
  type        = list(string)
  default     = []
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the pods secondary range"
  type        = string
}

variable "services_range_name" {
  description = "Name of the services secondary range"
  type        = string
}

variable "gke_version_prefix" {
  description = "Prefix for GKE version"
  type        = string
  default     = "1.32."
}

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

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}