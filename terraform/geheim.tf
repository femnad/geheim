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

module "instance" {
  source      = "femnad/instance-module/gcp"
  version     = "0.23.2"
  github_user = "femnad"
  name        = "geheim"
  attached_disks = [{
    source = nonsensitive(data.sops_file.secret.data["volume_name"]),
    name   = nonsensitive(data.sops_file.secret.data["disk_name"]),
  }]
  providers = {
    google = google
  }
}

module "dns" {
  source           = "femnad/dns-module/gcp"
  version          = "0.8.0"
  dns_name         = nonsensitive(data.sops_file.secret.data["dns_name"])
  instance_ip_addr = module.instance.instance_ip_addr
  managed_zone     = nonsensitive(data.sops_file.secret.data["managed_zone"])
  providers = {
    google = google
  }
}

module "firewall" {
  version = "0.11.0"
  source  = "femnad/firewall-module/gcp"
  network = module.instance.network_name
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
