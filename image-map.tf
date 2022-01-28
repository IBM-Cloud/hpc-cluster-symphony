# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
locals {
  image_region_map = {
    "hpcc-sym731-scale512-rhel82-jan1222-v1"  = {
      "eu-gb"    = "r018-76be0105-d2a6-43d3-9bc1-cea1d5536ef4"
      "eu-de"    = "r010-48156708-066f-4b26-9f2f-a505c7cfb5a1"
      "us-east"  = "r014-350b51b1-6f12-4573-858a-704604e285c1"
      "us-south" = "r006-b7818ae6-6791-4131-a25f-744eab8163db"
      "jp-tok"   = "r022-4059104f-f9f5-499f-b773-854dd134026f"
      "jp-osa"   = "r034-ecf45a92-f52e-4f19-84cc-5cc49ef64777"
      "au-syd"   = "r026-87f58e51-c12a-4497-a312-86e4ff42cc98"
      "br-sao"   = "r042-2f6fd6e6-93f3-49df-a2bf-582090f5731e"
      "ca-tor"   = "r038-39513311-89a8-4371-8c9d-b3c8ff1d5b76"
    }
  }
}
