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
variable "resource_group_id" {}
variable "region_location" {}
variable "cluster_prefix" {}

resource "ibm_resource_instance" "win_fileshare_instance" {
  name              = "${var.cluster_prefix}-win-fileshare"
  resource_group_id = var.resource_group_id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "win_fileshare_bucket" {
  bucket_name          = "${var.cluster_prefix}-win-fileshare"
  resource_instance_id = ibm_resource_instance.win_fileshare_instance.id
  region_location      = var.region_location
  storage_class        = "standard"
}

resource "ibm_resource_key" "resourcekey" {
  name                 = "${var.cluster_prefix}-win-fileshare"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.win_fileshare_instance.id
  parameters           = { "HMAC" = true }
  //User can increase timeouts
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

output "resourcekey" {
  value = ibm_resource_key.resourcekey
}
