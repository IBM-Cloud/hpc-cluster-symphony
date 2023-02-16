###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# IBM Cloud Provider
# Docs are available here, https://cloud.ibm.com/docs/terraform?topic=terraform-tf-provider#store_credentials
# Download IBM Cloud Provider binary from release page. https://github.com/IBM-Cloud/terraform-provider-ibm/releases
# And copy it to $HOME/.terraform.d/plugins/terraform-provider-ibm_v1.2.4

# if dedicated_host_enabled == true, determine the profile name of dedicated hosts and the number of them from worker_node_min_count and worker profile class
locals {
  region_name = join("-", slice(split("-", var.zone), 0, 2))
# 1. calculate required amount of compute resources using the same instance size as dynamic workers
  cpu_per_node = var.worker_node_type == "vsi" || var.windows_worker_node ? tonumber(data.ibm_is_instance_profile.worker[0].vcpu_count[0].value) : null
  mem_per_node = var.worker_node_type == "vsi" || var.windows_worker_node ? tonumber(data.ibm_is_instance_profile.worker[0].memory[0].value) : null
  required_cpu = var.worker_node_type == "vsi" || var.windows_worker_node ? var.worker_node_min_count * local.cpu_per_node : null
  required_mem = var.worker_node_type == "vsi" || var.windows_worker_node ? var.worker_node_min_count * local.mem_per_node : null

# 2. get profiles with a class name passed as a variable (NOTE: assuming VPC Gen2 provides a single profile per class)
  dh_profiles      = var.dedicated_host_enabled ? [
    for p in data.ibm_is_dedicated_host_profiles.worker[0].profiles: p if p.class == local.profile_str[0]
  ]: []
  dh_profile_index = (var.worker_node_type == "vsi" || var.windows_worker_node) && (local.dh_profiles) == 0 ? "Profile class ${local.profile_str[0]} for dedicated hosts does not exist in ${local.region_name}. Check available class with `ibmcloud target -r ${local.region_name}; ibmcloud is dedicated-host-profiles` and retry other worker_node_instance_type wtih the available class.": 0
  dh_profile       = var.dedicated_host_enabled ? local.dh_profiles[local.dh_profile_index]: null
  dh_cpu           = var.dedicated_host_enabled ? tonumber(local.dh_profile.vcpu_count[0].value): 0
  dh_mem           = var.dedicated_host_enabled ? tonumber(local.dh_profile.memory[0].value): 0

# 3. calculate the number of dedicated hosts
  dh_count = var.dedicated_host_enabled && (var.worker_node_type == "vsi" || var.windows_worker_node) ? ceil(max(local.required_cpu / local.dh_cpu, local.required_mem / local.dh_mem)): 0

# 4. calculate the possible number of workers, which is used by the pack placement
  dh_worker_count = var.dedicated_host_enabled ? floor(min(local.dh_cpu / local.cpu_per_node, local.dh_mem / local.mem_per_node)): 0
  remove_sg_rule_script_path = "${path.module}/resources/common/remove_security_rule.py"

  // Stock image is used for the creation of login and nfs_storage node.
  stock_image_name = "ibm-redhat-8-6-minimal-amd64-1"
}

locals {
  script_map = {
    "storage"           = file("${path.module}/scripts/user_data_input_storage.tpl")
    "primary"           = file("${path.module}/scripts/user_data_input_primary.tpl")
    "management_node"   = file("${path.module}/scripts/user_data_input_management_node.tpl")
    "worker"            = file("${path.module}/scripts/user_data_input_worker.tpl")
    "spectrum_storage"  = file("${path.module}/scripts/user_data_spectrum_storage.tpl")
    "windows"           = file("${path.module}/scripts/windows_worker_user_data.ps1")
  }
  storage_template_file = lookup(local.script_map, "storage")
  primary_template_file = lookup(local.script_map, "primary")
  management_node_template_file  = lookup(local.script_map, "management_node")
  worker_template_file  = lookup(local.script_map, "worker")
  spectrum_storage_template_file = lookup(local.script_map, "spectrum_storage")
  tags                  = ["hpcc", var.cluster_prefix]
  profile_str           = var.worker_node_type == "vsi" || var.windows_worker_node ? split("-", data.ibm_is_instance_profile.worker[0].name) : split("-", data.ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile[0].name)
  profile_list          = var.worker_node_type == "vsi" || var.windows_worker_node ? split("x", local.profile_str[1]) : split("x", local.profile_str[2])
  hf_ncores             = var.worker_node_type == "vsi" || var.windows_worker_node ? tonumber(local.profile_list[0]) / 2 : tonumber(local.profile_list[0]) / 2
  mem_in_mb             = var.worker_node_type == "vsi" || var.windows_worker_node ? tonumber(local.profile_list[1]) * 1024 : tonumber(local.profile_list[1]) * 1024
  hf_max_num            = var.worker_node_max_count > var.worker_node_min_count ? var.worker_node_max_count - var.worker_node_min_count : 0
  cluster_name          = var.cluster_id
  ssh_key_list          = split(",", var.ssh_key_name)
  ssh_key_id_list       = [
    for name in local.ssh_key_list:
    data.ibm_is_ssh_key.ssh_key[name].id
  ]

  // Check whether an entry is found in the mapping file for the given symphony compute node image
  image_mapping_entry_found = contains(keys(local.image_region_map), var.image_name)
  new_image_id = local.image_mapping_entry_found ? lookup(lookup(local.image_region_map, var.image_name), local.region_name) : "Image not found with the given name"

  // Use existing VPC if var.vpc_name is not empty
  vpc_name                  = var.vpc_name == "" ? module.vpc.*.name[0] : data.ibm_is_vpc.existing_vpc.*.name[0]
}

data "template_file" "storage_user_data" {
  template = local.storage_template_file
  vars = {
    hf_cidr_block = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
  }
}

data "template_file" "primary_user_data" {
  template = local.primary_template_file
  vars = {
    vpc_apikey_value     = var.api_key
    image_id             = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
    subnet_id            = module.subnet.subnet_id
    security_group_id    = module.sg.sg_id
    resource_group_id    = data.ibm_resource_group.rg.id
    sshkey_id            = data.ibm_is_ssh_key.ssh_key[local.ssh_key_list[0]].id
    region_name          = data.ibm_is_region.region.name
    zone_name            = data.ibm_is_zone.zone.name
    vpc_id               = data.ibm_is_vpc.vpc.id
    hf_cidr_block        = module.subnet.ipv4_cidr_block
    hf_profile           = var.worker_node_type == "vsi" || var.windows_worker_node ? data.ibm_is_instance_profile.worker[0].name : data.ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile[0].name
    hf_ncores            = local.hf_ncores
    hf_mem_in_mb         = local.mem_in_mb
    hf_max_num           = local.hf_max_num
    storage_ips          = join(" ", local.storage_ips)
    cluster_id           = local.cluster_name
    host_prefix          = var.cluster_prefix
    mgmt_count           = var.management_node_count
    ego_host_role        = "primary"
    hyperthreading       = var.hyperthreading_enabled
    cluster_cidr         = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
    temp_public_key      = local.vsi_login_temp_public_key
    windows_worker_node  = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
  }
}

data "template_file" "secondary_user_data" {
  template = local.management_node_template_file
  vars = {
    vpc_apikey_value     = var.api_key
    hf_cidr_block        = module.subnet.ipv4_cidr_block
    storage_ips          = join(" ", local.storage_ips)
    cluster_id           = local.cluster_name
    host_prefix          = var.cluster_prefix
    mgmt_count           = var.management_node_count
    ego_host_role        = "secondary"
    cluster_cidr         = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
    temp_public_key     = local.vsi_login_temp_public_key
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
  }
}

data "template_file" "management_node_user_data" {
  template = local.management_node_template_file
  vars = {
    vpc_apikey_value     = var.api_key
    hf_cidr_block        = module.subnet.ipv4_cidr_block
    storage_ips          = join(" ", local.storage_ips)
    cluster_id           = local.cluster_name
    host_prefix          = var.cluster_prefix
    mgmt_count           = var.management_node_count
    ego_host_role        = "management_node"
    cluster_cidr         = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
    temp_public_key     = local.vsi_login_temp_public_key
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
  }
}

data "template_file" "worker_user_data" {
  template = local.worker_template_file
  vars = {
    storage_ips         = join(" ", local.storage_ips)
    cluster_id          = local.cluster_name
    mgmt_count          = var.management_node_count
    hyperthreading      = var.hyperthreading_enabled
    cluster_cidr        = module.subnet.ipv4_cidr_block
    spectrum_scale      = var.spectrum_scale_enabled
    temp_public_key     = local.vsi_login_temp_public_key
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
  }
}

// template file for scale storage nodes
data "template_file" "scale_storage_user_data" {
  template = local.spectrum_storage_template_file
  vars = {
    ego_host_role       = "scale_storage"
    storage_ips         = join(" ", local.storage_ips)
    cluster_id          = local.cluster_name
    mgmt_count          = var.management_node_count
    hyperthreading      = var.hyperthreading_enabled
    cluster_cidr        = module.subnet.ipv4_cidr_block
    spectrum_scale      = var.spectrum_scale_enabled
    temp_public_key     = local.vsi_login_temp_public_key
    worker_node_type     = var.worker_node_type
  }
}

data "template_file" "login_user_data" {
  template = <<EOF
#!/usr/bin/env bash
echo "${local.vsi_login_temp_public_key}" >> ~/.ssh/authorized_keys
EOF
}

/*
Infrastructure creation related steps
*/

// This module creates a new VPC resource only if var.vpc_name is empty i.e( If any VPC name is provided, that vpc will be considered for all resource creation)
module "vpc" {
  source    = "./resources/ibmcloud/network/vpc"
  count     = var.vpc_name == "" ? 1 : 0
  name      = "${var.cluster_prefix}-vpc"
  resource_group = data.ibm_resource_group.rg.id
  vpc_address_prefix_management = "manual"
  tags      = local.tags
}
// This module creates a vpc_address_prefix as we are now using custom CIDR range for VPC creation
module "vpc_address_prefix" {
  count        = var.vpc_name == "" ? 1 : 0
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = data.ibm_is_vpc.vpc.id
  address_name = format("%s-addr", var.cluster_prefix)
  zones        = var.zone
  cidr_block   = var.vpc_cidr_block
}

module "public_gw" {
  source         = "./resources/ibmcloud/network/public_gw"
  public_gw_name = "${var.cluster_prefix}-gateway"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = data.ibm_is_zone.zone.name
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
}

# This module is used to create subnet, which is used to create both login node. The subnet CIDR range is passed manually based on the user input from variable file
module "login_subnet" {
  source            = "./resources/ibmcloud/network/login_subnet"
  login_subnet_name = "${var.cluster_prefix}-login-subnet"
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  ipv4_cidr_block   = var.vpc_cluster_login_private_subnets_cidr_blocks[0]
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
  depends_on = [module.vpc_address_prefix]
}

# This module is used to create subnet, which is used to create both worker and storage node. The subnet CIDR range is passed manually based on the user input from variable file
module "subnet" {
  source            = "./resources/ibmcloud/network/subnet"
  subnet_name       = "${var.cluster_prefix}-subnet"
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  ipv4_cidr_block   = var.vpc_cluster_private_subnets_cidr_blocks[0]
  public_gateway    = module.public_gw.public_gateway_id
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
  depends_on = [module.vpc_address_prefix]
}

// The module is used to create a security group for only login nodes
module "login_sg" {
  source         = "./resources/ibmcloud/security/login_sg"
  sec_group_name = "${var.cluster_prefix}-login-sg"
  resource_group = data.ibm_resource_group.rg.id
  vpc            = data.ibm_is_vpc.vpc.id
  tags           = local.tags
}

module "login_inbound_security_rules" {
  source             = "./resources/ibmcloud/security/login_sg_inbound_rule"
  remote_allowed_ips = var.remote_allowed_ips
  group              = module.login_sg.sec_group_id
  depends_on         = [module.login_sg]
}


module "login_outbound_security_rule" {
  source    = "./resources/ibmcloud/security/login_sg_outbound_rule"
  group     = module.login_sg.sec_group_id
  remote    = module.sg.sg_id
}

// The module is used to create a security group for all the nodes (i.e.controller/controller-candidate/worker-vsi/worker-baremetal/storage).
module "sg" {
  source          = "./resources/ibmcloud/security/security_group"
  sec_group_name  = "${var.cluster_prefix}-sg"
  vpc             = data.ibm_is_vpc.vpc.id
  resource_group  = data.ibm_resource_group.rg.id
  tags            = local.tags
}

module "inbound_sg_rule" {
  source    = "./resources/ibmcloud/security/security_group_inbound_rule"
  group     = module.sg.sg_id
  remote    = module.login_sg.sec_group_id
}

module "inbound_sg_ingress_all_local_rule" {
  source    = "./resources/ibmcloud/security/security_group_ingress_all_local"
  group     = module.sg.sg_id
  remote    = module.sg.sg_id
}

module "outbound_sg_rule" {
  source     = "./resources/ibmcloud/security/security_group_outbound_rule"
  group      = module.sg.sg_id
}
// The module is used to fetch the IP address of the schematics container and update the IP on security group rule
module "schematics_sg_tcp_rule" {
  source            = "./resources/ibmcloud/security/security_tcp_rule"
  security_group_id = module.login_sg.sec_group_id
  sg_direction      = "inbound"
  remote_ip_addr    = tolist([chomp(data.http.fetch_myip.response_body)])
  depends_on = [module.login_sg]
}

// The module is used to create the login/bastion node to access all other nodes in the cluster
module "login_vsi" {
  source          =  "./resources/ibmcloud/compute/login_vsi"
  vsi_name        = "${var.cluster_prefix}-login"
  image           = data.ibm_is_image.stock_image.id
  profile         = data.ibm_is_instance_profile.login.name
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = data.ibm_is_zone.zone.name
  keys            = local.ssh_key_id_list
  user_data       = data.template_file.login_user_data.rendered
  resource_group  = data.ibm_resource_group.rg.id
  tags            = local.tags
  subnet_id       = module.login_subnet.login_subnet_id
  security_group  = [module.login_sg.sec_group_id]
  depends_on      = [module.login_ssh_key,module.login_inbound_security_rules,module.login_outbound_security_rule]
}

#####################################################################
#                       IP ADDRESS MAPPING
#####################################################################
# LSF assumes all the node IPs are known before their startup.
# This causes a cyclic dependency, e.g., management_nodes must know their IPs
# before starting themselves. We resolve this by explicitly
# assigining IP addresses calculated by cidrhost(cidr_block, index).
#
# Input variables:
# nrM    == var.management_node_count
# nrMinW == var.worker_node_min_count
# nrMaxW == var.worker_node_max_count
#
# Address index range                        | Mapped nodes
# -------------------------------------------------------------------
# 0                  - 3                     | Reserved by IBM Cloud
# 4                  - 4                     | Storage node
# 5                  - (5 + nrM - 1)         | Management nodes
# (5 + nrM)          - (5 + nrM + nrMinW - 1)| Static worker nodes
# (5 + nrM + nrMinW) - (5 + nrM + nrMaxW - 1)| Dynamic worker nodes
#
# Details of reserved IPs:
# https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc
#
# We also reserve four IPs for VPN
# https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-create-gateway
#####################################################################

locals {
  storage_ips = [
    for idx in range(1) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + 4)
  ]
  spectrum_storage_node_count = var.spectrum_scale_enabled ? var.scale_storage_node_count : 0
  spectrum_storage_ips = [
    for idx in range(local.spectrum_storage_node_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + 4 + length(local.storage_ips))
  ]
  management_node_ips = [
    for idx in range(var.management_node_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + 4 + length(local.storage_ips) + length(local.spectrum_storage_ips))
  ]

  worker_ips = [
    for idx in range(var.worker_node_min_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + 4 + length(local.storage_ips) + length(local.spectrum_storage_ips) +length(local.management_node_ips))
  ]

  vsi_login_temp_public_key = module.login_ssh_key.public_key
  peer_cidr_list = var.vpn_enabled ? split(",", var.vpn_peer_cidrs): []
}

module "nfs_storage" {
  source            = "./resources/ibmcloud/compute/nfs_storage_vsi"
  count             = 1
  vsi_name          = "${var.cluster_prefix}-storage-${count.index}"
  image             = data.ibm_is_image.stock_image.id
  profile           = data.ibm_is_instance_profile.storage.name
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  keys              = local.ssh_key_id_list
  resource_group    = data.ibm_resource_group.rg.id
  user_data         = "${data.template_file.storage_user_data.rendered} ${file("${path.module}/scripts/user_data_storage.sh")}"
  subnet_id         = module.subnet.subnet_id
  security_group    = [module.sg.sg_id]
  volumes           = [module.nfs_volume.nfs_volume_id]
  primary_ipv4_address = local.storage_ips[count.index]
  tags              = local.tags
  depends_on        = [module.inbound_sg_ingress_all_local_rule,module.inbound_sg_ingress_all_local_rule,module.outbound_sg_rule]
}

module "primary_vsi" {
  source            = "./resources/ibmcloud/compute/primary_vsi"
  count             = 1
  vsi_name          = "${var.cluster_prefix}-primary-${count.index}"
  image             = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile           = data.ibm_is_instance_profile.management_node.name
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  keys              = local.ssh_key_id_list
  resource_group    = data.ibm_resource_group.rg.id
  user_data         = "${data.template_file.primary_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  subnet_id         = module.subnet.subnet_id
  security_group    = [module.sg.sg_id]
  primary_ipv4_address = local.management_node_ips[count.index]
  tags              = local.tags
  depends_on = [
    module.login_ssh_key,
    module.nfs_storage,
    module.inbound_sg_rule,
    module.inbound_sg_ingress_all_local_rule,
    module.outbound_sg_rule
  ]
}

locals {
  products = var.spectrum_scale_enabled ? "symphony,scale" : "symphony"
}

resource "null_resource" "entitlement_check" {
  connection {
    type                = "ssh"
    host                = module.primary_vsi[0].primary_network_interface
    user                = "root"
    private_key         = module.login_ssh_key.private_key
    bastion_host        = module.login_fip.floating_ip_address
    bastion_user        = "root"
    bastion_private_key = module.login_ssh_key.private_key
    timeout             = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "python3 /opt/IBM/cloud_entitlement/entitlement_check.py --products ${local.products} --icns ${var.ibm_customer_number}"
    ]
  }
  depends_on = [module.primary_vsi, module.login_fip, module.login_vsi]
}

module "secondary_vsi" {
  source          = "./resources/ibmcloud/compute/secondary_vsi"
  count           = var.management_node_count > 1 ? 1: 0
  vsi_name        = "${var.cluster_prefix}-secondary-${count.index}"
  image           = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile         = data.ibm_is_instance_profile.management_node.name
  vpc             = data.ibm_is_vpc.vpc.id
  zone            = data.ibm_is_zone.zone.name
  keys            = local.ssh_key_id_list
  resource_group  = data.ibm_resource_group.rg.id
  user_data       = "${data.template_file.secondary_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  subnet_id       = module.subnet.subnet_id
  security_group  = [module.sg.sg_id]
  primary_ipv4_address = local.management_node_ips[count.index + 1]
  tags            = local.tags
  depends_on = [
    module.nfs_storage,
    module.primary_vsi,
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_rule,
    module.outbound_sg_rule,
    null_resource.entitlement_check
  ]
}

module "management_node_vsi" {
  source           = "./resources/ibmcloud/compute/management_node_vsi"
  count            = var.management_node_count > 2 ? var.management_node_count - 2: 0
  vsi_name         = "${var.cluster_prefix}-management-node-${count.index}"
  image            = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile          = data.ibm_is_instance_profile.management_node.name
  vpc              = data.ibm_is_vpc.vpc.id
  zone             = data.ibm_is_zone.zone.name
  keys             = local.ssh_key_id_list
  resource_group   = data.ibm_resource_group.rg.id
  user_data        = "${data.template_file.management_node_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  subnet_id        = module.subnet.subnet_id
  security_group   = [module.sg.sg_id]
  primary_ipv4_address = local.management_node_ips[count.index + 2]
  tags              = local.tags
  depends_on = [
    module.nfs_storage,
    module.primary_vsi,
    module.secondary_vsi,
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_rule,
    module.outbound_sg_rule,
    null_resource.entitlement_check
  ]
}

// The module is used to create the spectrum scale storage node only when spectrum scale is enabled
module "spectrum_scale_storage" {
  source            = "./resources/ibmcloud/compute/scale_storage_vsi"
  count             = var.spectrum_scale_enabled == true ? var.scale_storage_node_count : 0
  vsi_name          = "${var.cluster_prefix}-scale-storage-${count.index}"
  image             = local.scale_image_mapping_entry_found ? local.scale_image_id : data.ibm_is_image.scale_image[0].id
  profile           = data.ibm_is_instance_profile.spectrum_scale_storage[0].name
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  keys              = local.ssh_key_id_list
  resource_group    = data.ibm_resource_group.rg.id
  user_data         = "${data.template_file.scale_storage_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  tags              = local.tags
  subnet_id         = module.subnet.subnet_id
  security_group    = [module.sg.sg_id]
  primary_ipv4_address = local.spectrum_storage_ips[count.index]
  depends_on        = [module.login_vsi,module.nfs_storage,module.primary_vsi,module.management_node_vsi,module.inbound_sg_rule, module.inbound_sg_ingress_all_local_rule, module.outbound_sg_rule]
}

// The module is used to create the compute vsi instance based on the type of node_type required for deployment
module "worker_vsi" {
  source           = "./resources/ibmcloud/compute/worker_vsi"
  count            = ( var.windows_worker_node ? 0 : (var.worker_node_type != "baremetal" ? var.worker_node_min_count : 0 ))
  #count  =  var.storage_type != "baremetal" ? var.worker_node_min_count : 0
  vsi_name         = "${var.cluster_prefix}-worker-${count.index}"
  image            = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile          = data.ibm_is_instance_profile.worker[0].name
  vpc              = data.ibm_is_vpc.vpc.id
  zone             = data.ibm_is_zone.zone.name
  keys             = local.ssh_key_id_list
  resource_group   = data.ibm_resource_group.rg.id
  user_data        = "${data.template_file.worker_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  dedicated_host   = var.dedicated_host_enabled ? module.dedicated_host[var.dedicated_host_placement == "spread" ? count.index % local.dh_count: floor(count.index / local.dh_worker_count)].dedicated_host_id: null
  subnet_id        = module.subnet.subnet_id
  security_group   = [module.sg.sg_id]
  primary_ipv4_address = local.worker_ips[count.index]
  tags             = local.tags
  depends_on = [
    module.nfs_storage,
    module.primary_vsi,
    module.secondary_vsi,
    module.management_node_vsi,
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_rule,
    module.outbound_sg_rule,
    null_resource.entitlement_check
  ]
}

// The module is used to create the compute baremetal server based on the type of node_type required for deployment
module "bare_metal_server" {
  source          = "./resources/ibmcloud/compute/bare_metal_server"
  count           = ( var.windows_worker_node ? 0 : (var.worker_node_type != "vsi" ? var.worker_node_min_count : 0))
  name            =  "${var.cluster_prefix}-bare-metal-server-${count.index}"
  profile         = data.ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile[0].name
  image           = data.ibm_is_image.baremetal_image.id
  zone            = data.ibm_is_zone.zone.name
  keys            = local.ssh_key_id_list
  vpc             = data.ibm_is_vpc.vpc.id
  resource_group  = data.ibm_resource_group.rg.id
  subnet          = module.subnet.subnet_id
  security_group  = [module.sg.sg_id]
  user_data       = "${data.template_file.worker_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  tags            = local.tags
  depends_on = [module.primary_vsi, module.secondary_vsi, module.management_node_vsi, module.inbound_sg_ingress_all_local_rule, module.inbound_sg_rule, module.outbound_sg_rule, module.spectrum_scale_storage]
}

module "nfs_volume" {
  source            = "./resources/ibmcloud/network/nfs_volume"
  nfs_name          = "${var.cluster_prefix}-vm-nfs-volume"
  profile           = data.ibm_is_volume_profile.nfs.name
  iops              = data.ibm_is_volume_profile.nfs.name == "custom" ? var.volume_iops : null
  capacity          = var.volume_capacity
  zone              = data.ibm_is_zone.zone.name
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
}

module "login_fip" {
  source            = "./resources/ibmcloud/network/floating_ip"
  floating_ip_name  = "${var.cluster_prefix}-login-fip"
  target_network_id = module.login_vsi.primary_network_interface
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
}

module "vpn" {
  source         = "./resources/ibmcloud/network/vpn"
  count          = var.vpn_enabled ? 1: 0
  name           = "${var.cluster_prefix}-vpn"
  resource_group = data.ibm_resource_group.rg.id
  subnet         = module.login_subnet.login_subnet_id
  mode           = "policy"
  tags           = local.tags
}

module "vpn_connection" {
  source          = "./resources/ibmcloud/network/vpn_connection"
  count           = var.vpn_enabled ? 1: 0
  name            = "${var.cluster_prefix}-vpn-conn"
  vpn_gateway     = module.vpn[count.index].vpn_gateway_id
  vpn_peer_address = var.vpn_peer_address
  vpn_preshared_key = var.vpn_preshared_key
  admin_state_up  = true
  local_cidrs     = [module.subnet.ipv4_cidr_block]
  peer_cidrs      = local.peer_cidr_list
}

module "ingress_vpn" {
  source    = "./resources/ibmcloud/security/vpn_ingress_sg_rule"
  count     = length(local.peer_cidr_list)
  group     = module.sg.sg_id
  remote    = local.peer_cidr_list[count.index]
}

module "dedicated_host_group" {
  source         = "./resources/ibmcloud/dedicated_host_group"
  count          = local.dh_count > 0 ? 1 : 0
  name           = "${var.cluster_prefix}-dh"
  class          = local.dh_profile.class
  family         = local.dh_profile.family
  zone           = data.ibm_is_zone.zone.name
  resource_group = data.ibm_resource_group.rg.id
}

// // The module is used to create the dedicated host for all the worker nodes to join the host
module "dedicated_host" {
  source         = "./resources/ibmcloud/dedicated_host"
  count          = local.dh_count
  name           = "${var.cluster_prefix}-dh-${count.index}"
  profile        = local.dh_profile.name
  host_group     = module.dedicated_host_group[0].dedicate_host_group_id
  resource_group = data.ibm_resource_group.rg.id
}

/*
Symphony Windows related steps
*/

locals{

  EgoUserName = "egoadmin"
  EgoPassword = "Symphony@123"

  windows_worker_node_prefix = "-w"
  
  windows_template_file = lookup(local.script_map, "windows")
  
  // Check whether an entry is found in the mapping file for the given symphony compute node image for windows
  windows_image_mapping_entry_found = contains(keys(local.image_region_map), var.windows_image_name)
  new_windows_image_id = local.windows_image_mapping_entry_found ? lookup(lookup(local.image_region_map, var.windows_image_name), local.region_name) : "Image not found with the given name"


}


data "template_file" "windows_worker_user_data" {
  count    = var.windows_worker_node ? var.worker_node_min_count : 0 
  template = local.windows_template_file
  vars = {
    storage_ip    = join(" ", local.storage_ips)
    EgoUserName   = local.EgoUserName
    EgoPassword   = local.EgoPassword
    computer_name = "${var.cluster_prefix}${local.windows_worker_node_prefix}${count.index}"
    cluster_id          = local.cluster_name
  }
}

data "ibm_is_image" "windows_worker_image" {
  name = var.windows_image_name
  count = local.windows_image_mapping_entry_found ? 0:1
}

// This module is used to invoke compute playbook, to setup windows worker.
module "invoke_windows_security_group_rules" {
  count                            = var.windows_worker_node ? 1 : 0
  source                           = "./resources/windows/security_group_rules"
  remote_allowed_ips               = var.remote_allowed_ips
  security_group                   = module.sg.sg_id
  depends_on                       = [module.sg]
}

resource "ibm_is_instance" "windows_worker" {
  count          = var.windows_worker_node ? var.worker_node_min_count : 0 
  name           = "${var.cluster_prefix}${local.windows_worker_node_prefix}${count.index}"
  image          = local.windows_image_mapping_entry_found ? local.new_windows_image_id : data.ibm_is_image.windows_worker_image[0].id
  profile        = data.ibm_is_instance_profile.worker[0].name
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = data.ibm_is_zone.zone.name
  keys           = local.ssh_key_id_list
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
  dedicated_host = var.dedicated_host_enabled ? module.dedicated_host[var.dedicated_host_placement == "spread" ? count.index % local.dh_count: floor(count.index / local.dh_worker_count)].dedicated_host_id: null
  user_data      = "${data.template_file.windows_worker_user_data[count.index].rendered}"
  primary_network_interface {
    name                 = "eth0"
    subnet               = module.subnet.subnet_id
    security_groups      = [module.sg.sg_id]
    primary_ipv4_address = local.worker_ips[count.index]
  }
  depends_on     = [module.login_ssh_key, module.primary_vsi, module.secondary_vsi, module.management_node_vsi,module.invoke_windows_security_group_rules]
}

/*
Spectrum Scale Integration related steps
*/

locals {
  // Check whether an entry is found in the scale mapping file for the given scale storage node image
  // scale image used for scale storage node.
  scale_image_mapping_entry_found = contains(keys(local.scale_image_region_map), var.scale_storage_image_name)
  scale_image_id = contains(keys(local.scale_image_region_map), var.scale_storage_image_name) ? lookup(lookup(local.scale_image_region_map, var.scale_storage_image_name), local.region_name) : "Image not found with the given name"
 
  // path for ansible playbook data configurations
  tf_data_path              =  "/tmp/.schematics/IBM/tf_data_path"
  tf_input_json_root_path   = null
  tf_input_json_file_name   = null

  // scale version installed on custom images.
  scale_version             = "5.1.5.1"

  // cloud platform as IBMCloud, required for ansible playbook.
  cloud_platform            = "IBMCloud"

  // path where ansible playbook will be cloned from github public repo.
  scale_infra_repo_clone_path = "/tmp/.schematics/IBM/ibm-spectrumscale-cloud-deploy"

  // collect ip of all scale storage nodes
  storage_vsis_1A_by_ip = module.spectrum_scale_storage[*].primary_network_interface

  // collect storage vsi's id for all scale storage nodes. Required for storage playbook.
  strg_vsi_ids_0_disks = module.spectrum_scale_storage.*.spectrum_scale_storage_id
  storage_vsi_ips_with_0_datadisks = local.storage_vsis_1A_by_ip
  vsi_data_volumes_count = 0
  // For NSD creation, create disk map of attached volumes on scale storage nodes.
  strg_vsi_ips_0_disks_dev_map = {
    for instance in local.storage_vsi_ips_with_0_datadisks :
    instance => local.vsi_data_volumes_count == 0 ? data.ibm_is_instance_profile.spectrum_scale_storage[0].disks.0.quantity.0.value == 1 ? ["/dev/vdb"] : ["/dev/vdb", "/dev/vdc"] : null
  }
  total_compute_instances = var.management_node_count + var.worker_node_min_count

  // list of all compute nodes id.
  compute_vsi_ids_0_disks = concat(module.primary_vsi.*.primary_id, module.secondary_vsi.*.secondary_id, module.management_node_vsi.*.management_id, module.worker_vsi.*.worker_id, module.bare_metal_server.*.bare_metal_server_id)
  // list of all compute vsi ips.
  compute_vsi_by_ip = concat(module.primary_vsi[*].primary_network_interface, module.secondary_vsi[*].primary_network_interface, module.management_node_vsi[*].primary_network_interface, module.worker_vsi[*].primary_network_interface, module.bare_metal_server[*].primary_network_interface)

  worker_bare_metal_server_osimage_name = "ibm-redhat-8-4-minimal-amd64-3"

}

data "ibm_is_image" "scale_image" {
  name = var.scale_storage_image_name
  count = local.scale_image_mapping_entry_found ? 0:1
}


data "ibm_is_instance_profile" "spectrum_scale_storage" {
  count = var.spectrum_scale_enabled ? 1 : 0
  name = var.scale_storage_node_instance_type
}

// generate new temporary ssh-key that will be used by ansible playbook to setup scale.
module "login_ssh_key" {
  source       = "./resources/scale_common/generate_keys"
  invoke_count = var.spectrum_scale_enabled ? 1:0
  tf_data_path = format("%s", local.tf_data_path)
}


// After completion of scale storage nodes, nodes need wait time to get in running state.
module "storage_nodes_wait" { ## Setting up the variable time as 180s for the entire set of storage nodes, this approach is used to overcome the issue of ssh and nodes unreachable
  count         = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source        = "./resources/scale_common/wait"
  wait_duration = var.TF_WAIT_DURATION
  depends_on    = [module.spectrum_scale_storage]
}

// After completion of compute nodes, nodes need wait time to get in running state.
module "compute_nodes_wait" { # # Setting up the variable time as 180s for the entire set of storage nodes, this approach is used to overcome the issue of ssh and nodes unreachable
  count         = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source        = "./resources/scale_common/wait"
  wait_duration = var.TF_WAIT_DURATION
  depends_on    = [module.primary_vsi,module.secondary_vsi,module.management_node_vsi, module.worker_vsi, module.bare_metal_server]
}

// This module is used to clone ansible repo for scale.
module "prepare_spectrum_scale_ansible_repo" {
  count      = var.spectrum_scale_enabled ? 1 : 0
  source     = "./resources/scale_common/git_utils"
  branch     = "scale_cloud"
  tag        = null
  clone_path = local.scale_infra_repo_clone_path
}

// This module is used to invoke storage playbook, to setup scale storage gpfs cluster.
module "invoke_storage_playbook" {
  count                            = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source                           = "./resources/scale_common/ansible_storage_playbook"
  region                           = local.region_name
  stack_name                       = format("%s.%s", var.cluster_prefix, "storage")
  tf_data_path                     = local.tf_data_path
  tf_input_json_root_path          = local.tf_input_json_root_path == null ? abspath(path.cwd) : local.tf_input_json_root_path
  tf_input_json_file_name          = local.tf_input_json_file_name == null ? join(", ", fileset(abspath(path.cwd), "*.tfvars*")) : local.tf_input_json_file_name
  bastion_public_ip                = module.login_fip.floating_ip_address
  bastion_os_flavor                = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key          = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  scale_infra_repo_clone_path      = local.scale_infra_repo_clone_path
  clone_complete                   = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  scale_version                    = local.scale_version
  filesystem_mountpoint            = var.scale_storage_cluster_filesystem_mountpoint
  filesystem_block_size            = var.scale_filesystem_block_size
  storage_cluster_gui_username     = var.scale_storage_cluster_gui_username
  storage_cluster_gui_password     = var.scale_storage_cluster_gui_password
  cloud_platform                   = local.cloud_platform
  avail_zones                      = jsonencode([var.zone])
  compute_instance_desc_map        = jsonencode([])
  compute_instance_desc_id         = jsonencode([])
  host                             = chomp(data.http.fetch_myip.response_body)
  storage_instances_by_id          = local.strg_vsi_ids_0_disks == null ? jsondecode([]) : jsonencode(local.strg_vsi_ids_0_disks)
  storage_instance_disk_map        = local.strg_vsi_ips_0_disks_dev_map == null ? jsondecode([]) : jsonencode(local.strg_vsi_ips_0_disks_dev_map)
  depends_on                       = [ module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.storage_nodes_wait , module.login_vsi, module.spectrum_scale_storage]
}

// This module is used to invoke compute playbook, to setup scale compute gpfs cluster.
module "invoke_compute_playbook" {
  count                            = (var.spectrum_scale_enabled && var.worker_node_min_count > 0) ? 1 : 0
  source                           = "./resources/scale_common/ansible_compute_playbook"
  region                           = local.region_name
  stack_name                       = format("%s.%s", var.cluster_prefix, "compute")
  tf_data_path                     = local.tf_data_path
  tf_input_json_root_path          = local.tf_input_json_root_path == null ? abspath(path.cwd) : local.tf_input_json_root_path
  tf_input_json_file_name          = local.tf_input_json_file_name == null ? join(", ", fileset(abspath(path.cwd), "*.tfvars*")) : local.tf_input_json_file_name
  bastion_public_ip                = module.login_fip.floating_ip_address
  bastion_os_flavor                = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key          = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  scale_infra_repo_clone_path      = local.scale_infra_repo_clone_path
  clone_complete                   = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  scale_version                    = local.scale_version
  compute_filesystem_mountpoint    = var.scale_compute_cluster_filesystem_mountpoint
  compute_cluster_gui_username     = var.scale_compute_cluster_gui_username
  compute_cluster_gui_password     = var.scale_compute_cluster_gui_password
  cloud_platform                   = local.cloud_platform
  avail_zones                      = jsonencode([var.zone])
  compute_instances_by_id          = jsonencode(local.compute_vsi_ids_0_disks)
  host                             = chomp(data.http.fetch_myip.response_body)
  compute_instances_by_ip          = local.compute_vsi_by_ip == null ? jsonencode([]) : jsonencode(local.compute_vsi_by_ip)
  depends_on                       = [module.login_ssh_key, module.primary_vsi, module.secondary_vsi, module.management_node_vsi, module.worker_vsi, module.compute_nodes_wait]
}

// This module is used to invoke scale remote mount
module "invoke_remote_mount" {
  count                       = var.spectrum_scale_enabled ? 1 : 0
  source                      = "./resources/scale_common/ansible_remote_mount_playbook"
  scale_infra_repo_clone_path = local.scale_infra_repo_clone_path
  cloud_platform              = local.cloud_platform
  tf_data_path                = local.tf_data_path
  bastion_public_ip           = module.login_fip.floating_ip_address
  bastion_os_flavor           = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key     = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  total_compute_instances     = local.total_compute_instances
  total_storage_instances     = var.scale_storage_node_count
  host                        = chomp(data.http.fetch_myip.response_body)
  clone_complete              = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  depends_on                  = [module.invoke_compute_playbook, module.invoke_storage_playbook, module.sg, module.login_sg]
}

// once scale configuration is completed, need to remove temp ssh key added from all nodes.
module "remove_ssh_key" {
  count = var.spectrum_scale_enabled ? 1 : 0
  source = "./resources/scale_common/remove_ssh"
  bastion_ssh_private_key = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  compute_instances_by_ip = local.compute_vsi_by_ip == null ? jsonencode([]) : jsonencode(local.compute_vsi_by_ip)
  key_to_remove = var.spectrum_scale_enabled? module.login_ssh_key.public_key: ""
  login_ip = module.login_fip.floating_ip_address
  storage_vsis_1A_by_ip = jsonencode(local.storage_vsis_1A_by_ip)
  host = chomp(data.http.fetch_myip.response_body)
  depends_on = [module.invoke_remote_mount, null_resource.entitlement_check]
}

data "ibm_iam_auth_token" "token" {}

resource "null_resource" "delete_schematics_ingress_security_rule" { # This code executes to refresh the IAM token, so during the execution we would have the latest token updated of IAM cloud so we can destroy the security group rule through API calls
  provisioner "local-exec" {
    environment = {
      REFRESH_TOKEN       = data.ibm_iam_auth_token.token.iam_refresh_token
      REGION              = local.region_name
      SECURITY_GROUP      = module.login_sg.sec_group_id
      SECURITY_GROUP_RULE = module.schematics_sg_tcp_rule.security_rule_id
    }
    command     = <<EOT
          echo $SECURITY_GROUP
          echo $SECURITY_GROUP_RULE
          TOKEN=$(
            echo $(
              curl -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=refresh_token&refresh_token=$REFRESH_TOKEN" -u bx:bx
              ) | jq  -r .access_token
          )
          curl -X DELETE "https://$REGION.iaas.cloud.ibm.com/v1/security_groups/$SECURITY_GROUP/rules/$SECURITY_GROUP_RULE?version=2021-08-03&generation=2" -H "Authorization: $TOKEN"
        EOT
  }
  depends_on = [
    module.remove_ssh_key, module.schematics_sg_tcp_rule, null_resource.entitlement_check
  ]
}