# This mapping file has entries for symphony images which support both the scenarios (scale enabled or disabled)
# These are images for computes nodes (primary, secondary, worker nodes etc)
# The custom images are installed with Symphony 7.3.2 and scale 5.1.9.3 versions
# These images has preconfiguration files to install the required packages on bare metal nodes, since baremetal server doesn't support custom images

locals {
  image_region_map = {
    "hpcc-sym732-win2016-v1-3" = {
      "eu-gb"    = "r018-f5864398-0ff5-4a04-a5ff-90f17f5297e7"
      "eu-de"    = "r010-a68efd6b-a0c2-4948-acc6-037e50821c63"
      "us-east"  = "r014-f2c1d189-b92d-4b7d-bd97-31153bb74fb9"
      "us-south" = "r006-b65c1a4a-e373-4643-bb74-8b3734a47550"
      "jp-tok"   = "r022-b73e316a-efc8-431d-9b84-15609d18aecb"
      "jp-osa"   = "r034-88a84bf1-6d35-49e3-8100-7e6a6b7c6d07"
      "au-syd"   = "r026-1f3e1d74-26bb-4f05-a4e7-6bbbde201e89"
      "br-sao"   = "r042-84dbc89f-d2cb-4c92-8bac-30f14cb375b2"
      "ca-tor"   = "r038-68321f3b-2819-4959-ac57-d5fc714a78c5"
    },
    "hpcc-symp732-scale5201-rhel88-v2" = {
      "eu-gb"    = "r018-90a9a05e-6862-4c32-b6ee-613379c10457"
      "eu-de"    = "r010-b1b12d1b-32a4-4d48-926a-c33ea1bd2aef"
      "us-east"  = "r014-49b31162-756f-4f46-b86e-1bf14cb9b535"
      "us-south" = "r006-3afa3867-e2f6-4fa0-8aab-7fd2a617ef01"
      "jp-tok"   = "r022-ad1d16d1-7e6f-4eb2-b69c-3cb2ef90d89d"
      "jp-osa"   = "r034-ff9c088b-3f41-414c-a336-424561ddc894"
      "au-syd"   = "r026-9b4b9440-dcea-4cdb-8b57-e7b4f30aa4dc"
      "br-sao"   = "r042-f5cdac24-d811-49fb-a3e6-477cc204e585"
      "ca-tor"   = "r038-abddf6af-89d2-4527-958f-446fb2c11943"
    }
  }
}