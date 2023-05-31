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

variable "total_vsis" {}
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

resource "ibm_is_bare_metal_server" "itself" {
  for_each = {
    # This assigns a subnet-id to each of the instance
    # iteration.
    for idx, count_number in range(1, var.total_vsis + 1) : idx => {
      sequence_string = tostring(count_number)
      subnet_id       = element(var.subnet, idx)
      zone            = element(var.zone, idx)
    }
  }
  profile = var.profile
  name    = format("%s-%s", var.name, each.value.sequence_string)
  image   = var.image
  zone    = each.value.zone
  keys    = var.keys
  tags    = var.tags
  primary_network_interface {
    subnet          = each.value.subnet_id
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
  dns_record_ttl = 300
}

// Support lookup by fully qualified domain name
resource "ibm_dns_resource_record" "dns_record_record_a" {
   for_each = {
    for idx, count_number in range(1, var.total_vsis + 1) : idx => {
      name       = element(tolist([for name_details in ibm_is_bare_metal_server.itself : name_details.name]), idx)
      network_ip = element(tolist([for ip_details in ibm_is_bare_metal_server.itself : ip_details.primary_network_interface[0]["primary_ip"][0]["address"]]), idx)
    }
  }

  instance_id = var.instance_id
  zone_id     = var.zone_id
  type        = "A"
  name        = each.value.name
  rdata       = format("%s", each.value.network_ip)
  ttl         = local.dns_record_ttl
}

// Support lookup by ip address returning fully qualified domain name
resource "ibm_dns_resource_record" "dns_resource_record_ptr" {
   for_each = {
    for idx, count_number in range(1, var.total_vsis + 1) : idx => {
      name       = element(tolist([for name_details in ibm_is_bare_metal_server.itself : name_details.name]), idx)
      network_ip = element(tolist([for ip_details in ibm_is_bare_metal_server.itself : ip_details.primary_network_interface[0]["primary_ip"][0]["address"]]), idx)
    }
  }

  instance_id = var.instance_id
  zone_id     = var.zone_id
  type        = "PTR"
  name        = each.value.network_ip
  rdata       = format("%s.%s", each.value.name, var.dns_domain)
  ttl         = local.dns_record_ttl
  depends_on  = [ibm_dns_resource_record.dns_record_record_a]
}

output "bare_metal_server_id" {
  value      = try(toset([for instance_details in ibm_is_bare_metal_server.itself : instance_details.id]), [])
  depends_on = [ibm_is_bare_metal_server.itself, ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]

}

output "primary_network_interface" {
  value      = try(toset([for instance_details in ibm_is_bare_metal_server.itself : instance_details.primary_network_interface[0]["primary_ip"][0]["address"]]), [])
  depends_on = [ibm_is_bare_metal_server.itself, ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}

output "instance_ips_with_vol_mapping" {
  value = try({ for instance_details in ibm_is_bare_metal_server.itself : instance_details.primary_network_interface[0]["primary_ip"][0]["address"] =>
  data.ibm_is_bare_metal_server_profile.itself.disks[1].quantity[0].value == 8 ? ["/dev/nvme0n1", "/dev/nvme1n1", "/dev/nvme2n1", "/dev/nvme3n1", "/dev/nvme4n1", "/dev/nvme5n1", "/dev/nvme6n1", "/dev/nvme7n1"] : ["/dev/nvme0n1", "/dev/nvme1n1", "/dev/nvme2n1", "/dev/nvme3n1", "/dev/nvme4n1", "/dev/nvme5n1", "/dev/nvme6n1", "/dev/nvme7n1", "/dev/nvme8n1", "/dev/nvme9n1", "/dev/nvme10n1", "/dev/nvme11n1", "/dev/nvme12n1", "/dev/nvme13n1", "/dev/nvme14n1", "/dev/nvme15n1"] }, {})
  depends_on = [ibm_is_bare_metal_server.itself, ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]
}

output "instance_private_dns_ip_map" {
  value = try({ for instance_details in ibm_is_bare_metal_server.itself : instance_details.primary_network_interface[0]["primary_ip"][0]["address"] => instance_details.private_dns }, {})
  depends_on = [ibm_is_bare_metal_server.itself, ibm_dns_resource_record.dns_record_record_a, ibm_dns_resource_record.dns_resource_record_ptr]

}