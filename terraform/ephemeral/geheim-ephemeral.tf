variable github_user {}

variable volume_name {}

variable project {}

variable service_account_secret {}

variable ssh_user {}

variable ssh_email {}

variable region {
  default = "europe-west-2"
}

variable zone {
  default = "europe-west2-c"
}

variable managed_zone {}

variable dns_name {
}

provider passwordstore {
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
  ssh_format_spec = format("%s:%%s %s", var.ssh_user, var.ssh_email)
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
  machine_type = "g1-small"

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

  attached_disk {
    source = var.volume_name
  }

}

resource "google_dns_record_set" "geheim_dns" {
  name = var.dns_name
  type = "A"
  ttl  = 60

  managed_zone = var.managed_zone

  rrdatas = [google_compute_instance.geheim_hoster.network_interface[0].access_config[0].nat_ip]
}
