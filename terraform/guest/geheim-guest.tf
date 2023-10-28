terraform {
  backend "gcs" {
    bucket = "tf-fcd-sync"
    prefix = "geheim"
  }
}

data "sops_file" "secret" {
  source_file = "secret.sops.yml"
}

provider "google" {
  project = nonsensitive(data.sops_file.secret.data["project"])
  region  = var.region
  zone    = var.zone
}

variable "guest_ip" {}

module "firewall" {
  version = "0.11.0"
  source  = "femnad/firewall-module/gcp"
  network = var.network_name
  prefix  = "geheim-guest"
  world_reachable = {
    remote_ips = [var.guest_ip]
    port_map   = { "22" = "tcp" }
  }
  providers = {
    google = google
  }
}
