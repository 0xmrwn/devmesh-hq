data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default_esw1" {
  name   = "default"
  region = var.default_region
}

data "google_compute_subnetwork" "default_us" {
  name   = "default"
  region = var.us_region
}

resource "google_compute_router" "nat_router_esw1" {
  depends_on = [google_project_service.compute]
  name       = "nat-router-esw1"
  network    = data.google_compute_network.default.self_link
  project    = var.project_id
  region     = var.default_region
}

resource "google_compute_router" "nat_router_us" {
  depends_on = [google_project_service.compute]
  name       = "nat-router"
  network    = data.google_compute_network.default.self_link
  project    = var.project_id
  region     = var.us_region
}
