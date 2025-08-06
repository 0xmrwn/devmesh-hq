resource "random_pet" "global_version" {
  keepers = {
    bastion_image     = data.google_compute_image.bastion.family
    code_image        = data.google_compute_image.code.family
    workstation_image = data.google_compute_image.workstation.family
    zone              = var.default_zone
  }
}
