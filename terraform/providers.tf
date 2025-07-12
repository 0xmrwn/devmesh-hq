provider "google" {
  project                     = var.project_id
  region                      = var.default_region
  impersonate_service_account = var.impersonate_sa_email
}

provider "google-beta" {
  alias                       = "beta"
  project                     = var.project_id
  region                      = var.default_region
  impersonate_service_account = var.impersonate_sa_email
}