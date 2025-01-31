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

variable "name" {}
variable "size" {}
variable "zone" {}
variable "security_groups" {}
variable "subnet_id" {}
variable "iops" {}
variable "tags" {}
variable "resource_group" {}
variable "vpcid" {}

resource "ibm_is_share" "share" {
  name                = var.name
  access_control_mode = "vpc"
  size                = var.size
  iops                = var.iops
  profile             = "dp2"
  resource_group      = var.resource_group
  zone                = var.zone
  tags                = var.tags
}

resource "ibm_is_share_mount_target" "share_target" {
  share = ibm_is_share.share.id
  name  = "${var.name}-mount-target"
  vpc   = var.vpcid
}

output "mount_path" {
  value = ibm_is_share_mount_target.share_target.mount_path
}
