resource "google_secret_manager_secret" "tailscale_authkey" {
  depends_on = [google_project_service.secret_manager]
  project    = var.project_id
  secret_id  = var.tailscale_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "github_ssh_key" {
  depends_on = [google_project_service.secret_manager]
  project    = var.project_id
  secret_id  = var.github_ssh_key_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "gemini_api_key" {
  depends_on = [google_project_service.secret_manager]
  project    = var.project_id
  secret_id  = var.gemini_api_key_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "groq_api_key" {
  depends_on = [google_project_service.secret_manager]
  project    = var.project_id
  secret_id  = var.groq_api_key_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "tailscale_authkey" {
  deletion_policy = "DELETE"
  enabled         = true
  secret          = google_secret_manager_secret.tailscale_authkey.id
  secret_data     = tailscale_tailnet_key.nodes_auth_key.key
}
