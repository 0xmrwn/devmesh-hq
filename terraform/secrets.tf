resource "google_secret_manager_secret" "tailscale_authkey" {
  depends_on = [google_project_service.secret_manager]
  project    = var.project_id
  secret_id  = var.tailscale_secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "tailscale_authkey" {
  deletion_policy = "DELETE"
  enabled         = true
  secret          = google_secret_manager_secret.tailscale_authkey.id
  secret_data     = var.tailscale_auth_key
}
