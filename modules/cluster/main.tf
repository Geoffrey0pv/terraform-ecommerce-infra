# Get available GKE versions
data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = var.gke_version_prefix
}

# Create GKE cluster
resource "google_container_cluster" "primary" {
  name                     = var.name
  location                 = var.region
  node_locations           = var.node_locations
  remove_default_node_pool = true
  initial_node_count       = 1
  network    = var.vpc_name
  subnetwork = var.subnet_name

  # Set GKE version to avoid version issues
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version

  # Use unspecified release channel for better control
  release_channel {
    channel = "UNSPECIFIED"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Default node configuration
  node_config {
    disk_type    = "pd-standard"
    disk_size_gb = 20
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled = true
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }
  }

  # Enable protection against accidental cluster deletion.
  # This will be temporarily disabled to allow the cluster to be recreated.
  deletion_protection = false
}