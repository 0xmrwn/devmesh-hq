resource "random_pet" "global_version" {
  keepers = {
    bastion_image = var.ubuntu_2204_version
    code_image    = var.debian_11_version
    workstation_image = var.debian_12_version
    zone          = var.default_zone
  }
} 