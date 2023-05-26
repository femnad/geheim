terraform {
  backend "gcs" {}
}

data "http" "ipinfo" {
  url = "https://ipinfo.io/json"
}

data "http" "github" {
  url = format("https://api.github.com/users/%s/keys", var.github_user)
}

locals {
  ssh_format_spec = format("%s:%%s %s", var.ssh_user, var.ssh_email)
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_subnetwork" "geheim-subnet" {
  name          = "geheim-subnet"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.region
  network       = google_compute_network.network_of_interest.id
}

resource "google_compute_network" "network_of_interest" {
  name                    = "geheim-network"
  auto_create_subnetworks = false
}

module "firewall-module" {
  version = "0.7.1"
  source  = "femnad/firewall-module/gcp"
  network = google_compute_network.network_of_interest.name
  self_reachable = {
    "22" = "tcp"
  }
  ip_mask = var.managed_connection ? 29 : 32
  ip_num  = var.managed_connection ? 7 : 1
  providers = {
    google = google
  }
}

resource "google_compute_instance" "geheim_hoster" {
  name         = "geheim"
  machine_type = "e2-small"

  metadata = {
    ssh-keys = join("\n", formatlist(local.ssh_format_spec, [for key in jsondecode(data.http.github.response_body) : key.key]))
  }

  network_interface {
    network    = google_compute_network.network_of_interest.name
    subnetwork = google_compute_subnetwork.geheim-subnet.name
    access_config {
      network_tier = "STANDARD"
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  attached_disk {
    source = var.volume_name
  }

  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
  }

}

resource "google_dns_record_set" "geheim_dns" {
  name = var.dns_name
  type = "A"
  ttl  = 60

  managed_zone = var.managed_zone

  rrdatas = [google_compute_instance.geheim_hoster.network_interface[0].access_config[0].nat_ip]
}
