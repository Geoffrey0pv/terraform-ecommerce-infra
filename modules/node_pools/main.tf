# Separately Managed Node Pools
resource "google_container_node_pool" "node_pools" {
  for_each = var.node_pools

  name       = "${each.key}-pool"
  location   = var.region
  cluster    = var.cluster_name
  node_count = each.value

  version = var.stable_gke_version

  # Management - auto_repair true, auto_upgrade false to avoid version issues
  management {
    auto_repair  = true
    auto_upgrade = false
  }

  # Node configuration
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env  = var.project_id
      role = each.key
    }

    preemptible  = false
    disk_size_gb = 30
    disk_type    = "pd-standard"
    machine_type = "e2-standard-2"  # 2 vCPU, 8GB RAM - más eficiente para Jenkins + microservicios
    tags         = ["gke-node", "${var.project_id}-gke", "gke-${each.key}-pool"]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
