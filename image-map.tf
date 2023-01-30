# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
locals {
  image_region_map = {
    "hpcc-symp731-scale5151-rhel84-v1-4" = {
      "ca-tor"  = "r038-092885d7-2588-47f1-9005-9187a5c6d5f4"
      "br-sao"  = "r042-a3198dad-1ff4-4b7a-adb1-a2da0df80e03"
      "us-east" = "r014-a88acfc5-6196-4a4a-8bcb-a4e28251c6f6"
      "us-south"= "r006-38dde0fe-b09c-4899-b269-a0e6f3814c7a"
      "jp-osa"  = "r034-9d190fca-8320-4074-aa98-949e25825730"
      "jp-tok"  = "r022-454c0eb2-1089-494f-86a9-d7d055c0879e"
      "au-syd"  = "r026-f6a6734c-1182-4c8a-9f2e-90ebd4588e98"
      "eu-de"   = "r010-be77876b-fef7-4977-ab06-c190f84bc691"
      "eu-gb"   = "r018-cee3dfa2-811a-4fe7-bdf6-cf7b6d133db8"
    },
    "hpcc-sym731-win2016-10oct22-v1" = {  
      "ca-tor"  = "r038-74251e18-0a8b-4eea-b4ab-f2a52d3d78c7"
      "br-sao"  = "r042-25aa73c7-ca44-4aa3-94d6-7f01c3c98804"
      "us-east" = "r014-d5ee150e-7103-468d-847c-08258b8e16c5"
      "us-south"= "r006-3f250809-d1b3-4f1c-b629-ce16cfb34e9d" 
      "jp-osa"  = "r034-c37fef8a-cf0b-415a-b5f0-dad7fbd60b14"
      "jp-tok"  = "r022-1806238e-107d-4955-a481-153e0cbd8fa9"
      "au-syd"  = "r026-c1cb73af-b8c6-498c-ba0a-f2acb3f928d1"
      "eu-de"   = "r010-f49b523f-96bc-413b-b1a0-0f710a7c7c99"
      "eu-gb"   = "r018-a43cb221-e893-4b2d-af96-c4efb79241a9"
    }
  }
}  