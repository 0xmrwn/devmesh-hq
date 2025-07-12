resource "google_service_account" "devmesh_hub_sa" {
  account_id   = "${var.base_name}-hub-sa"
  display_name = "DevMesh hub (e2-micro bastion)"
}

resource "google_project_iam_member" "devmesh_hub_sa_compute_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.devmesh_hub_sa.email}"
}

resource "google_project_iam_member" "devmesh_hub_sa_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.devmesh_hub_sa.email}"
}

resource "google_project_iam_member" "devmesh_hub_sa_logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.devmesh_hub_sa.email}"
}

resource "google_project_iam_member" "devmesh_hub_sa_secret_manager_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.devmesh_hub_sa.email}"
}
