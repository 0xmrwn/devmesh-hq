# Service Account
output "service_account" {
  description = "DevMesh Hub service account information"
  value = {
    email = google_service_account.devmesh_hub_sa.email
    name  = google_service_account.devmesh_hub_sa.name
  }
}

# Compute Instances
output "instances" {
  description = "Information about all compute instances"
  value = {
    bastion = {
      name         = google_compute_instance.bastion.name
      zone         = google_compute_instance.bastion.zone
      machine_type = google_compute_instance.bastion.machine_type
      internal_ip  = google_compute_instance.bastion.network_interface[0].network_ip
    }
    code = {
      name         = google_compute_instance.code.name
      zone         = google_compute_instance.code.zone
      machine_type = google_compute_instance.code.machine_type
      internal_ip  = google_compute_instance.code.network_interface[0].network_ip
    }
    workstation = {
      name         = google_compute_instance.workstation.name
      zone         = google_compute_instance.workstation.zone
      machine_type = google_compute_instance.workstation.machine_type
      internal_ip  = google_compute_instance.workstation.network_interface[0].network_ip
    }
  }
}

# Storage Disks
output "disks" {
  description = "Information about all compute disks"
  value = {
    bastion = {
      name = google_compute_disk.bastion.name
      size = google_compute_disk.bastion.size
      type = google_compute_disk.bastion.type
      zone = google_compute_disk.bastion.zone
    }
    code = {
      name = google_compute_disk.code.name
      size = google_compute_disk.code.size
      type = google_compute_disk.code.type
      zone = google_compute_disk.code.zone
    }
    workstation = {
      name = google_compute_disk.workstation.name
      size = google_compute_disk.workstation.size
      type = google_compute_disk.workstation.type
      zone = google_compute_disk.workstation.zone
    }
  }
}

# Network Resources
output "network" {
  description = "Network infrastructure information"
  value = {
    routers = {
      esw1 = {
        name   = google_compute_router.nat_router_esw1.name
        region = google_compute_router.nat_router_esw1.region
      }
      us = {
        name   = google_compute_router.nat_router_us.name
        region = google_compute_router.nat_router_us.region
      }
    }
    default_network = data.google_compute_network.default.name
  }
}

# Instance Connection Information
output "connection_info" {
  description = "Connection information for instances"
  value = {
    bastion_ssh     = "gcloud compute ssh ${google_compute_instance.bastion.name} --zone=${google_compute_instance.bastion.zone}"
    code_ssh        = "gcloud compute ssh ${google_compute_instance.code.name} --zone=${google_compute_instance.code.zone}"
    workstation_ssh = "gcloud compute ssh ${google_compute_instance.workstation.name} --zone=${google_compute_instance.workstation.zone}"
  }
}

output "dependency_group" {
  description = "Shared dependency group identifier for all linked resources."
  value       = random_pet.global_version.id
}
