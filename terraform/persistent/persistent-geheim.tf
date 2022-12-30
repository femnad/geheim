variable "project" {}

variable "dns_zone_name" {}

variable "dns_name" {}

variable "volume_name" {}

variable "state_storage_bucket" {}

variable "tf_service_account" {}

variable "tf_service_account_display_name" {}

variable "region" {
  default = "europe-west-2"
}

variable "zone" {
  default = "europe-west2-c"
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_dns_managed_zone" "geheim_zone" {
  name     = var.dns_zone_name
  dns_name = var.dns_name
}

resource "google_compute_disk" "geheim_disk" {
  name = var.volume_name
  size = 10
  type = "pd-standard"
}

resource "google_storage_bucket" "state_store" {
  name     = var.state_storage_bucket
  location = "EUROPE-WEST2"
}

resource "google_service_account" "tf_service_account" {
  account_id   = var.tf_service_account
  display_name = var.tf_service_account_display_name
}

resource "google_storage_bucket_acl" "image_store_acl" {
  bucket = var.state_storage_bucket

  role_entity = [
    "WRITER:user-${google_service_account.tf_service_account.email}"
  ]
}
