terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.39.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}
