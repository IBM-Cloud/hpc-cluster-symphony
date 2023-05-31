###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Creates IBM Cloud Resource instance.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "resource_instance_name" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_resource_instance" "itself" {
  name              = format("%s-dns", var.resource_instance_name)
  resource_group_id = var.resource_group_id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
  tags              = var.tags
}

output "resource_guid" {
  value = ibm_resource_instance.itself.guid
}
