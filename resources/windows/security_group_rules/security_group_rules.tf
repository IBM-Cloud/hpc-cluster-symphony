###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    This module used for creating security group rules for symphony windows
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "remote_allowed_ips" {}
variable "security_group" {}

#Enable below security group to allow RDP to windows worker nodes
resource "ibm_is_security_group_rule" "ingress_tcp_windows_rdp" {
  count     = length(var.remote_allowed_ips)
  group     = var.security_group
  direction = "inbound"
  remote    = var.remote_allowed_ips[count.index]
  tcp {
    port_min = 3389
    port_max = 3389
  }
}

resource "ibm_is_security_group_rule" "ingress_udp_windows_rdp" {
  count     = length(var.remote_allowed_ips)
  group     = var.security_group
  direction = "inbound"
  remote    = var.remote_allowed_ips[count.index]
  udp {
    port_min = 3389
    port_max = 3389
  }
}
