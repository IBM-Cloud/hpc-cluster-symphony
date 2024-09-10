###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

output "ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 18443:localhost:8443 -J root@${module.login_fip.floating_ip_address} root@${module.primary_vsi[0].primary_network_interface}"
}

output "vpc_name" {
  value = "${data.ibm_is_vpc.vpc.name} --  - ${data.ibm_is_vpc.vpc.id}"
}

output "vpn_config_info" {
  value = var.vpn_enabled ? "IP : ${module.vpn[0].vpn_gateway_public_ip_address}, CIDR: ${module.login_subnet.ipv4_cidr_block}, UDP ports : 500, 4500 " : null
}

output "spectrum_scale_storage_ssh_command" {
  value = var.spectrum_scale_enabled ? var.storage_type == "scratch" ? "ssh -J root@${module.login_fip.floating_ip_address} root@${module.spectrum_scale_storage[0].primary_network_interface}" : "ssh -J root@${module.login_fip.floating_ip_address} root@${element(tolist(module.storage_bare_metal_server_cluster[0].primary_network_interface), 0)}" : null
}

output "region_name" {
  value = data.ibm_is_region.region.name
}

output "image_map_entry_found" {
  value = "${local.image_mapping_entry_found} --  - ${var.image_name}"
}
