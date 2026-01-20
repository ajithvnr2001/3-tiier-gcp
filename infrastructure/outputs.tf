# infrastructure/outputs.tf

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "artifact_registry_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.name}"
  description = "The URL to push docker images to"
}

# infrastructure/outputs.tf (Append this to the previous code)

output "db_private_ip" {
  value       = google_sql_database_instance.postgres.private_ip_address
  description = "The Private IP of the Database"
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The Workload Identity Provider resource name"
}

output "service_account_email" {
  value       = google_service_account.github_actions.email
  description = "The Service Account Email for GitHub Actions"
}