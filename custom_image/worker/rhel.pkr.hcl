

source "ibmcloud-vpc" "itself" {
  api_key             = var.ibm_api_key // pragma: allowlist secret
  region              = var.vpc_region
  subnet_id           = var.vpc_subnet_id
  resource_group_id   = var.resource_group_id
  vsi_base_image_name = var.source_image_name
  vsi_profile         = "bx2-2x8"
  vsi_interface       = "public"
  image_name          = var.image_name
  communicator        = "ssh"
  ssh_username        = "root"
  ssh_port            = 22
  timeout             = "60m"
}
