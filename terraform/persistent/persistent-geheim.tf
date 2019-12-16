variable project {}

variable service_account_secret {}

variable region {
  default = "europe-west-2"
}

variable zone {
  default = "europe-west2-c"
}

variable dns_zone_name {
}

variable dns_name {
}

provider passwordstore {
}

data "passwordstore_secret" "service_account" {
  name = var.service_account_secret
}

provider "google" {
  credentials = data.passwordstore_secret.service_account.contents
  project     = var.project
  region      = var.region
  zone = var.zone
}

resource "google_dns_managed_zone" "geheim_zone" {
  name     = var.dns_zone_name
  dns_name = var.dns_name
}
