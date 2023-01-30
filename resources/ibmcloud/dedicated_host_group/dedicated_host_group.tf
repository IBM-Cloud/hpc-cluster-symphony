terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "name" {}
variable "class" {}
variable "family" {}
variable "zone" {}
variable "resource_group" {}



resource "ibm_is_dedicated_host_group" "worker" {
  name           = var.name
  class          = var.class
  family         = var.family
  zone           = var.zone
  resource_group = var.resource_group
}

output "dedicate_host_group_id" {
  value = ibm_is_dedicated_host_group.worker.id
}
