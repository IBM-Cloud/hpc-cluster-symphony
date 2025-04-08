###################################################
# Copyright (C) IBM Corp. 2025 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

variable "cluster_prefix" {}
variable "region_location" {}
variable "encryption_key_crn" {}
variable "flowlog_storage_instance_guid" {}
variable "vpc_flow_log_name" {}
variable "target_id" {}
variable "is_active" {}
variable "storage_bucket" {}
variable "resource_group" {}
variable "tags" {}
variable "create_iam" {}
variable "create_cos" {}

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

resource "ibm_resource_instance" "vpcflowlog_cos_instance" {
  count             = var.create_cos ? 1 : 0
  name              = "${var.cluster_prefix}-vpcflowlog-cos"
  resource_group_id = var.resource_group
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "vpcflowlog_cos_bucket" {
  count                = var.create_cos ? 1 : 0
  bucket_name          = "${var.cluster_prefix}-vpcflow"
  resource_instance_id = ibm_resource_instance.vpcflowlog_cos_instance[0].id
  region_location      = var.region_location
  storage_class        = "standard"
  kms_key_crn          = var.encryption_key_crn
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [ibm_cos_bucket.vpcflowlog_cos_bucket]
  create_duration = "60s"
}

resource "ibm_iam_authorization_policy" "policy" {
  count                       = var.create_iam || var.create_cos ? 1 : 0
  depends_on                  = [time_sleep.wait_60_seconds]
  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = var.flowlog_storage_instance_guid == "" ? ibm_resource_instance.vpcflowlog_cos_instance[0].guid : var.flowlog_storage_instance_guid
  roles                       = ["Writer"]
}

resource "ibm_is_flow_log" "vpc_flowlog" {
  name           = var.vpc_flow_log_name
  target         = var.target_id
  active         = var.is_active
  storage_bucket = var.storage_bucket == "" ? "${var.cluster_prefix}-vpcflow" : var.storage_bucket
  resource_group = var.resource_group
  tags           = var.tags
  depends_on     = [time_sleep.wait_60_seconds]
}
