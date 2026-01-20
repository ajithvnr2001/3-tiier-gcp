# infrastructure/gke.tf

# 1. The Control Plane
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region  
  
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # --- CRITICAL FIX: Make the default temporary pool small & HDD ---
  node_config {
    disk_type    = "pd-standard"  # Force HDD
    disk_size_gb = 30             # Minimum size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  # -------------------------------------------------------------

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-range"
    services_secondary_range_name = "gke-services-range"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  deletion_protection = false
}

# 2. The Worker Nodes
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.project_id}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    preemptible  = false
    spot         = true
    machine_type = "e2-standard-2"

    # --- LOW RESOURCE SETTINGS ---
    disk_size_gb = 30             # Reduced to 30GB
    disk_type    = "pd-standard"  # Standard HDD
    # -----------------------------

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    tags = ["gke-node", "${var.project_id}-gke"]
  }
}