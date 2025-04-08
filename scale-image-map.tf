###################################################
# Copyright (C) IBM Corp. 2025 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This mapping file has entries for scale storage node images. Version used is 5.2.0.1
locals {
  scale_image_region_map = {
    "hpcc-scale5221-rhel810" = {
      "au-syd"   = "r026-e6ace789-74bc-4ae2-a881-6236994a1018"
      "br-sao"   = "r042-54221b98-18e0-457d-83bc-142e47499d9a"
      "ca-tor"   = "r038-39520078-e7f0-4405-b70c-bca6ae91885c"
      "eu-de"    = "r010-e2debf2e-a80f-40f8-903f-9a648d602faa"
      "eu-es"    = "r050-561fb6d2-e4d0-42a2-b2d8-17df8ccb9e9c"
      "eu-gb"    = "r018-5d89efa5-d53f-4deb-a3b3-d3b9bd2cd312"
      "jp-osa"   = "r034-682a378c-6b73-4bc8-ad23-6c9d2900b0b1"
      "jp-tok"   = "r022-7500c788-e3d1-4ebc-8dc9-b5ac12ba7b84"
      "us-east"  = "r014-c5a059c3-4fe2-4e20-8a60-86fa33d42bb0"
      "us-south" = "r006-60bc1e23-86b4-46c2-9220-5f937abd60a2"
    }
  }
}
