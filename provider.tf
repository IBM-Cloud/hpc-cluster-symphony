###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# Or we can switch the region via export IC_REGION="eu-gb"
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.71.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
  }
}

# Or we can switch the region via export IC_REGION="eu-gb"
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.region_name
}
