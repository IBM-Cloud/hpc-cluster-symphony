###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Write provisioned infrastructure details to JSON.
*/

variable "inventory_path" {}
variable "cloud_platform" {}
variable "resource_prefix" {}
variable "vpc_region" {}
variable "vpc_availability_zones" {}
variable "scale_version" {}
variable "filesystem_block_size" {}
variable "compute_cluster_filesystem_mountpoint" {}
variable "bastion_user" {}
variable "bastion_instance_id" {}
variable "bastion_instance_public_ip" {}
variable "compute_cluster_instance_ids" {}
variable "compute_cluster_instance_private_ips" {}
variable "compute_cluster_instance_private_dns_ip_map" {}
variable "storage_cluster_filesystem_mountpoint" {}
variable "storage_cluster_instance_ids" {}
variable "storage_cluster_instance_private_ips" {}
variable "storage_cluster_with_data_volume_mapping" {}
variable "storage_cluster_instance_private_dns_ip_map" {}
variable "storage_cluster_desc_instance_ids" {}
variable "storage_cluster_desc_instance_private_ips" {}
variable "storage_cluster_desc_data_volume_mapping" {}
variable "storage_cluster_desc_instance_private_dns_ip_map" {}

resource "local_sensitive_file" "itself" {
  content  = <<EOT
{
    "cloud_platform": ${var.cloud_platform},
    "resource_prefix": ${var.resource_prefix},
    "vpc_region": ${var.vpc_region},
    "vpc_availability_zones": ${var.vpc_availability_zones},
    "scale_version": ${var.scale_version},
    "compute_cluster_filesystem_mountpoint": ${var.compute_cluster_filesystem_mountpoint},
    "filesystem_block_size": ${var.filesystem_block_size},
    "bastion_user": ${var.bastion_user},
    "bastion_instance_id": ${var.bastion_instance_id},
    "bastion_instance_public_ip": ${var.bastion_instance_public_ip},
    "compute_cluster_instance_ids": ${var.compute_cluster_instance_ids},
    "compute_cluster_instance_private_ips": ${var.compute_cluster_instance_private_ips},
    "compute_cluster_instance_private_dns_ip_map": ${var.compute_cluster_instance_private_dns_ip_map},
    "storage_cluster_filesystem_mountpoint": ${var.storage_cluster_filesystem_mountpoint},
    "storage_cluster_instance_ids": ${var.storage_cluster_instance_ids},
    "storage_cluster_instance_private_ips": ${var.storage_cluster_instance_private_ips},
    "storage_cluster_with_data_volume_mapping": ${var.storage_cluster_with_data_volume_mapping},
    "storage_cluster_instance_private_dns_ip_map": ${var.storage_cluster_instance_private_dns_ip_map},
    "storage_cluster_desc_instance_ids": ${var.storage_cluster_desc_instance_ids},
    "storage_cluster_desc_instance_private_ips": ${var.storage_cluster_desc_instance_private_ips},
    "storage_cluster_desc_data_volume_mapping": ${var.storage_cluster_desc_data_volume_mapping},
    "storage_cluster_desc_instance_private_dns_ip_map": ${var.storage_cluster_desc_instance_private_dns_ip_map}
}
EOT
  filename = var.inventory_path
}

output "write_inventory_complete" {
  value      = true
  depends_on = [local_sensitive_file.itself]
}
