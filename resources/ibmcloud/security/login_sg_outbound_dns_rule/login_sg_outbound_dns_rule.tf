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

variable "group" {}
variable "remote" {}

resource "ibm_is_security_group_rule" "login_egress_dns" {
  group     = var.group
  direction = "outbound"
  remote    = var.remote
  udp {
    port_min = 53
    port_max = 53
  }
}