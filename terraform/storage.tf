resource "google_compute_disk" "bastion" {
  name                      = "${var.base_name}-bastion"
  zone                      = var.us_zone
  image                     = data.google_compute_image.ubuntu_2204.self_link
  licenses                  = data.google_compute_image.ubuntu_2204.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.bastion_disk_size
  type                      = var.default_disk_types["bastion"]
  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "TDX_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

}

resource "google_compute_disk" "code" {
  name                      = "${var.base_name}-code"
  zone                      = var.default_zone
  image                     = data.google_compute_image.debian_11.self_link
  licenses                  = data.google_compute_image.debian_11.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.code_disk_size
  type                      = var.default_disk_types["code"]

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

}

resource "google_compute_disk" "workstation" {
  name                      = "${var.base_name}-workstation"
  zone                      = var.default_zone
  image                     = data.google_compute_image.debian_12.self_link
  licenses                  = data.google_compute_image.debian_12.licenses
  physical_block_size_bytes = var.default_block_size_bytes
  size                      = var.workstation_disk_size
  type                      = var.default_disk_types["workstation"]

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

}
