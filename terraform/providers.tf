provider "google" {
  project                     = var.project_id
  region                      = var.default_region
  impersonate_service_account = "${var.deployer_sa_name}@${var.project_id}.iam.gserviceaccount.com"
}

provider "tailscale" {
  api_key = var.tailscale_api_key
}

provider "random" {}