variable "project_id" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
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
  default     = "name"
}

variable "repo_description" {
  description = "Description for the repository or project."
  type        = string
  default     = "desc"
}

variable "node_pools" {
  description = "Map of node pool names to the number of nodes in each pool."
  type        = map(number)
  default     = { testing = 1 }
}

variable "namespaces" {
  description = "List of Kubernetes namespaces to be created in the cluster."
  type        = list(string)
  default     = ["testing"]
}

variable "credentials_file" {
  description = "Path to the service account credentials JSON file."
  type        = string
  default     = "terraform-key.json"
}

variable "subnet_cidr" {
  description = "CIDR block for the VPC subnet."
  type        = string
}

variable "pods_cidr" {
  description = "CIDR block for the Kubernetes pods network."
  type        = string
}

variable "services_cidr" {
  description = "CIDR block for the Kubernetes services network."
  type        = string
}
