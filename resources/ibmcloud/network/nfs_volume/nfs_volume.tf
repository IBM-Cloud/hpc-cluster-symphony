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

variable "nfs_name" {}
variable "profile" {}
variable "iops" {}
variable "capacity" {}
variable "zone" {}
variable "resource_group" {}
variable "tags" {}

resource "ibm_is_volume" "nfs" {
  name           = var.nfs_name
  profile        = var.profile
  iops           = var.iops
  capacity       = var.capacity
  zone           = var.zone
  resource_group = var.resource_group
  tags           = var.tags
}

output "nfs_volume_id" {
  value = ibm_is_volume.nfs.id
}