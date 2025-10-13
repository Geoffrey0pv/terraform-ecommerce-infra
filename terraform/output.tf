# Project Information
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region where resources are deployed"
  value       = var.region
}

output "environment" {
  description = "The current environment"
  value       = terraform.workspace
}

# Network Outputs
output "network_name" {
  description = "The name of the VPC network"
  value       = module.networking.network_name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = module.networking.network_id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = module.networking.subnet_name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = module.networking.subnet_id
}

# Cluster Outputs
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = module.cluster.cluster_ca
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.cluster.location
}

# Service Account Outputs
output "gke_service_account_email" {
  description = "The email of the GKE service account"
  value       = google_service_account.gke_service_account.email
}

# Connection Command
output "kubectl_connection_command" {
  description = "Command to connect to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.cluster.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# Namespaces
output "created_namespaces" {
  description = "List of created Kubernetes namespaces"
  value       = module.namespaces.namespace_names
}
