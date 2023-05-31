###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
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
    dns_domain_name      = var.vpc_worker_dns_domain
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
    storage_type         = var.storage_type
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
    dns_domain_name      = var.vpc_worker_dns_domain
    ego_host_role        = "secondary"
    cluster_cidr         = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
    temp_public_key     = var.spectrum_scale_enabled ? local.vsi_login_temp_public_key : ""
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
    storage_type         = var.storage_type
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
    dns_domain_name      = var.vpc_worker_dns_domain
    ego_host_role        = "management_node"
    cluster_cidr         = module.subnet.ipv4_cidr_block
    spectrum_scale       = var.spectrum_scale_enabled
    temp_public_key     = var.spectrum_scale_enabled ? local.vsi_login_temp_public_key : ""
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
    storage_type         = var.storage_type
  }
}

data "template_file" "worker_user_data" {
  template = local.worker_template_file
  vars = {
    storage_ips         = join(" ", local.storage_ips)
    cluster_id          = local.cluster_name
    mgmt_count          = var.management_node_count
    dns_domain_name     = var.vpc_worker_dns_domain
    hyperthreading      = var.hyperthreading_enabled
    cluster_cidr        = module.subnet.ipv4_cidr_block
    spectrum_scale      = var.spectrum_scale_enabled
    temp_public_key     = var.spectrum_scale_enabled ? local.vsi_login_temp_public_key : ""
    windows_worker_node = var.windows_worker_node
    EgoUserName          = local.EgoUserName
    EgoPassword          = local.EgoPassword
    worker_node_type     = var.worker_node_type
    storage_type         = var.storage_type
  }
}

// template file for scale storage nodes
data "template_file" "scale_storage_user_data" {
  template = local.spectrum_storage_template_file
  vars = {
    ego_host_role       = "scale_storage"
    storage_ips         = join(" ", local.storage_ips)
    cluster_id          = local.cluster_name
    dns_domain_name     = var.vpc_scale_storage_dns_domain
    mgmt_count          = var.management_node_count
    hyperthreading      = var.hyperthreading_enabled
    cluster_cidr        = module.subnet.ipv4_cidr_block
    spectrum_scale      = var.spectrum_scale_enabled
    temp_public_key     = local.vsi_login_temp_public_key
    worker_node_type     = var.worker_node_type
    storage_type         = var.storage_type

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
  source       = "./resources/ibmcloud/network/vpc"
  count        = var.vpc_name == "" ? 1 : 0
  name         = "${var.cluster_prefix}-vpc"
  resource_group = data.ibm_resource_group.rg.id
  vpc_address_prefix_management = "manual"
  tags         = local.tags
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
  count          = local.existing_public_gateway_zone != "" ? 0 : 1
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
  depends_on        = [module.vpc_address_prefix]
}

# This module is used to create subnet, which is used to create both worker and storage node. The subnet CIDR range is passed manually based on the user input from variable file
module "subnet" {
  source            = "./resources/ibmcloud/network/subnet"
  subnet_name       = "${var.cluster_prefix}-subnet"
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  ipv4_cidr_block   = var.vpc_cluster_private_subnets_cidr_blocks[0]
  public_gateway    = local.existing_public_gateway_zone != "" ? local.existing_public_gateway_zone : module.public_gw[0].public_gateway_id
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
  depends_on        = [module.vpc_address_prefix]
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

# Module open port 53 on outbound rule for login SG, for the resolution of rhel capsule server to get license when existing vpc has custom resolver associated.
module "login_outbound_dns_rule" {
  count   = local.dns_reserved_ip != "" ? 1 : 0
  source  = "./resources/ibmcloud/security/login_sg_outbound_dns_rule"
  group   = module.login_sg.sec_group_id
  remote  = data.ibm_dns_custom_resolvers.dns_custom_resolver[0].custom_resolvers[0].locations[0].dns_server_ip
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

/*
 * DNS Resolver
 Created the DNS service and associates the DNS Zone and its respective permitted networks to the zone for communication
 As Symphony supports scale, separate scale domain will be created only if the spectrum_scale_enables is set as true
 Custom resolver is not enables with HA and only single subnet is associated and it can support only 1 VPC at maximum
*/

module "dns_service"{
  source            = "./resources/ibmcloud/network/dns_service"
  count             = local.dns_reserved_ip == "" ? 1 : 0
  resource_group_id = data.ibm_resource_group.rg.id
  resource_instance_name = var.cluster_prefix
  tags              = local.tags
}

module "worker_zone" {
  source         = "./resources/ibmcloud/network/dns_zone"
  dns_domain     = var.vpc_worker_dns_domain
  dns_service_id = local.dns_instance_id
  description    = "Private DNS Zone for Symphony VPC DNS communication."
  dns_label      = var.cluster_prefix
  depends_on     = [module.dns_service]
}

module "worker_dns_permitted"{
  source      = "./resources/ibmcloud/network/dns_permitted_network"
  instance_id = local.dns_instance_id
  zone_id     = module.worker_zone.dns_zone_id
  vpc_crn     = data.ibm_is_vpc.vpc.crn
  depends_on  = [module.vpc, module.worker_zone]
}

module "storage_zone" {
  count        = var.spectrum_scale_enabled ? 1 : 0
  source       = "./resources/ibmcloud/network/dns_zone"
  dns_domain   = var.vpc_scale_storage_dns_domain
  dns_service_id = local.dns_instance_id
  description  = "Private DNS Zone for Spectrum Scale storage VPC DNS communication."
  dns_label    = var.cluster_prefix
  depends_on   = [module.dns_service]
}

module "storage_dns_permitted"{
  count       = var.spectrum_scale_enabled ? 1 : 0
  source      = "./resources/ibmcloud/network/dns_permitted_network"
  instance_id = local.dns_instance_id
  zone_id     = module.storage_zone[0].dns_zone_id
  vpc_crn     = data.ibm_is_vpc.vpc.crn
  depends_on   = [module.vpc, module.storage_zone,module.worker_dns_permitted]
}

module "dns_resolver" {
  count          = local.dns_reserved_ip == "" ? 1 : 0
  source         = "./resources/ibmcloud/network/dns_resolver"
  customer_resolver_name = var.cluster_prefix
  instance_guid  = local.dns_instance_id
  description    = "Private DNS custom resolver for VPC DNS communication."
  subnet_crn     = module.subnet.subnet_crn
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

  totat_spectrum_storage_node_count = var.spectrum_scale_enabled ? var.scale_storage_node_count : 0
  total_ipv4_address_count = pow(2, ceil(log(
    local.totat_spectrum_storage_node_count +
    var.worker_node_max_count +
    var.management_node_count +
    5 +
    1 + /* ibm-broadcast-address */
    4 + /* ibm-default-gateway, ibm-dns-address, ibm-network-address, ibm-reserved-address */
    1,  /* DNS Instance */
    2))
  )
  first_ip_idx = 5

  custom_ipv4_subnet_node_count = join(",", var.vpc_cluster_private_subnets_cidr_blocks) != "" ? parseint(regex("/(\\d+)$", join(",", var.vpc_cluster_private_subnets_cidr_blocks))[0], 10) : 0
  total_custom_ipv4_node_count = pow(2, 32 - local.custom_ipv4_subnet_node_count)

  storage_ips = [
    for idx in range(1) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + local.first_ip_idx)
  ]
  spectrum_storage_node_count = var.spectrum_scale_enabled ? var.scale_storage_node_count : 0
  spectrum_storage_ips = [
    for idx in range(local.spectrum_storage_node_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + local.first_ip_idx + length(local.storage_ips))
  ]
  management_node_ips = [
    for idx in range(var.management_node_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + local.first_ip_idx + length(local.storage_ips) + length(local.spectrum_storage_ips))
  ]

  worker_ips = [
    for idx in range(var.worker_node_min_count) :
    cidrhost(module.subnet.ipv4_cidr_block, idx + local.first_ip_idx + length(local.storage_ips) + length(local.spectrum_storage_ips) +length(local.management_node_ips))
  ]

  vsi_login_private_key     = module.login_ssh_key.private_key
  vsi_login_temp_public_key = module.login_ssh_key.public_key
  peer_cidr_list = var.vpn_enabled ? split(",", var.vpn_peer_cidrs): []
   # Get the list of public gateways from the existing vpc on provided var.zone input parameter. If no public gateway is found and in that zone our solution creates a new public gateway.
  existing_pgs = [for subnetsdetails in data.ibm_is_subnet.subnet_id: subnetsdetails.public_gateway if subnetsdetails.zone == var.zone && subnetsdetails.public_gateway != ""]
  existing_public_gateway_zone = var.vpc_name == "" ? "" : (length(local.existing_pgs) == 0 ? "" : element(local.existing_pgs ,0))

  // Fetch if there is already a DNS custom resolver is associated to the existing VPC feature, if there is no DNS custom resolver associated new DNS service and CR will be created through our solution.
  dns_reserved_ip = join("", flatten(toset([for details in data.ibm_is_subnet_reserved_ips.dns_reserved_ips: flatten(details[*].reserved_ips[*].target_crn)])))
  dns_service_id  = local.dns_reserved_ip == "" ? "" : split(":", local.dns_reserved_ip)[7]
  dns_instance_id = local.dns_reserved_ip == "" ? module.dns_service[0].resource_guid : local.dns_service_id
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
  instance_id       = local.dns_instance_id
  zone_id           = module.worker_zone.dns_zone_id
  dns_domain        = var.vpc_worker_dns_domain
  depends_on        = [
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_ingress_all_local_rule,
    module.outbound_sg_rule
  ]
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
  instance_id       = local.dns_instance_id
  zone_id           = module.worker_zone.dns_zone_id
  dns_domain        = var.vpc_worker_dns_domain
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
  count                 = local.image_mapping_entry_found ? 1 : 0
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
  instance_id     = local.dns_instance_id
  zone_id         = module.worker_zone.dns_zone_id
  dns_domain      = var.vpc_worker_dns_domain
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
  tags             = local.tags
  instance_id      = local.dns_instance_id
  zone_id          = module.worker_zone.dns_zone_id
  dns_domain       = var.vpc_worker_dns_domain
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
  count             = var.spectrum_scale_enabled == true && var.storage_type != "persistent" ? var.scale_storage_node_count : 0
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
  instance_id       = local.dns_instance_id
  zone_id           = module.storage_zone[0].dns_zone_id
  dns_domain        = var.vpc_scale_storage_dns_domain
  depends_on        = [module.login_vsi,module.nfs_storage,module.primary_vsi,module.management_node_vsi,module.inbound_sg_rule, module.inbound_sg_ingress_all_local_rule, module.outbound_sg_rule]
}

// The module is used to create the compute vsi instance based on the type of node_type required for deployment
module "worker_vsi" {
  source           = "./resources/ibmcloud/compute/worker_vsi"
  count            = ( var.windows_worker_node ? 0 : (var.worker_node_type != "baremetal" ? var.worker_node_min_count : 0 ))
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
  instance_id      = local.dns_instance_id
  zone_id          = module.worker_zone.dns_zone_id
  dns_domain       = var.vpc_worker_dns_domain
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
   name            = "${var.cluster_prefix}-bare-metal-server-${count.index}"
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
   instance_id     = local.dns_instance_id
   zone_id         = module.worker_zone.dns_zone_id
   dns_domain      = var.vpc_worker_dns_domain
   depends_on      = [module.primary_vsi, module.secondary_vsi, module.management_node_vsi, module.inbound_sg_ingress_all_local_rule, module.inbound_sg_rule, module.outbound_sg_rule, module.spectrum_scale_storage]
}

// The module is used to create the scale storage baremetal nodes based on storage_type is set as persistent
module "storage_bare_metal_server_cluster" {
  source           = "./resources/ibmcloud/compute/scale_storage_bare_metal_server"
  count            =  var.spectrum_scale_enabled && var.storage_type == "persistent" ? 1 : 0
  total_vsis      =  var.scale_storage_node_count
  name             = "${var.cluster_prefix}-storage-bare-metal-server"
  profile          = data.ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile[0].name
  image            = data.ibm_is_image.baremetal_image.id
  zone             = [data.ibm_is_zone.zone.name]
  keys             = local.ssh_key_id_list
  vpc              = data.ibm_is_vpc.vpc.id
  resource_group   = data.ibm_resource_group.rg.id
  subnet           = [module.subnet.subnet_id]
  security_group   = [module.sg.sg_id]
  user_data        = "${data.template_file.scale_storage_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony.sh")}"
  tags             = local.tags
  instance_id      = local.dns_instance_id
  zone_id          = module.storage_zone[0].dns_zone_id
  dns_domain       = var.vpc_scale_storage_dns_domain
  depends_on       = [module.primary_vsi, module.secondary_vsi, module.management_node_vsi, module.inbound_sg_ingress_all_local_rule, module.inbound_sg_rule, module.outbound_sg_rule, module.spectrum_scale_storage]
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
  local_cidrs     = [module.login_subnet.ipv4_cidr_block]
  peer_cidrs      = local.peer_cidr_list
}

module "ingress_vpn" {
  source    = "./resources/ibmcloud/security/vpn_ingress_sg_rule"
  count     = length(local.peer_cidr_list)
  group     = module.login_sg.sec_group_id
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
    cluster_id    = local.cluster_name
    mgmt_count    = var.management_node_count
    dns_domain_name = var.vpc_worker_dns_domain
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

module "windows_worker" {
  source         = "./resources/ibmcloud/compute/windows_worker_vsi"
  count          = var.windows_worker_node ? var.worker_node_min_count : 0
  vsi_name       = "${var.cluster_prefix}${local.windows_worker_node_prefix}${count.index}"
  image          = local.windows_image_mapping_entry_found ? local.new_windows_image_id : data.ibm_is_image.windows_worker_image[0].id
  profile        = data.ibm_is_instance_profile.worker[0].name
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = data.ibm_is_zone.zone.name
  keys           = local.ssh_key_id_list
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
  dedicated_host = var.dedicated_host_enabled ? module.dedicated_host[var.dedicated_host_placement == "spread" ? count.index % local.dh_count: floor(count.index / local.dh_worker_count)].dedicated_host_id: null
  user_data      = "${data.template_file.windows_worker_user_data[count.index].rendered}"
  subnet_id      = module.subnet.subnet_id
  security_group = [module.sg.sg_id]
  primary_ipv4_address = local.worker_ips[count.index]
  instance_id    = local.dns_instance_id
  zone_id        = module.worker_zone.dns_zone_id
  dns_domain     = var.vpc_worker_dns_domain
  depends_on     = [module.login_ssh_key, module.primary_vsi, module.secondary_vsi, module.management_node_vsi,module.invoke_windows_security_group_rules]
}

/*
Spectrum Scale Integration related steps
*/

// This null_resource is required to upgrade the jinja package version on schematics, since the ansible playbook that we run requires the latest version of jinja
resource "null_resource" "upgrade_jinja" {
  count = var.spectrum_scale_enabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "pip install jinja2 --upgrade"
  }
  depends_on     =  [null_resource.entitlement_check]
}

locals {
  // Check whether an entry is found in the scale mapping file for the given scale storage node image
  // scale image used for scale storage node.
  scale_image_mapping_entry_found = contains(keys(local.scale_image_region_map), var.scale_storage_image_name)
  scale_image_id = contains(keys(local.scale_image_region_map), var.scale_storage_image_name) ? lookup(lookup(local.scale_image_region_map, var.scale_storage_image_name), local.region_name) : "Image not found with the given name"
 
  // path for ansible playbook data configurations
  tf_data_path                =  "/tmp/.schematics/IBM/tf_data_path"
  gpfs_rpm_path               = "/opt/IBM/gpfs_cloud_rpms"
  tf_input_json_root_path     = null
  tf_input_json_file_name     = null
  inventory_format            = "ini"
  create_scale_cluster        = false
  using_rest_api_remote_mount = true
  bastion_instance_public_ip  = null
  bastion_ssh_private_key     = null

  // scale version installed on custom images.
  scale_version             = "5.1.7.0"

  // cloud platform as IBMCloud, required for ansible playbook.
  cloud_platform            = "IBMCloud"

  // path where ansible playbook will be cloned from github public repo.
  scale_infra_repo_clone_path = "/tmp/.schematics/IBM/ibm-spectrumscale-cloud-deploy"
  scale_infra_repo_inventory_path = "/tmp/.schematics/IBM/ibm-spectrumscale-cloud-deploy/ibm-spectrum-scale-install-infra/"

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

  // RHEL OS version used for the creation of Baremetal servers i.e.(Worker_node_type="baremetal" and storage_type="persistent")
  bare_metal_server_osimage_name = "ibm-redhat-8-6-minimal-amd64-4"

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
  depends_on    = [module.spectrum_scale_storage, module.storage_bare_metal_server_cluster]
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
  branch     = "master"
  tag        = null
  clone_path = local.scale_infra_repo_clone_path
}

/*
Spectrum Scale Deployment Process.
Firstly the inventory file for both Comput/storage would be created in json format
Using the inventory file created from the above, configuration file will be created for the further Ansible deployment
Once the configuration files are created, using the data Ansible playbook shall be invoked to run the rest Ansible playbook to set the scale cluster
*/

// This module creates the json file with the required configuration and will be used for the creation of inventory file for compute cluster
module "write_compute_cluster_inventory" {
  count                                            = var.spectrum_scale_enabled == true ? 1 : 0
  source                                           = "./resources/scale_common/write_inventory"
  inventory_path                                   = format("%s/compute_cluster_inventory.json", local.scale_infra_repo_clone_path)
  cloud_platform                                   = jsonencode("IBMCloud")
  resource_prefix                                  = jsonencode(format("%s.%s", var.cluster_prefix, var.vpc_worker_dns_domain))
  vpc_region                                       = jsonencode(local.region_name)
  vpc_availability_zones                           = jsonencode([var.zone])
  scale_version                                    = jsonencode(local.scale_version)
  filesystem_block_size                            = jsonencode("None")
  compute_cluster_filesystem_mountpoint            = jsonencode(var.scale_compute_cluster_filesystem_mountpoint)
  bastion_instance_id                              = jsonencode(module.login_vsi.login_id)
  bastion_instance_public_ip                       = jsonencode(module.login_fip.floating_ip_address)
  bastion_user                                     = jsonencode("root")
  compute_cluster_instance_ids                     = jsonencode(local.compute_vsi_ids_0_disks)
  compute_cluster_instance_private_ips             = local.compute_vsi_by_ip == null ? jsonencode([]) : jsonencode(local.compute_vsi_by_ip)
  compute_cluster_instance_private_dns_ip_map      = jsonencode([])
  storage_cluster_filesystem_mountpoint            = jsonencode("None")
  storage_cluster_instance_ids                     = jsonencode([])
  storage_cluster_instance_private_ips             = jsonencode([])
  storage_cluster_with_data_volume_mapping         = jsonencode({})
  storage_cluster_instance_private_dns_ip_map      = jsonencode({})
  storage_cluster_desc_instance_ids                = jsonencode([])
  storage_cluster_desc_instance_private_ips        = jsonencode([])
  storage_cluster_desc_data_volume_mapping         = jsonencode({})
  storage_cluster_desc_instance_private_dns_ip_map = jsonencode({})
  depends_on                                       = [ module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.compute_nodes_wait]
}

// This module creates the json file with the required configuration and will be used for the creation of inventory file for scale storage cluster
module "write_storage_cluster_inventory" {
  count                                            = var.spectrum_scale_enabled ? 1 : 0
  source                                           = "./resources/scale_common/write_inventory"
  inventory_path                                   = format("%s/storage_cluster_inventory.json", local.scale_infra_repo_clone_path)
  cloud_platform                                   = jsonencode("IBMCloud")
  resource_prefix                                  = jsonencode(format("%s.%s", var.cluster_prefix, var.vpc_scale_storage_dns_domain))
  vpc_region                                       = jsonencode(local.region_name)
  vpc_availability_zones                           = jsonencode([var.zone])
  scale_version                                    = jsonencode(local.scale_version)
  filesystem_block_size                            = jsonencode(var.scale_filesystem_block_size)
  compute_cluster_filesystem_mountpoint            = jsonencode("None")
  bastion_instance_id                              = jsonencode(module.login_vsi.login_id)
  bastion_instance_public_ip                       = jsonencode(module.login_fip.floating_ip_address)
  bastion_user                                     = jsonencode("root")
  compute_cluster_instance_ids                     = jsonencode([])
  compute_cluster_instance_private_ips             = jsonencode([])
  compute_cluster_instance_private_dns_ip_map      = jsonencode({})
  storage_cluster_filesystem_mountpoint            = jsonencode(var.scale_storage_cluster_filesystem_mountpoint)
  storage_cluster_instance_ids                     = var.storage_type == "persistent" ? jsonencode(one(module.storage_bare_metal_server_cluster[*].bare_metal_server_id)) : jsonencode(module.spectrum_scale_storage[*].spectrum_scale_storage_id)
  storage_cluster_instance_private_ips             = var.storage_type == "persistent" ? jsonencode(one(module.storage_bare_metal_server_cluster[*].primary_network_interface)) : jsonencode(module.spectrum_scale_storage[*].primary_network_interface)
  storage_cluster_with_data_volume_mapping         = var.storage_type == "persistent" ? jsonencode(one(module.storage_bare_metal_server_cluster[*].instance_ips_with_vol_mapping)) : jsonencode(local.strg_vsi_ips_0_disks_dev_map)
  storage_cluster_instance_private_dns_ip_map      = jsonencode([])
  storage_cluster_desc_instance_ids                = jsonencode([])
  storage_cluster_desc_instance_private_ips        = jsonencode([])
  storage_cluster_desc_data_volume_mapping         = jsonencode({})
  storage_cluster_desc_instance_private_dns_ip_map = jsonencode({})
  depends_on                                       = [module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.storage_nodes_wait]
}

// This module creates the inventory file for the compute ansible playbook to be created
module "compute_cluster_configuration" {
  count                        =  var.spectrum_scale_enabled ? 1 : 0
  source                       = "./resources/scale_common/compute_configuration"
  turn_on                      = local.total_compute_instances > 0 ? true : false
  clone_complete               = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  write_inventory_complete     = module.write_compute_cluster_inventory[0].write_inventory_complete
  inventory_format             = local.inventory_format
  create_scale_cluster         = local.create_scale_cluster
  clone_path                   = local.scale_infra_repo_clone_path
  inventory_path               = format("%s/compute_cluster_inventory.json", local.scale_infra_repo_clone_path)
  using_packer_image           = false
  using_direct_connection      = false
  using_rest_initialization    = local.using_rest_api_remote_mount
  compute_cluster_gui_username = var.scale_compute_cluster_gui_username
  compute_cluster_gui_password = var.scale_compute_cluster_gui_password
  memory_size                  = var.worker_node_type == "baremetal" ? data.ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile[0].memory[0].value * 1000 : data.ibm_is_instance_profile.worker[0].memory[0].value * 1000
  max_pagepool_gb              = 4
  bastion_user                 = jsonencode("root")
  bastion_instance_public_ip   = module.login_fip.floating_ip_address
  bastion_ssh_private_key      = module.login_ssh_key.private_key_path
  meta_private_key             = module.login_ssh_key.private_key
  scale_version                = local.scale_version
  spectrumscale_rpms_path      = "/opt/IBM/gpfs_cloud_rpms"
  max_mbps                     = var.worker_node_type == "baremetal" ? data.ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile[0].bandwidth[0].value * 0.25 : data.ibm_is_instance_profile.worker[0].bandwidth[0].value * 0.25
  depends_on                   = [ module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.compute_nodes_wait , module.login_vsi, module.write_compute_cluster_inventory]
}

// This module creates the inventory file for the storage ansible playbook to be created
module "storage_cluster_configuration" {
  count                        = var.spectrum_scale_enabled ? 1 : 0
  source                       = "./resources/scale_common/storage_configuration"
  turn_on                      = var.scale_storage_node_count > 0  ? true : false
  clone_complete               = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  write_inventory_complete     = module.write_storage_cluster_inventory[0].write_inventory_complete
  inventory_format             = local.inventory_format
  create_scale_cluster         = local.create_scale_cluster
  clone_path                   = local.scale_infra_repo_clone_path
  inventory_path               = format("%s/storage_cluster_inventory.json", local.scale_infra_repo_clone_path)
  using_packer_image           = false
  using_direct_connection      = false
  using_rest_initialization    = local.using_rest_api_remote_mount
  storage_cluster_gui_username = var.scale_storage_cluster_gui_username
  storage_cluster_gui_password = var.scale_storage_cluster_gui_password
  memory_size                  = var.storage_type == "persistent" ? data.ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile[0].memory[0].value * 1000 : data.ibm_is_instance_profile.spectrum_scale_storage[0].memory[0].value * 1000
  max_pagepool_gb              = var.storage_type == "persistent" ? 32 : 16
  vcpu_count                   = var.storage_type == "persistent" ? data.ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile[0].cpu_socket_count[0].value * data.ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile[0].cpu_core_count[0].value  : data.ibm_is_instance_profile.spectrum_scale_storage[0].vcpu_count[0].value
  bastion_user                 = jsonencode("root")
  bastion_instance_public_ip   = module.login_fip.floating_ip_address
  bastion_ssh_private_key      = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  meta_private_key             = module.login_ssh_key.private_key
  scale_version                = local.scale_version
  spectrumscale_rpms_path      = "/opt/IBM/gpfs_cloud_rpms"
  disk_type                    = var.storage_type == "persistent" ? "locally-attached" : "network-attached"
  max_data_replicas            = 3
  max_metadata_replicas        = 3
  default_metadata_replicas    = var.storage_type == "persistent" ? 3 : 2
  default_data_replicas        = var.storage_type == "persistent" ? 2 : 1
  max_mbps                     = var.storage_type == "persistent" ? data.ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile[0].bandwidth[0].value * 0.25 : data.ibm_is_instance_profile.spectrum_scale_storage[0].bandwidth[0].value * 0.25
  depends_on                   = [ module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.storage_nodes_wait]
}

// This module creates the inventory file for the remote ansible playbook to be created
module "remote_mount_cluster_configuration" {
  count                           = var.spectrum_scale_enabled ? 1 : 0
  source                          = "./resources/scale_common/remote_mount_configuration"
  turn_on                         = (local.total_compute_instances > 0 && var.scale_storage_node_count > 0 && var.spectrum_scale_enabled == true) ? true : false
  create_scale_cluster            = local.create_scale_cluster
  clone_path                      = local.scale_infra_repo_clone_path
  compute_inventory_path          = format("%s/compute_cluster_inventory.json", local.scale_infra_repo_clone_path)
  compute_gui_inventory_path      = format("%s/compute_cluster_gui_details.json", local.scale_infra_repo_clone_path)
  storage_inventory_path          = format("%s/storage_cluster_inventory.json", local.scale_infra_repo_clone_path)
  storage_gui_inventory_path      = format("%s/storage_cluster_gui_details.json", local.scale_infra_repo_clone_path)
  compute_cluster_gui_username    = var.scale_compute_cluster_gui_username
  compute_cluster_gui_password    = var.scale_compute_cluster_gui_password
  storage_cluster_gui_username    = var.scale_storage_cluster_gui_username
  storage_cluster_gui_password    = var.scale_storage_cluster_gui_password
  using_direct_connection         = false
  using_rest_initialization       = local.using_rest_api_remote_mount
  bastion_user                    = jsonencode("root")
  bastion_instance_public_ip      = module.login_fip.floating_ip_address
  bastion_ssh_private_key         = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  clone_complete                  = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  compute_cluster_create_complete = true
  storage_cluster_create_complete = true
  depends_on                      = [ module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.compute_cluster_configuration, module.storage_cluster_configuration]
}

// This module is used to configure the end-end deployment for storage cluster through Ansible
module "invoke_storage_playbook" {
  count                            = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source                           = "./resources/scale_common/ansible_playbook"
  bastion_public_ip                = module.login_fip.floating_ip_address
  bastion_ssh_private_key          = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  host                             = chomp(data.http.fetch_myip.response_body)
  scale_version                    = local.scale_version
  cloud_platform                   = local.cloud_platform
  inventory_path                   = format("%s/storage_inventory.ini", local.scale_infra_repo_inventory_path)
  playbook_path                    = format("%s/storage_cloud_playbook.yaml", local.scale_infra_repo_inventory_path)
  gpfs_rpm_path                    = local.gpfs_rpm_path
  bastion_user                     = "root"
  depends_on                       = [module.login_ssh_key, module.storage_nodes_wait, module.storage_cluster_configuration, null_resource.upgrade_jinja]
}


// This module is used to invoke compute playbook, to setup scale compute gpfs cluster.
module "invoke_compute_playbook" {
  count                            = (var.spectrum_scale_enabled && var.worker_node_min_count > 0) ? 1 : 0
  source                           = "./resources/scale_common/ansible_playbook"
  bastion_public_ip                = module.login_fip.floating_ip_address
  bastion_ssh_private_key          = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  host                             = chomp(data.http.fetch_myip.response_body)
  scale_version                    = local.scale_version
  cloud_platform                   = local.cloud_platform
  inventory_path                   = format("%s/compute_inventory.ini", local.scale_infra_repo_inventory_path)
  playbook_path                    = format("%s/compute_cloud_playbook.yaml", local.scale_infra_repo_inventory_path)
  gpfs_rpm_path                    = local.gpfs_rpm_path
  bastion_user                     = "root"
  depends_on                       = [module.login_ssh_key, module.compute_nodes_wait, module.compute_cluster_configuration, null_resource.upgrade_jinja]
}

// This module is used to invoke scale remote mount
module "invoke_remote_mount" {
  count                       = var.spectrum_scale_enabled ? 1 : 0
  source                      = "./resources/scale_common/ansible_playbook"
  bastion_public_ip           = module.login_fip.floating_ip_address
  bastion_ssh_private_key     = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  host                        = chomp(data.http.fetch_myip.response_body)
  scale_version               = local.scale_version
  cloud_platform              = local.cloud_platform
  inventory_path              = format("%s/remote_mount_inventory.ini", local.scale_infra_repo_inventory_path)
  playbook_path               = format("%s/remote_mount_cloud_playbook.yaml", local.scale_infra_repo_inventory_path)
  gpfs_rpm_path               = local.gpfs_rpm_path
  bastion_user                = "root"
  depends_on                  = [module.invoke_compute_playbook, module.invoke_storage_playbook, null_resource.upgrade_jinja]
}

// This module is used to invoke scale cloud network config for compute cluster
module "invoke_compute_network_playbook" {
  count                       = var.spectrum_scale_enabled ? 1 : 0
  source                      = "./resources/scale_common/ansible_playbook"
  bastion_public_ip           = module.login_fip.floating_ip_address
  bastion_ssh_private_key     = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  host                        = chomp(data.http.fetch_myip.response_body)
  scale_version               = local.scale_version
  cloud_platform              = local.cloud_platform
  inventory_path              = format("%s/compute_inventory.ini", local.scale_infra_repo_inventory_path)
  playbook_path               = format("%s/samples/legacy/playbook_cloud_network_config.yaml", local.scale_infra_repo_inventory_path)
  gpfs_rpm_path               = local.gpfs_rpm_path
  bastion_user                = "root"
  depends_on                  = [module.invoke_remote_mount, null_resource.upgrade_jinja, module.prepare_spectrum_scale_ansible_repo]
}
// This module is used to invoke scale cloud network config for storage cluster
module "invoke_storage_network_playbook" {
  count                       = var.spectrum_scale_enabled ? 1 : 0
  source                      = "./resources/scale_common/ansible_playbook"
  bastion_public_ip           = module.login_fip.floating_ip_address
  bastion_ssh_private_key     = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  host                        = chomp(data.http.fetch_myip.response_body)
  scale_version               = local.scale_version
  cloud_platform              = local.cloud_platform
  inventory_path              = format("%s/storage_inventory.ini", local.scale_infra_repo_inventory_path)
  playbook_path               = format("%s/samples/legacy/playbook_cloud_network_config.yaml", local.scale_infra_repo_inventory_path)
  gpfs_rpm_path               = local.gpfs_rpm_path
  bastion_user                = "root"
  depends_on                  = [module.invoke_compute_network_playbook, null_resource.upgrade_jinja,]
}

// once scale configuration is completed, need to remove temp ssh key added from all nodes.
module "remove_ssh_key" {
  source                      = "./resources/scale_common/remove_ssh"
  bastion_ssh_private_key     = module.login_ssh_key.private_key_path
  compute_instances_by_ip     = var.spectrum_scale_enabled ? jsonencode(local.compute_vsi_by_ip) : jsonencode(module.primary_vsi[*].primary_network_interface)
  key_to_remove               = module.login_ssh_key.public_key
  login_ip                    = module.login_fip.floating_ip_address
  storage_vsis_1A_by_ip       = var.spectrum_scale_enabled == true ? jsonencode(local.storage_vsis_1A_by_ip) : jsonencode([])
  host                        = chomp(data.http.fetch_myip.response_body)
  depends_on                  = [module.invoke_compute_playbook, module.invoke_storage_playbook, module.invoke_remote_mount, module.invoke_compute_network_playbook, module.invoke_storage_network_playbook, null_resource.entitlement_check]
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
  depends_on = [module.remove_ssh_key, module.schematics_sg_tcp_rule, null_resource.entitlement_check]
}