terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "guest_ip" {}

module "firewall-module" {
  version = "0.10.0"
  source  = "femnad/firewall-module/gcp"
  network = var.network_name
  world_reachable = {
    remote_ips = var.guest_ip
    port_map   = { "22" = "tcp" }
  }
  providers = {
    google = google
  }
}
