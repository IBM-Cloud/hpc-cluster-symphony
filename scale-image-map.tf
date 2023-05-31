# This mapping file has entries for scale storage node images. The Scale version used on these images are 5.1.7.0
locals {
  scale_image_region_map = {
    "hpcc-scale5170-rhel86": {
      "eu-de"    = "r010-5ee41298-1903-4236-a633-5cc32fe9295e",
      "us-east"  = "r014-ecf6d8e5-779a-4c75-a1b7-061300df8542",
      "us-south" = "r006-57ab2097-d2f1-4b96-bc7e-01123f9fd612",
      "jp-tok"   = "r022-69366b38-025a-4be7-92d1-5e3e2435d7f9"
      "eu-gb"    = "r018-dab69bd8-28fd-4bf3-853e-4836ea7236d4",
      "jp-osa"   = "r034-22001bab-e53f-4cd5-9b9d-ac3409fcb33b",
      "ca-tor"   = "r038-64c151bf-5063-405f-b013-873129be44df",
      "au-syd"   = "r026-94572c9a-585c-4e33-856f-45dad3a79db4",
      "br-sao"   = "r042-49b57b78-d35c-46a6-89cc-3215d81cb245"
    }
  }
}