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

variable "login_subnet_name" {}
variable "vpc" {}
variable "zone" {}
variable "ipv4_cidr_block" {}
variable "resource_group" {}
variable "tags" {}

resource "ibm_is_subnet" "login_subnet" {
  name                     = var.login_subnet_name
  vpc                      = var.vpc
  zone                     = var.zone
  ipv4_cidr_block          = var.ipv4_cidr_block
  resource_group           = var.resource_group
  tags                     = var.tags
}

output "login_subnet_id" {
  value = ibm_is_subnet.login_subnet.id
}

output "ipv4_cidr_block" {
  value = ibm_is_subnet.login_subnet.ipv4_cidr_block
}
