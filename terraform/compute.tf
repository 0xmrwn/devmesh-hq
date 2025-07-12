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

resource "google_compute_instance" "bastion_hub" {
  name                = "bastion-hub"
  zone                = var.us_zone
  machine_type        = var.bastion_machine_type
  deletion_protection = true

  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = google_compute_disk.bastion_hub.image
      size  = google_compute_disk.bastion_hub.size
      type  = google_compute_disk.bastion_hub.type
    }

    mode   = "READ_WRITE"
    source = google_compute_disk.bastion_hub.self_link
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

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
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

resource "google_compute_instance" "devmesh_code" {
  name         = "${var.base_name}-code"
  zone         = var.default_zone
  machine_type = var.code_machine_type
  tags         = ["allow-tailscale-udp"]

  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = google_compute_disk.devmesh_code.image
      size  = google_compute_disk.devmesh_code.size
      type  = google_compute_disk.devmesh_code.type
    }

    mode   = "READ_WRITE"
    source = google_compute_disk.devmesh_code.self_link
  }

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
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

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
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

resource "google_compute_instance" "devmesh_desktop" {
  name         = "${var.base_name}-desktop"
  zone         = var.default_zone
  machine_type = var.desktop_machine_type
  tags         = ["allow-tailscale-udp"]

  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = google_compute_disk.devmesh_desktop.image
      size  = google_compute_disk.devmesh_desktop.size
      type  = google_compute_disk.devmesh_desktop.type
    }

    mode   = "READ_WRITE"
    source = google_compute_disk.devmesh_desktop.self_link
  }

  metadata = {
    startup-script = local.desktop_startup_script
  }

  network_interface {
    network            = google_compute_router.nat_router_esw1.network
    stack_type         = data.google_compute_subnetwork.default_esw1.stack_type
    subnetwork         = data.google_compute_subnetwork.default_esw1.self_link
    subnetwork_project = data.google_compute_subnetwork.default_esw1.project
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
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

