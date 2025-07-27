data "google_compute_image" "bastion" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2204-lts"
}

data "google_compute_image" "code" {
  project = "debian-cloud"
  family  = "debian-12"
}

data "google_compute_image" "workstation" {
  project = "debian-cloud"
  family  = "debian-12"
}

resource "google_compute_disk" "bastion" {
  depends_on                = [google_project_service.compute]
  name                      = "${var.base_name}-bastion"
  zone                      = var.us_zone
  image                     = data.google_compute_image.bastion.self_link
  licenses                  = data.google_compute_image.bastion.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.bastion_disk_size
  type                      = var.default_disk_types["bastion"]

  labels = merge(local.standard_labels, {
    component        = "bastion"
    dependency_group = random_pet.global_version.id
  })
}

resource "google_compute_disk" "code" {
  depends_on                = [google_project_service.compute]
  name                      = "${var.base_name}-code"
  zone                      = var.default_zone
  image                     = data.google_compute_image.code.self_link
  licenses                  = data.google_compute_image.code.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.code_disk_size
  type                      = var.default_disk_types["code"]

  labels = merge(local.standard_labels, {
    component        = "code"
    dependency_group = random_pet.global_version.id
  })
}

resource "google_compute_disk" "workstation" {
  depends_on                = [google_project_service.compute]
  name                      = "${var.base_name}-workstation"
  zone                      = var.default_zone
  image                     = data.google_compute_image.workstation.self_link
  licenses                  = data.google_compute_image.workstation.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.workstation_disk_size
  type                      = var.default_disk_types["workstation"]

  labels = merge(local.standard_labels, {
    component        = "workstation"
    dependency_group = random_pet.global_version.id
  })
}
