terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "vsi_name" {}
variable "image" {}
variable "profile" {}
variable "vpc" {}
variable "zone" {}
variable "keys" {}
variable "user_data" {}
variable "resource_group" {}
variable "tags" {}
variable "subnet_id" {}
variable "security_group" {}
variable "primary_ipv4_address" {}


resource "ibm_is_instance" "primary" {
  name           = var.vsi_name
  image          = var.image
  profile        = var.profile
  vpc            = var.vpc
  zone           = var.zone
  keys           = var.keys
  resource_group = var.resource_group
  user_data      = var.user_data

  tags = var.tags
  primary_network_interface {
    name                 = "eth0"
    subnet               = var.subnet_id
    security_groups      = var.security_group
    primary_ip {
      address            = var.primary_ipv4_address
    }
  }
}
/*
output "primary_network_interface" {
  value = ibm_is_instance.primary.primary_network_interface[0]["primary_ipv4_address"]
}
*/
output "primary_id" {
  value = ibm_is_instance.primary.id
}

output "primary_network_interface" {
  value = ibm_is_instance.primary.primary_network_interface[0].primary_ip.0.address
}