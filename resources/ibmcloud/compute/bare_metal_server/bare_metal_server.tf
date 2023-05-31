###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

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
variable "instance_id" {}
variable "zone_id" {}
variable "dns_domain" {}

data "ibm_is_bare_metal_server_profile" "itself" {
  name = var.profile
}

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

locals {
  instance = [ {
      name = ibm_is_bare_metal_server.bare_metal.name
      primary_network_interface = ibm_is_bare_metal_server.bare_metal.primary_network_interface[0].primary_ip.0.address
    }
  ]
  dns_record_ttl = 300
  instances = flatten(local.instance)
}

// Support lookup by fully qualified domain name
resource "ibm_dns_resource_record" "dns_record_record_a" {
  for_each = {
    for instance in local.instances : instance.name => instance.primary_network_interface
  }

  instance_id = var.instance_id
  zone_id     = var.zone_id
  type        = "A"
  name        = each.key
  rdata       = each.value
  ttl         = local.dns_record_ttl
}

// Support lookup by ip address returning fully qualified domain name
resource "ibm_dns_resource_record" "dns_resource_record_ptr" {
  for_each = {
    for instance in local.instances : instance.name => instance.primary_network_interface
  }

  instance_id = var.instance_id
  zone_id     = var.zone_id
  type        = "PTR"
  name        = each.value
  rdata       = format("%s.%s", each.key, var.dns_domain)
  ttl         = local.dns_record_ttl
  depends_on  = [ibm_dns_resource_record.dns_record_record_a]
}


output "bare_metal_server_id" {
  value = ibm_is_bare_metal_server.bare_metal.id
  depends_on = [ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}

output "primary_network_interface" {
  value = ibm_is_bare_metal_server.bare_metal.primary_network_interface[0].primary_ip.0.address
  depends_on = [ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}

output "name" {
  value = ibm_is_bare_metal_server.bare_metal.name
  depends_on = [ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}