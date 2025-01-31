###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This mapping file has entries for scale storage node images. Version used is 5.2.0.1
locals {
  scale_image_region_map = {
    "hpcc-scale5211-rhel810" = {
      "au-syd"   = "r026-e8ed81b4-d974-47cd-98b2-8ab122f9f793"
      "br-sao"   = "r042-83ef5052-2f41-4f01-90d5-d542af676bc3"
      "ca-tor"   = "r038-c89c5867-fa4f-4fa4-b773-e030f11249bb"
      "eu-de"    = "r010-5c7331b2-2b0c-4eef-925c-31a93a8dbbdc"
      "eu-es"    = "r050-713ffa8f-5b1e-4c45-838c-b271aa04df97"
      "eu-gb"    = "r018-5bbd380f-1326-4a79-b992-fb0e06417a95"
      "jp-osa"   = "r034-5dd849c9-86e2-4513-801c-b96ef0f4b3d2"
      "jp-tok"   = "r022-e4aab701-36a1-4f8b-8641-55d626378d9a"
      "us-east"  = "r014-929bfaad-2b80-4acf-bc3f-4a2a01f8cc57"
      "us-south" = "r006-c24af608-ae93-41d3-8c27-bad8aa93ac9d"
    }
  }
}
