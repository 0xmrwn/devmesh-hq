terraform {
  required_version = ">= 1.8.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.21.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
