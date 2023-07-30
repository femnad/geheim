variable "github_user" {}

variable "volume_name" {}

variable "project" {}

variable "region" {
  default = "europe-west2"
}

variable "zone" {
  default = "europe-west2-c"
}

variable "managed_zone" {}

variable "dns_name" {}

variable "managed_connection" {
  default = false
}

variable "disk_name" {}

variable "network_name" {
  default = "geheim-network"
}
