# This mapping file has entries for scale storage node images
locals {
  scale_image_region_map = {
    "hpcc-scale512-rhel82-jan0522-v1" = {
      "br-sao"   =  "r042-05fef64d-23f2-4a31-bb43-ebb18d91c54b"
      "ca-tor"   =  "r038-b353f42d-ebd2-42b3-8e1c-05d2de9bdfef"
      "au-syd"   =  "r026-7ab0e0ad-c524-4b6a-9f96-67570aac819a"
      "jp-tok"   =  "r022-58b11416-080a-4422-a16b-802c949434a3"
      "jp-osa"   =  "r034-001b70f1-ddbb-4565-ae3a-f0b41b27ea79"
      "us-south" =  "r006-11941235-50b9-4f50-988c-9d3773e1a3af"
      "us-east"  =  "r014-382a185a-4a42-4f10-82bc-8e09e1697707"
      "eu-de"    =  "r010-bae02de4-1233-4036-8dc1-32610f710e93"
      "eu-gb"    =  "r018-6abd744f-bd6e-4e0a-be17-3852f859407d"
    }
  }
}