terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "profile" {}
variable "name" {}
variable "image" {}
variable "zone" {}
variable "keys" {}
variable "tags" {}
variable "vpc" {}
variable "resource_group" {}
variable "user_data" {}
variable "subnet" {}
variable "security_group" {}




resource "ibm_is_bare_metal_server" "bare_metal" {

  profile = var.profile
  name    = var.name
  image   = var.image
  zone    = var.zone
  keys    = var.keys
  tags    = var.tags
  primary_network_interface {
    name            = "ens1"
    subnet          = var.subnet
    security_groups = var.security_group
  }
  vpc            = var.vpc
  resource_group = var.resource_group
  user_data      = var.user_data
  timeouts {
    create = "90m"
  }
}

output "bare_metal_server_id" {
  value = ibm_is_bare_metal_server.bare_metal.id
}

output "primary_network_interface" {
  value = ibm_is_bare_metal_server.bare_metal.primary_network_interface[0].primary_ip.0.address
}