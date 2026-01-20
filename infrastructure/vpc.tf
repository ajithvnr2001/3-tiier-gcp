# infrastructure/vpc.tf

# 1. The VPC (Virtual Private Cloud)
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false  # We want full control!
}

# 2. The Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/20" # Main IPs for the Nodes (VMs)

  # Secondary Ranges for GKE (Crucial for VPC-Native clusters)
  secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = "10.4.0.0/14" # Huge range for Pods
  }
  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = "10.8.0.0/20" # Range for Services (Load Balancers)
  }
}

# 3. Cloud Router (Required for NAT)
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id
}

# 4. Cloud NAT (Allows private VMs to access the internet securely)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}