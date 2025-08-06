# -----------------------------------------------------------
# Global variables
# -----------------------------------------------------------

variable "base_name" {
  type        = string
  description = "Base name for DevMesh resources"
  default     = "devmesh"
}

variable "project_id" {
  type        = string
  description = "GCP project ID where resources are managed"
}

variable "default_region" {
  type        = string
  description = "Default GCP region where resources are managed"
  default     = "europe-southwest1"
}

variable "default_zone" {
  type        = string
  description = "Default GCP zone where resources are managed"
  default     = "europe-southwest1-b"
}

variable "us_region" {
  type        = string
  description = "US GCP region where resources are managed"
  default     = "us-east1"
}

variable "us_zone" {
  type        = string
  description = "US GCP zone where resources are managed"
  default     = "us-east1-b"
}

variable "deployer_sa_name" {
  type        = string
  description = "Email of the service account to impersonate"
  default     = "devmesh-infra-admin"
}

variable "tailscale_api_key" {
  type        = string
  description = "API key for authenticating with Tailscale API"
}

# -----------------------------------------------------------
# Compute variables
# -----------------------------------------------------------

variable "bastion_machine_type" {
  type        = string
  description = "Machine type for the bastion instance"
  default     = "e2-micro"
}

variable "code_machine_type" {
  type        = string
  description = "Machine type for the code server instance"
  default     = "e2-medium"
}

variable "workstation_machine_type" {
  type        = string
  description = "Machine type for the workstation instance"
  default     = "e2-standard-2"
}

# -----------------------------------------------------------
# Compute Storage variables
# -----------------------------------------------------------

variable "default_disk_types" {
  type        = map(string)
  description = "Default disk type for the disks"
  default = {
    bastion     = "pd-standard"
    code        = "pd-balanced"
    workstation = "pd-balanced"
  }
}

variable "default_block_size_bytes" {
  type        = number
  description = "Default block size for the disks"
  default     = 4096
}

variable "bastion_disk_size" {
  type        = number
  description = "Size for the bastion disk"
  default     = 10
}

variable "code_disk_size" {
  type        = number
  description = "Size for the code disk"
  default     = 50
}

variable "workstation_disk_size" {
  type        = number
  description = "Size for the workstation disk"
  default     = 50
}

# -----------------------------------------------------------
# Secret Manager variables
# -----------------------------------------------------------

variable "tailscale_secret_id" {
  type        = string
  description = "Tailscale secret ID"
  default     = "TAILSCALE_AUTHKEY"
}

variable "github_ssh_key_secret_id" {
  type        = string
  description = "GitHub SSH key secret ID"
  default     = "GITHUB_SSH_KEY"
}

variable "gemini_api_key_secret_id" {
  type        = string
  description = "Gemini API key secret ID"
  default     = "GEMINI_API_KEY"
}

variable "groq_api_key_secret_id" {
  type        = string
  description = "Groq API key secret ID"
  default     = "GROQ_API_KEY"
}

# -----------------------------------------------------------
# Tagging variables
# -----------------------------------------------------------

variable "environment" {
  type        = string
  description = "Deployment environment for resources"
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner of the deployed resources"
  default     = "devmesh-team"
}
