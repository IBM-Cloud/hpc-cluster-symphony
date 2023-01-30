terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "subnet_name" {}
variable "vpc" {}
variable "zone" {}
variable "ipv4_cidr_block" {}
variable "public_gateway" {}
variable "resource_group" {}
variable "tags" {}

resource "ibm_is_subnet" "subnet" {
  name                     = var.subnet_name
  vpc                      = var.vpc
  zone                     = var.zone
  ipv4_cidr_block          = var.ipv4_cidr_block
  public_gateway           = var.public_gateway
  resource_group           = var.resource_group
  tags                     = var.tags
}

output "subnet_id" {
  value = ibm_is_subnet.subnet.id
}

output "ipv4_cidr_block" {
  value = ibm_is_subnet.subnet.ipv4_cidr_block
}