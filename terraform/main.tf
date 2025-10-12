# Habilita la API de Kubernetes Engine en tu proyecto GCP
resource "google_project_service" "kubernetes" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

# Crea el clúster de Kubernetes (GKE)
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gcp_region

  # Queremos un clúster pequeño para no gastar los créditos
  initial_node_count       = 1
  remove_default_node_pool = true

  # Depende de que la API esté habilitada antes de intentar crear el clúster
  depends_on = [google_project_service.kubernetes]
}

# Define un "node pool" (grupo de máquinas virtuales) para nuestro clúster
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = 2 # Dos nodos para tener algo de redundancia

  node_config {
    # e2-medium es una máquina económica y suficiente para este taller
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}