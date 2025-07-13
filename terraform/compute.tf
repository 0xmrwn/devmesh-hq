data "google_compute_image" "ubuntu_2204" {
  project = "ubuntu-os-cloud"
  filter  = "name = ${var.ubuntu_2204_version}"
}

data "google_compute_image" "debian_11" {
  project = "debian-cloud"
  filter  = "name = ${var.debian_11_version}"
}

data "google_compute_image" "debian_12" {
  project = "debian-cloud"
  filter  = "name = ${var.debian_12_version}"
}

resource "google_compute_instance" "bastion" {
  name                = "${var.base_name}-bastion"
  zone                = var.us_zone
  machine_type        = var.bastion_machine_type
  deletion_protection = true

  boot_disk {
    source = google_compute_disk.bastion.self_link
  }

  metadata = {
    startup-script = local.bastion_startup_script
  }

  network_interface {
    network            = google_compute_router.nat_router_us.network
    stack_type         = data.google_compute_subnetwork.default_us.stack_type
    subnetwork         = data.google_compute_subnetwork.default_us.self_link
    subnetwork_project = data.google_compute_subnetwork.default_us.project
  }

  service_account {
    email  = google_service_account.devmesh_hub_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  labels = {
    dependency_group = random_pet.global_version.id
  }
}

resource "google_compute_instance" "code" {
  depends_on   = [google_project_service.osconfig]
  name         = "${var.base_name}-code"
  zone         = var.default_zone
  machine_type = var.code_machine_type
  tags         = ["allow-tailscale-udp"]

  boot_disk {
    source = google_compute_disk.code.self_link
  }

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
    dependency_group      = random_pet.global_version.id
  }

  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = local.code_server_startup_script
  }

  network_interface {
    network            = google_compute_router.nat_router_esw1.network
    stack_type         = data.google_compute_subnetwork.default_esw1.stack_type
    subnetwork         = data.google_compute_subnetwork.default_esw1.self_link
    subnetwork_project = data.google_compute_subnetwork.default_esw1.project
  }

  service_account {
    email  = google_service_account.devmesh_hub_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

}

resource "google_compute_instance" "workstation" {
  name         = "${var.base_name}-workstation"
  zone         = var.default_zone
  machine_type = var.workstation_machine_type
  tags         = ["allow-tailscale-udp"]

  boot_disk {
    source = google_compute_disk.workstation.self_link
  }

  metadata = {
    startup-script = local.workstation_startup_script
  }

  network_interface {
    network            = google_compute_router.nat_router_esw1.network
    stack_type         = data.google_compute_subnetwork.default_esw1.stack_type
    subnetwork         = data.google_compute_subnetwork.default_esw1.self_link
    subnetwork_project = data.google_compute_subnetwork.default_esw1.project
  }

  service_account {
    email  = google_service_account.devmesh_hub_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  labels = {
    dependency_group = random_pet.global_version.id
  }

}
