# Service Accounts

resource "google_service_account" "bastion_sa" {
  depends_on   = [google_project_service.compute]
  account_id   = "sa-${var.base_name}-bastion"
  display_name = "Bastion Service Account"
}

resource "google_service_account" "code_sa" {
  depends_on   = [google_project_service.compute]
  account_id   = "sa-${var.base_name}-code"
  display_name = "Code Service Account"
}

resource "google_service_account" "workstation_sa" {
  depends_on   = [google_project_service.compute]
  account_id   = "sa-${var.base_name}-workstation"
  display_name = "Workstation Service Account"
}

# Project IAM Members

# Bastion Service Account

resource "google_project_iam_member" "bastion_sa_compute_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_sa_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_sa_logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_sa_secret_manager_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

# Code Service Account

resource "google_project_iam_member" "code_sa_logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.code_sa.email}"
}

resource "google_project_iam_member" "code_sa_secret_manager_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.code_sa.email}"
}

# Workstation Service Account

resource "google_project_iam_member" "workstation_sa_logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workstation_sa.email}"
}

resource "google_project_iam_member" "workstation_sa_secret_manager_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.workstation_sa.email}"
}
