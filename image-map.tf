# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.1.7.0 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-symp732-scale5190-rhel88-v1-6" = {
      "ca-tor"  = "r038-d1253b36-da42-4053-9faa-cc0f2b294596"
      "br-sao"  = "r042-ca8f2d46-0eb0-45b3-b2cd-44d9d27d151c"
      "us-east" = "r014-6bab86dc-2417-4194-a32d-2a15e426e3d3"
      "us-south"= "r006-cc1957ce-2a0b-484a-bccc-690dc8ab2491"
      "jp-osa"  = "r034-af09538b-166f-4bf5-a81e-3b1a20e7fd27"
      "jp-tok"  = "r022-773ddcf9-ca5d-4200-a7bb-466ada3584ac"
      "au-syd"  = "r026-71cff7b5-ddc4-40ee-a999-70ff00097f9d"
      "eu-de"   = "r010-770ae090-d60f-44a9-b985-f7f57386ad6c"
      "eu-gb"   = "r018-8ed688c9-5c59-45a5-aacb-f586be3b958f"
    },
    "hpcc-sym732-win2016-v1-1" = {  
      "ca-tor"  = "r038-02785dbe-ac57-4668-b65b-0039960c87af"
      "br-sao"  = "r042-1d4c4ffc-15a7-4354-bd42-dc8aaa094608"
      "us-east" = "r014-a26e9cd9-a0f1-4b79-a8b5-da9366c6a430"
      "us-south"= "r006-29e2c380-19df-4df4-924b-369c4ff65b86" 
      "jp-osa"  = "r034-c02a64dd-3c08-4085-b34b-f2478b479677"
      "jp-tok"  = "r022-72297c63-0cca-45c5-8e35-b2b372e77731"
      "au-syd"  = "r026-770e4fb6-789a-4a91-938c-87416818be65"
      "eu-de"   = "r010-4505370c-cb3f-4f5b-9154-72599421d0f1"
      "eu-gb"   = "r018-734839bf-2512-46db-a4f3-9fdc9efa4ba3"
    }
  }
}