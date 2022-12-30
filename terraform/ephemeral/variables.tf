variable "github_user" {}

variable "volume_name" {}

variable "project" {}

variable "ssh_user" {}

variable "ssh_email" {}

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
