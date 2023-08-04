terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

module "instance-module" {
  source          = "femnad/instance-module/gcp"
  version         = "0.20.0"
  github_user     = "femnad"
  name            = "geheim"
  network_name    = var.network_name
  subnetwork_name = "geheim-subnetwork"
  attached_disks = [{
    source = var.volume_name,
    name   = var.disk_name,
  }]
  providers = {
    google = google
  }
}

module "dns-module" {
  source           = "femnad/dns-module/gcp"
  version          = "0.8.0"
  dns_name         = var.dns_name
  instance_ip_addr = module.instance-module.instance_ip_addr
  managed_zone     = var.managed_zone
  providers = {
    google = google
  }
}

module "firewall-module" {
  version = "0.10.1"
  source  = "femnad/firewall-module/gcp"
  network = module.instance-module.network_name
  prefix  = "geheim"
  self_reachable = {
    "22" = "tcp"
  }
  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
  providers = {
    google = google
  }
}
