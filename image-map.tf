# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
locals {
  image_region_map = {
    "hpcc-symp731-scale5131-rhel84-25may2022-v1" = {
      "ca-tor" = "r038-303b6837-0767-4abc-9950-7e59c5ff1344"
      "br-sao" = "r042-f4860c73-e883-4ea5-8b92-c81706d2e390"
      "us-east" = "r014-45c37ae5-726c-4d9b-b567-7ba39ebd60eb"
      "us-south"= "r006-c8ce7b6b-b40b-4f12-8ce5-0ba947a26524"
      "jp-osa" = "r034-638b1f1e-84ff-43a8-acc3-ce864c9d6af5"
      "jp-tok" = "r022-afed1834-572a-4937-9200-d5c25553feef"
      "au-syd" = "r026-b58c6aa4-684b-4fe3-817c-32faa3157082"
      "eu-de" = "r010-90a603fa-4881-490d-8d1e-bb9ba127a321"
      "eu-gb" = "r018-c2dc9947-acf0-47a3-bf91-ee73c27b0a66"
    }
  }
}
