# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.1.9.3 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-sym732-win2016-v1-2" = {    
      "eu-gb"    = "r018-57a5be6b-b036-4a97-9abd-60f39e701bc9"
      "eu-de"    = "r010-19349651-5d90-4a91-bb41-7183872724f4"
      "us-east"  = "r014-4ece9a24-a689-463e-ac20-8c181a8cf2aa"
      "us-south" = "r006-5c24ce36-9ca9-4d68-8536-dd1f8a46ce96"
      "jp-tok"   = "r022-25c8772b-71e2-4e94-8d0d-c1f4f8fd413b"
      "jp-osa"   = "r034-581b904f-b27a-4792-9492-1f25b3fa65b0"
      "au-syd"   = "r026-9e6c675a-a0ba-483c-9913-8563e77238f8"
      "br-sao"   = "r042-9d711a6f-30fa-41b9-880c-a27b5943fe3b"
      "ca-tor"   = "r038-83be02d3-122d-41b3-a36b-376200ddf638"
    },
    "hpcc-symp732-scale5193-rhel88-v1-7" = {
      "eu-gb"    = "r018-14a32e7b-9496-4f5a-848a-c101bcac4cd1"
      "eu-de"    = "r010-3f01a2b0-946a-4079-b0f6-554f081091c8"
      "us-east"  = "r014-c9b52f0b-1155-4016-a477-7d658c84c37a"
      "us-south" = "r006-822c001e-e0f0-44b4-9bbf-3503347b64b9"
      "jp-tok"   = "r022-c46d1b0c-fce5-43f8-ab7d-e76fdff87db0"
      "jp-osa"   = "r034-f0627b8d-3311-4971-98c0-3d8b525db5ac"
      "au-syd"   = "r026-d8cd2667-30df-4a9b-a3f6-15f104112778"
      "br-sao"   = "r042-585a1228-5096-41c1-83cc-6b020f1fae2c"
      "ca-tor"   = "r038-80677ee4-723b-475a-9024-ff6df3f910b1"
    }
  }
}