variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR block for pods secondary range"
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for services secondary range"
  type        = string
  default     = "10.30.0.0/16"
}

variable "pods_range_name" {
  description = "Name for pods secondary range"
  type        = string
  default     = "pods-secondary-range"
}

variable "services_range_name" {
  description = "Name for services secondary range"
  type        = string
  default     = "services-secondary-range"
}