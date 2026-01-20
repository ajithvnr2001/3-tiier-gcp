# infrastructure/artifact-registry.tf

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.project_id}-repo"
  description   = "Docker repository for our 3-tier app"
  format        = "DOCKER"
}