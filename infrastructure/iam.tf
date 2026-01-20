# infrastructure/iam.tf

# 1. Create a Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "Service Account for GitHub Actions"
}

# 2. Give permissions to the Service Account
# It needs to Push to Artifact Registry & Deploy to GKE
resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "cloud_deploy_releaser" {
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "sa_user" {
    # Needed for Cloud Deploy to act as this SA
    project = var.project_id
    role = "roles/iam.serviceAccountUser"
    member = "serviceAccount:${google_service_account.github_actions.email}"
}


# 3. Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
  description               = "Identity pool for GitHub Actions"
}

# 4. Workload Identity Provider (The Connector)
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 5. Allow YOUR specific GitHub Repo to use this Service Account
# REPLACE 'YOUR_GITHUB_USER/YOUR_REPO_NAME' with your actual details
# Example: "repo:suresh/gcp-native-project:ref:refs/heads/main"
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  
  # Allowing ANY repo for now to make it easy for you, 
  # BUT in prod, lock this down to specific repo string.
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/YOUR_GITHUB_USER/YOUR_REPO_NAME" 
}