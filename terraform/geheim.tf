variable "service_account_secret" {}

variable "project" {}

variable "region" {
  default = "europe-west-2"
}

provider "passwordstore" {
}

data "passwordstore_secret" "service_account" {
  name = var.service_account_secret
}

provider "google" {
  credentials = data.passwordstore_secret.service_account.contents
  project     = var.project
  region      = var.region
}

resource "google_compute_network" "vpc_network" {
  name = "geheim-network"
}
