terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.2.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}
