###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.2.1.1 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-symp732-scale5211-rhel810-v1" = {
      "eu-gb"    = "r018-a8822ccc-3a1f-4247-ab85-7b14776c2c05"
      "eu-de"    = "r010-201368de-6459-4cd7-bf86-ea4ef9a3b3bb"
      "us-east"  = "r014-e17978cb-2e07-473c-9894-c10ed6c47c4d"
      "us-south" = "r006-d1f00f48-2314-4217-962c-2dcacc291544"
      "jp-tok"   = "r022-77117be4-959e-41b5-968e-7a3b36c9905e"
      "jp-osa"   = "r034-713550a1-b964-492b-b9fc-0a98ce1e70fd"
      "au-syd"   = "r026-ebde8111-2d61-4e54-8771-276145af2983"
      "br-sao"   = "r042-8a6efd8c-1665-47ca-872b-47c0db6ab259"
      "ca-tor"   = "r038-fa8d01b6-0ab6-43cf-af4f-c9fc330b6946"
    },
    "hpcc-sym732-win2016-v1-4" = {
      "eu-gb"    = "r018-7550fe0b-2370-47d2-b708-ece40b106451"
      "eu-de"    = "r010-b48ace46-de17-41cb-b2e9-170845629575"
      "us-east"  = "r014-166edb58-4761-479c-aac4-32e6fcad9cfe"
      "us-south" = "r006-b63f8b4c-3c47-4479-a137-597f93bec14b"
      "jp-tok"   = "r022-7ac7e496-2af3-46c6-be22-fb349ead977f"
      "jp-osa"   = "r034-ed62284f-33f0-4f1e-810a-ee9afdf8dcd9"
      "au-syd"   = "r026-dd9a4dbd-4d5b-4521-9b52-97f17b983bfc"
      "br-sao"   = "r042-26b1a376-d5f4-4f80-b88e-d3e89bc8c634"
      "ca-tor"   = "r038-dbb3a295-ceb1-4f03-999c-1e5c836000d1"
    },
    "hpcc-sym732-win2022-v1" = {
      "eu-gb"    = "r018-7bdbc70d-4769-4246-ad2c-0e134ece56ba"
      "eu-de"    = "r010-b60031a8-b1ec-434a-907e-95cdf5e25ee9"
      "us-east"  = "r014-a50b4561-7db6-478f-96e7-138a7d0afbde"
      "us-south" = "r006-ce5b3b47-ed9d-4c5e-9916-c43134d63710"
      "jp-tok"   = "r022-1c52066b-472b-43d9-95f0-f4b6fd8e5a0a"
      "jp-osa"   = "r034-a157c50c-cbbe-4118-b506-d7b43690fb9d"
      "au-syd"   = "r026-1a143ab9-f43c-477e-bbe6-209f27b4ac1a"
      "br-sao"   = "r042-69152a39-708c-4bea-b477-3f7e6e5213aa"
      "ca-tor"   = "r038-1da71a3a-ee9b-45ef-bacc-e09594753c9a"
    }
  }
}
