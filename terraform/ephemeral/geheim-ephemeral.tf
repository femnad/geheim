terraform {
  backend gcs { }
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
    access_config {
      network_tier = "STANDARD"
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  attached_disk {
    source = var.volume_name
  }

  scheduling {
    preemptible = true
    automatic_restart = false
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
