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
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# 3. Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool-v3" 
  display_name              = "GitHub Pool V3"
  description               = "Identity pool for GitHub Actions"
}

# 4. Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-v3"
  display_name                       = "GitHub Provider V3"
  
  # Standard Mapping
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # Attribute condition - REQUIRED - replace with your GitHub username
  attribute_condition = "assertion.repository_owner == 'ajithvnr2001'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 5. Allow GitHub Actions to impersonate the Service Account
# Replace 'ajithvnr2001/YOUR_REPO_NAME' with your actual repository
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  
  # Option 1: Allow all repos from your GitHub account
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository_owner/ajithvnr2001"
  
  # Option 2: Allow specific repository only (RECOMMENDED - uncomment and update)
  # member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/ajithvnr2001/3-tiier-gcp"
}

resource "google_service_account_iam_member" "token_creator" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}