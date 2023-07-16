terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "guest_ip" {}

data "google_compute_network" "network_of_interest" {
  name = "geheim-network"
}

resource "google_compute_firewall" "guest_firewall" {
  name    = "guest-allower"
  network = data.google_compute_network.network_of_interest.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [format("%s/32", var.guest_ip)]
}
