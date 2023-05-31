###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This file contains the complete information on all the validations performed from the code during the generate plan process
# Validations are performed to make sure, the appropriate error messages are displayed to user in-order to provide required input parameter

locals {
  //validate storage gui password
  validate_storage_gui_password_cnd = (var.spectrum_scale_enabled && (replace(lower(var.scale_storage_cluster_gui_password), lower(var.scale_storage_cluster_gui_username), "" ) == lower(var.scale_storage_cluster_gui_password)) && can(regex("^.{8,}$", var.scale_storage_cluster_gui_password) != "") && can(regex("[0-9]{1,}", var.scale_storage_cluster_gui_password) != "") && can(regex("[a-z]{1,}", var.scale_storage_cluster_gui_password) != "") && can(regex("[A-Z]{1,}", var.scale_storage_cluster_gui_password ) != "") && can(regex("[!@#$%^&*()_+=-]{1,}", var.scale_storage_cluster_gui_password ) != "" )&& trimspace(var.scale_storage_cluster_gui_password) != "") || !var.spectrum_scale_enabled
  gui_password_msg                  = "Password should be at least 8 characters, must have one number, one lowercase letter, and one uppercase letter, at least one unique character. Password Should not contain username"
  validate_storage_gui_password_chk = regex(
    "^${local.gui_password_msg}$",
    ( local.validate_storage_gui_password_cnd ? local.gui_password_msg : "") )

  // validate compute gui password
  validate_compute_gui_password_cnd = (var.spectrum_scale_enabled && (replace(lower(var.scale_compute_cluster_gui_password), lower(var.scale_compute_cluster_gui_username), "") == lower(var.scale_compute_cluster_gui_password)) && can(regex("^.{8,}$", var.scale_compute_cluster_gui_password) != "") && can(regex("[0-9]{1,}", var.scale_compute_cluster_gui_password) != "") && can(regex("[a-z]{1,}", var.scale_compute_cluster_gui_password) != "") && can(regex("[A-Z]{1,}", var.scale_compute_cluster_gui_password ) != "") && can(regex("[!@#$%^&*()_+=-]{1,}", var.scale_compute_cluster_gui_password ) != "" )&& trimspace(var.scale_compute_cluster_gui_password) != "") || !var.spectrum_scale_enabled
  validate_compute_gui_password_chk = regex(
    "^${local.gui_password_msg}$",
    ( local.validate_compute_gui_password_cnd ? local.gui_password_msg : ""))

  //validate scale storage gui user name
  validate_scale_storage_gui_username_cnd = (var.spectrum_scale_enabled && length(var.scale_storage_cluster_gui_username) >= 4 && length(var.scale_storage_cluster_gui_username) <= 32 && trimspace(var.scale_storage_cluster_gui_username) != "") || !var.spectrum_scale_enabled
  storage_gui_username_msg                = "Specified input for \"storage_cluster_gui_username\" is not valid."
  validate_storage_gui_username_chk       = regex(
    "^${local.storage_gui_username_msg}",
    (local.validate_scale_storage_gui_username_cnd? local.storage_gui_username_msg : ""))

  // validate compute gui username
  validate_compute_gui_username_cnd = (var.spectrum_scale_enabled && length(var.scale_compute_cluster_gui_username) >= 4 && length(var.scale_compute_cluster_gui_username) <= 32 && trimspace(var.scale_compute_cluster_gui_username) != "") || !var.spectrum_scale_enabled
  compute_gui_username_msg          = "Specified input for \"compute_cluster_gui_username\" is not valid."
  validate_compute_gui_username_chk = regex(
    "^${local.compute_gui_username_msg}",
    (local.validate_compute_gui_username_cnd? local.compute_gui_username_msg : ""))

  validate_scale_count_cnd =  !var.spectrum_scale_enabled || (var.spectrum_scale_enabled && (var.scale_storage_node_count > 1))
  validate_scale_count_msg = "Input \"scale_storage_node_count\" must be >= 3 and <= 18 and has to be divisible by 2."
  validate_scale_count_chk = regex(
      "^${local.validate_scale_count_msg}$",
      ( local.validate_scale_count_cnd
        ? local.validate_scale_count_msg
        : "" ) )

  validate_scale_worker_min_cnd =  !var.spectrum_scale_enabled || (var.spectrum_scale_enabled && (var.management_node_count + var.worker_node_min_count > 2 && var.worker_node_min_count > 0 && var.worker_node_min_count <= 64))
  validate_scale_worker_min_msg = "Input worker_node_min_count must be greater than 0 and less than or equal to 64 and total_quorum_node i.e, sum of management_node_count and worker_node_min_count should be greater than 2, if spectrum_scale_enabled set to true."
  validate_scale_worker_min_chk = regex(
      "^${local.validate_scale_worker_min_msg}$",
      ( local.validate_scale_worker_min_cnd
        ? local.validate_scale_worker_min_msg
        : "" ) )

  validate_scale_worker_max_cnd = !var.spectrum_scale_enabled || (var.spectrum_scale_enabled && (var.worker_node_min_count == var.worker_node_max_count))
  validate_scale_worker_max_msg = "If scale is enabled, Input worker_node_min_count must be equal to worker_node_max_count."
  validate_scale_worker_max_check = regex(
      "^${local.validate_scale_worker_max_msg}$",
      ( local.validate_scale_worker_max_cnd
        ? local.validate_scale_worker_max_msg
        : ""))

  // Since bare metal server creation is supported only in few specific zone, the below validation ensure to return an error message if any other zone value are provided from variable file
  validate_zone                  = var.worker_node_type == "baremetal" || var.spectrum_scale_enabled && var.storage_type == "persistent"? contains(["us-south-1", "us-south-2","us-south-3", "eu-de-1", "eu-de-2","ca-tor-2", "ca-tor-3"], var.zone) : true
  zone_msg                       = "The solution supports bare metal server creation in only given availability zones i.e. us-south-1, us-south-3, us-south-2, eu-de-1, eu-de-2, ca-tor-2 and ca-tor-3. To deploy bare metal server provide any one of the supported availability zones."
  validate_persistent_region_chk = regex("^${local.zone_msg}$", (local.validate_zone ? local.zone_msg : ""))

  // Validating the dedicated host creation only if the worker type is set as vsi. This function block works during the generate plan
  validate_dedicated_host = var.dedicated_host_enabled == true ? var.worker_node_type == "vsi" : true
  dedicated_host_msg                       = "The solution supports dedicated host creation only when the worker_node_type is set as vsi. Provide worker_node_type only as vsi, to enable dedicated host. "
  dedicated_host_enabled_chk = regex("^${local.dedicated_host_msg}$", (local.validate_dedicated_host ? local.dedicated_host_msg : ""))

  // Solution supports maximum of 16 baremetal node creation. This validation ensure to throw an error message if the value is greater than 16
  validate_worker_min_max_count = ( var.spectrum_scale_enabled && var.worker_node_type == "baremetal" ? var.worker_node_min_count == var.worker_node_max_count && var.worker_node_min_count >= 1 && var.worker_node_min_count <=16 && var.worker_node_max_count >=1 && var.worker_node_max_count <= 16 : (var.worker_node_type == "baremetal" ? var.worker_node_min_count == var.worker_node_max_count && var.worker_node_min_count >= 1 && var.worker_node_min_count <=16 && var.worker_node_max_count >=1 && var.worker_node_max_count <= 16 : true))
  count_msg                       = "The solution supports worker_node_min_count to be greater than or equal to 1 and less than or equal to 16 , Input worker_node_min_count must be equal to worker_node_max_count since dynamic host is not supported worker_node_type is set as baremetal."
  validate_worker_count_chk = regex("^${local.count_msg}$", (local.validate_worker_min_max_count ? local.count_msg : ""))

  // Validate baremetal profile
  validate_bare_metal_profile = var.worker_node_type == "baremetal" ? can(regex("^[b|c|m|v]x[0-9]+d?-[a-z]+-[0-9]+x[0-9]+", var.worker_node_instance_type)) : true
  bare_metal_profile_error = "Specified profile must be a valid baremetal profile type. For example \"cx2d-metal-96x192 , bx2d-metal-96x384, vx2d-metal-96x1536\".Refer worker_node_instance_type description for link."
  validate_bare_metal_profile_chk = regex("^${local.bare_metal_profile_error}$", (local.validate_bare_metal_profile ? local.bare_metal_profile_error : ""))

  // Validate Spectrum scale baremetal profile
  validate_spectrum_scale_bare_metal_profile = var.spectrum_scale_enabled == true && var.storage_type == "persistent" ? can(regex("^[b|c|m|v]x[0-9]+d?-[a-z]+-[0-9]+x[0-9]+", var.scale_storage_node_instance_type)) : (var.spectrum_scale_enabled && var.storage_type == "scratch" ? can(regex("^[b|c|m]x[0-9]+d-[0-9]+x[0-9]+", var.scale_storage_node_instance_type)) : true )
  spectrum_scale_bare_metal_profile_error = "Spectrum Scale nodes must be a valid baremetal profile type. For example if storage_type is baremetal then \"cx2d-metal-96x192 , bx2d-metal-96x384, vx2d-metal-96x1536\" and if storage_type is set as scratch \"cx2d-8x16, cx2d-4x16 \". Refer worker_node_instance_type description for link."
  validate_spectrum_scale_bare_metal_profile_chk = regex("^${local.spectrum_scale_bare_metal_profile_error}$", (local.validate_spectrum_scale_bare_metal_profile ? local.spectrum_scale_bare_metal_profile_error : ""))

  // validate Spectrum scale storage node count
  validate_spectrum_scale_persistent_node = var.spectrum_scale_enabled && var.storage_type == "persistent" ? var.scale_storage_node_count >= 3 && var.scale_storage_node_count <=10 : ( var.spectrum_scale_enabled && var.storage_type == "scratch" ? var.scale_storage_node_count >= 3 && var.scale_storage_node_count <= 18 : true)
  spectrum_scale_persistent_count_msg                       = "Specified input \"scale_storage_node_count\" must be in between the range of 3 and 10 while storage type is persistent. Otherwise it should be in range of 3 and 18 while storage type is scratch. Please provide the appropriate range of value."
  validate_spectrum_scale_persistent_chk = regex("^${local.spectrum_scale_persistent_count_msg}$", (local.validate_spectrum_scale_persistent_node ? local.spectrum_scale_persistent_count_msg : ""))

  //validate Spectrum scale dns domain, value for vpc_storage_cluster_dns_domain should not be same as other domain name
  validate_spectrum_scale_dns_domain_name = var.spectrum_scale_enabled == true ? var.vpc_scale_storage_dns_domain != var.vpc_worker_dns_domain : true
  spectrum_scale_dns_name_error = "The solution requires \"vpc_storage_cluster_dns_domain\" and \"vpc_worker_dns_domain\" to be with a different name when spectrum_scale_enabled is set as true."
  validate_spectrum_scale_dns_domain_name_chk = regex("^${local.spectrum_scale_dns_name_error}$", (local.validate_spectrum_scale_dns_domain_name ? local.spectrum_scale_dns_name_error : ""))

  validate_windows_worker_node       = var.windows_worker_node ? var.worker_node_type == "vsi" : true
  windows_worker_node_error_message  = "When windows worker node is set as true, the worker_node_type should be set as vsi. Because windows worker node doesn't support baremetal servers."
  validate_windows_worker_node_check = regex("^${local.windows_worker_node_error_message}$", (local.validate_windows_worker_node? local.windows_worker_node_error_message : ""))

  validate_worker_cnd = var.worker_node_min_count <= var.worker_node_max_count
  validate_worker_msg = "worker_node_max_count has to be greater or equal to worker_node_min_count"
  validate_worker_chk = regex(
      "^${local.validate_worker_msg}$",
      ( local.validate_worker_cnd
        ? local.validate_worker_msg
        : "" ) )

  validate_scale_cnd = var.spectrum_scale_enabled ? var.windows_worker_node ? false : true : true
  validate_scale_msg = " spectrum_scale not supported with windows worker node"
  validate_scale_chk = regex(
      "^${local.validate_scale_msg}$",
      ( local.validate_scale_cnd ? local.validate_scale_msg : "" ) )

  validate_windows_worker_max_cnd = !var.windows_worker_node || (var.windows_worker_node && (var.worker_node_min_count == var.worker_node_max_count))
  validate_windows_worker_max_msg = "If windows worker is enabled, Input worker_node_min_count and worker_node_max_count must be equal."
  validate_windows_worker_max_check = regex(
      "^${local.validate_windows_worker_max_msg}$",
      ( local.validate_windows_worker_max_cnd ? local.validate_windows_worker_max_msg : ""))

  // Copy address prefixes and CIDR of given zone into a new tuple
  prefixes_in_given_zone =  [
      for  prefix in data.ibm_is_vpc_address_prefixes.existing_vpc.*.address_prefixes[0] :
        prefix.cidr if prefix.zone.0.name == var.zone
     ]
  //Validation for the private subnet CIDR input
  validate_private_subnet_cidr = anytrue(
    [for cidrs in local.prefixes_in_given_zone:
      #Eg: var.vpc_cluster_private_subnets_cidr_blocks = 192.76.32.1
      ((((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],0))[0])*pow(256,3)) #192
        + ((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],0))[1])*pow(256,2)) #76
        + ((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],0))[2])*pow(256,1)) # 32
        +((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],0))[3])*pow(256,0))) # 1
        >=
        #Eg: local.prefixes_in_given_zone[0] = 192.76.32.1
        (((split(".",cidrhost(cidrs,0))[0])*pow(256,3)) #192*pow(256,3)
        + ((split(".",cidrhost(cidrs,0))[1])*pow(256,2)) #76*pow(256,2)
        + ((split(".",cidrhost(cidrs,0))[2])*pow(256,1)) #32*pow(256,1)
        +((split(".",cidrhost(cidrs,0))[3])*pow(256,0)))) #1*pow(256,0)
        && ((((split(".",cidrhost(cidrs,-1))[0])*pow(256,3)) #1*pow(256,3)
        + ((split(".",cidrhost(cidrs,-1))[1])*pow(256,2)) #32*pow(256,2)
        + ((split(".",cidrhost(cidrs,-1))[2])*pow(256,1)) #76*pow(256,1)
        +((split(".",cidrhost(cidrs,-1))[3])*pow(256,0))) #192*pow(256,0)
        >=
        (((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],-1))[0])*pow(256,3)) #1*pow(256,3)
        + ((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],-1))[1])*pow(256,2)) #32*pow(256,2)
        + ((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],-1))[2])*pow(256,1)) #76*pow(256,1)
        +((split(".",cidrhost(var.vpc_cluster_private_subnets_cidr_blocks[0],-1))[3])*pow(256,0))))]) #192*pow(256,0)
  validate_private_subnet_cidr_msg = "The solution supports creation of new subnets under an existing VPC, provide appropriate range of subnet CIDR value from the existing VPC’s CIDR block."
  validate_private_subnet_cidr_chk = regex(
      "^${local.validate_private_subnet_cidr_msg}$",
      ( local.validate_private_subnet_cidr ? local.validate_private_subnet_cidr_msg : ""))

  //Validation for the login subnet CIDR input
  validate_login_subnet_cidr = anytrue(
    [for cidrs in local.prefixes_in_given_zone:
      #Eg: var.vpc_cluster_private_subnets_cidr_blocks = 192.76.32.1
      ((((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],0))[0])*pow(256,3)) #192
        + ((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],0))[1])*pow(256,2)) #76
        + ((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],0))[2])*pow(256,1)) # 32
        +((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],0))[3])*pow(256,0))) # 1
        >=
        #Eg: local.prefixes_in_given_zone[0] = 192.76.32.1
        (((split(".",cidrhost(cidrs,0))[0])*pow(256,3)) #192*pow(256,3)
        + ((split(".",cidrhost(cidrs,0))[1])*pow(256,2)) #76*pow(256,2)
        + ((split(".",cidrhost(cidrs,0))[2])*pow(256,1)) #32*pow(256,1)
        +((split(".",cidrhost(cidrs,0))[3])*pow(256,0)))) #1*pow(256,0)
        && ((((split(".",cidrhost(cidrs,-1))[0])*pow(256,3)) #1*pow(256,3)
        + ((split(".",cidrhost(cidrs,-1))[1])*pow(256,2)) #32*pow(256,2)
        + ((split(".",cidrhost(cidrs,-1))[2])*pow(256,1)) #76*pow(256,1)
        +((split(".",cidrhost(cidrs,-1))[3])*pow(256,0))) #192*pow(256,0)
        >=
        (((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],-1))[0])*pow(256,3)) #1*pow(256,3)
        + ((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],-1))[1])*pow(256,2)) #32*pow(256,2)
        + ((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],-1))[2])*pow(256,1)) #76*pow(256,1)
        +((split(".",cidrhost(var.vpc_cluster_login_private_subnets_cidr_blocks[0],-1))[3])*pow(256,0))))]) #192*pow(256,0)
  validate_login_subnet_cidr_msg = "The solution supports creation of new subnets under an existing VPC, provide appropriate range of subnet CIDR value from the existing VPC’s CIDR block."
  validate_login_subnet_cidr_chk = regex(
      "^${local.validate_login_subnet_cidr_msg}$",
      ( local.validate_login_subnet_cidr ? local.validate_login_subnet_cidr_msg : ""))
}