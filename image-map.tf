###################################################
# Copyright (C) IBM Corp. 2025 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.2.2.1 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-symp732-scale5221-rhel810-v2" = {
      "eu-gb"    = "r018-67c28aad-ad2a-4c12-bc38-a7c412e3c68f"
      "eu-de"    = "r010-6e25bfed-a410-4346-973b-3f68ed456126"
      "us-east"  = "r014-72349074-c0ad-4ec7-b699-031c5a7f3c6d"
      "eu-es"    = "r050-a8be0502-3456-481d-b8fc-3286868a0378"
      "us-south" = "r006-a3fad2db-4cd2-4b9b-a867-376ca5f52653"
      "jp-tok"   = "r022-ae0d68af-893a-415d-9627-4e82ccce71c4"
      "jp-osa"   = "r034-1efa6e86-452b-43d3-9458-8d8f10f5042f"
      "au-syd"   = "r026-7999bfa9-267e-4b6e-8d4b-8c480d52ad0d"
      "br-sao"   = "r042-4de43c7f-1ba6-4444-94ca-0f985706c90a"
      "ca-tor"   = "r038-974d90c7-8343-412a-aa22-bb9f167851e6"
    },
    "hpcc-sym732-win2016-v1-5" = {
      "eu-gb"    = "r018-ef7df462-02fb-4019-85c0-56dddcbb57fc"
      "eu-de"    = "r010-234e8178-c80e-4803-8504-11be5188f115"
      "us-east"  = "r014-66f44c9b-563c-4ff0-bbc0-7ca7b1a511fd"
      "us-south" = "r006-18c56e1d-557d-47fe-9f47-a7d539b50859"
      "jp-tok"   = "r022-27111757-4463-4c44-93ce-593586fc3a66"
      "jp-osa"   = "r034-8571b369-3439-4372-bd0a-017befc8d7ec"
      "au-syd"   = "r026-748b6af1-bbe4-4846-8490-0006c58e9236"
      "br-sao"   = "r042-884945d4-abfc-4bb2-be7c-43591944ba55"
      "ca-tor"   = "r038-a04059b4-ce5d-46fc-ae23-a3e0b234c2c0"
    },
    "hpcc-sym732-win2022-v2" = {
      "eu-gb"    = "r018-3fc10d77-ebfa-45c3-beae-9a1428add6b2"
      "eu-de"    = "r010-cb9872e7-8185-4a2e-b4a4-468881f4c407"
      "us-east"  = "r014-a0e73894-c07d-4772-bd58-9099e1158517"
      "us-south" = "r006-e7958e7e-937b-4439-ab1d-8d107fbefb10"
      "jp-tok"   = "r022-e88214c8-e564-4974-bed9-6d44f63fb796"
      "jp-osa"   = "r034-8a122a56-86cb-4ec2-b9f9-93f707e92c89"
      "au-syd"   = "r026-fa8947e5-9dc4-4002-8104-c68ef5f35b3e"
      "br-sao"   = "r042-2f6334a6-94ca-4cb3-9db2-201d2b4887dd"
      "ca-tor"   = "r038-fbf26997-414a-4b44-84f4-0c351722259f"
    }
  }
}
