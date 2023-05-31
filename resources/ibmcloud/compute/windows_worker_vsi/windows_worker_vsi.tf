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

variable "vsi_name" {}
variable "image" {}
variable "profile" {}
variable "zone" {}
variable "keys" {}
variable "vpc" {}
variable "resource_group" {}
variable "tags" {}
variable "dedicated_host" {}
variable "user_data" {}
variable "subnet_id" {}
variable "security_group" {}
variable "primary_ipv4_address" {}
variable "instance_id" {}
variable "zone_id" {}
variable "dns_domain" {}

resource "ibm_is_instance" "windows_worker" {
  name           = var.vsi_name
  image          = var.image
  profile        = var.profile
  vpc            = var.vpc
  zone           = var.zone
  keys           = var.keys
  resource_group = var.resource_group
  tags           = var.tags
  dedicated_host = var.dedicated_host
  user_data      = var.user_data
  primary_network_interface {
    name            = "eth0"
    subnet          = var.subnet_id
    security_groups = var.security_group
    primary_ip {
      address = var.primary_ipv4_address
    }
  }
}

locals {
  instance = [ {
      name = var.vsi_name
      primary_network_interface = var.primary_ipv4_address
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
output "windows_worker_id" {
  value = ibm_is_instance.windows_worker.id
  depends_on = [ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}