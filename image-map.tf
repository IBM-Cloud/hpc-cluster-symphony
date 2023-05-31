# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.1.7.0 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-symp732-scale5170-rhel86-v1-5" = {
      "ca-tor"  = "r038-2f38af7d-fe95-47f6-9b74-fb3891976711"
      "br-sao"  = "r042-549f1984-a34a-4cf8-a02b-e2bc84689d92"
      "us-east" = "r014-7a55de08-6395-4a72-8676-7945047cda13"
      "us-south"= "r006-bfaa25a3-43ed-4fba-8488-c9fcdc6d24a6"
      "jp-osa"  = "r034-f96223fc-8d23-472e-a43e-51fb4c275c33"
      "jp-tok"  = "r022-3f8eaf0d-1506-4c07-9191-dfb09c7f662e"
      "au-syd"  = "r026-1aa3139a-c643-4bb1-a5e2-882e3a30b0c7"
      "eu-de"   = "r010-fd217f16-3f74-4f29-b35f-71b2978e1bc3"
      "eu-gb"   = "r018-e2869eb3-6b40-468f-b949-9b2da6bc53ac"
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