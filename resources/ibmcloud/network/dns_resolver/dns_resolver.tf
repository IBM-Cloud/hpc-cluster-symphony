###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Add custom resolver to IBM Cloud DNS resource instance.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "customer_resolver_name" {}
variable "instance_guid" {}
variable "description" {}
variable "subnet_crn" {}


resource "ibm_dns_custom_resolver" "itself" {
  name              = format("%s-dnsresolver", var.customer_resolver_name)
  instance_id       = var.instance_guid
  description       = var.description
  high_availability = false
  enabled           = true
  locations {
    subnet_crn = var.subnet_crn
    enabled    = true
  }
}

output "custom_resolver_id" {
  value = ibm_dns_custom_resolver.itself.custom_resolver_id
}

output "dns_server_ip" {
  value = ibm_dns_custom_resolver.itself.locations[0].dns_server_ip
}
