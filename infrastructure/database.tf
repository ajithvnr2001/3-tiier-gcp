# infrastructure/database.tf

# 1. Reserve an IP range for Google Services (Private Service Access)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_id}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# 2. Connect our VPC to Google's Service Network (Peering)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# 3. The Database Instance
resource "google_sql_database_instance" "postgres" {
  name             = "${var.project_id}-db-instance"
  region           = var.region
  database_version = "POSTGRES_15"
  
  # Wait for networking to be ready
  depends_on = [google_service_networking_connection.private_vpc_connection]
  
  # We want to delete it easily for this lab
  deletion_protection = false 

  settings {
    # Cost Saving: Smallest instance type
    tier = "db-f1-micro"
    
    # Cost Saving: Zonal (Single Zone). Change to "REGIONAL" for HA.
    availability_type = "ZONAL" 

    ip_configuration {
      ipv4_enabled    = false # No Public IP (Secure!)
      private_network = google_compute_network.vpc.id
    }
  }
}

# 4. Create the actual Database inside the instance
resource "google_sql_database" "database" {
  name     = "todo-app-db"
  instance = google_sql_database_instance.postgres.name
}

# 5. Create a User
resource "google_sql_user" "users" {
  name     = "todo-user"
  instance = google_sql_database_instance.postgres.name
  password = "changeme123" # In prod, use Secret Manager!
}