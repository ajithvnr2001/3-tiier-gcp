# infrastructure/gke.tf

# 1. The Control Plane (The Brain)
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region  # Regional Cluster (HA) - runs in 3 zones!
  
  # We delete the default node pool because we want a custom one with Spot VMs
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # VPC-Native Networking (Crucial for performance)
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-range"
    services_secondary_range_name = "gke-services-range"
  }

  # Security: Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Cost Saving: Delete protection disabled for this lab
  deletion_protection = false
}

# 2. The Worker Nodes (Where Apps Run) - "Cheap & Best"
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.project_id}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  # Auto-scaling: Starts small (1 node), grows if needed
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    preemptible  = false # We use Spot instead (newer version of preemptible)
    spot         = true  # <--- 90% Discount!
    machine_type = "e2-standard-2" # Best balance for GKE

    # Security: Use minimal scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    tags = ["gke-node", "${var.project_id}-gke"]
  }
}