variable github_user {}

variable "service_account_secret" {}

variable "project" {}

variable "ssh_user" {}

variable "region" {
  default = "europe-west-2"
}

variable "zone" {
  default = "europe-west2-c"
}

provider "passwordstore" {
}

data "passwordstore_secret" "service_account" {
  name = var.service_account_secret
}

data "http" "ipinfo" {
  url = "https://ipinfo.io/json"
}

data "http" "github" {
  url = format("https://api.github.com/users/%s/keys", var.github_user)
}

locals {
  ssh_format_spec = format("%s:%%s", var.ssh_user)
}

provider "google" {
  credentials = data.passwordstore_secret.service_account.contents
  project     = var.project
  region      = var.region
  zone = var.zone
}

resource "google_compute_network" "network_of_interest" {
  name = "geheim-network"
}

resource "google_compute_firewall" "firewall_ssh" {
  name = "ssh-allower"
  network = google_compute_network.network_of_interest.name

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = [format("%s/32", jsondecode(data.http.ipinfo.body).ip)]
}

resource "google_compute_instance" "geheim_hoster" {
  name = "geheim"
  machine_type = "f1-micro"
  scheduling {
    automatic_restart = false
    preemptible = true
  }

  metadata = {
    ssh-keys = join("\n", formatlist(local.ssh_format_spec, [for key in jsondecode(data.http.github.body): key.key]))
  }

  network_interface {
    network = google_compute_network.network_of_interest.name
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

}
