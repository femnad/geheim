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
  source  = "femnad/lazyspot/gcp"
  version = "0.6.5"

  disks = [{
    source = nonsensitive(data.sops_file.secret.data["volume_name"]),
    name   = nonsensitive(data.sops_file.secret.data["disk_name"]),
  }]
  dns = {
    name = nonsensitive(data.sops_file.secret.data["dns_name"])
    zone = nonsensitive(data.sops_file.secret.data["managed_zone"])
  }

  github_user     = "femnad"
  machine_type    = "e2-small"
  max_run_seconds = 3600
  name            = "geheim"

  firewall = {
    self = {
      ip_mask = var.managed_connection ? 29 : 32
      ip_num  = var.managed_connection ? 7 : 1
    }
  }
}
