###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    This module used to run playbook for compute, storage, remountmount and network confiuration.
*/


variable "bastion_public_ip" {}
variable "host" {}
variable "bastion_ssh_private_key" {}
variable "scale_version" {}
variable "cloud_platform" {}
variable "inventory_path" {}
variable "playbook_path" {}
variable "gpfs_rpm_path" {}
variable "bastion_user" {}


resource "null_resource" "call_scale_install_playbook" {
  connection {
    bastion_host = var.bastion_public_ip
    user         = var.bastion_user
    host         = var.host
    private_key  = file(var.bastion_ssh_private_key)
  }

  provisioner "ansible" {
    plays {
      playbook {
        file_path = var.playbook_path
      }
      inventory_file = var.inventory_path
      verbose        = true
      extra_vars = {
        "scale_version" : var.scale_version,
        "ansible_python_interpreter" : "auto",
        "scale_install_directory_pkg_path" : var.gpfs_rpm_path,
        "scale_install_prereqs_packages" : true
      }
    }
    ansible_ssh_settings {
      insecure_no_strict_host_key_checking         = true
      insecure_bastion_no_strict_host_key_checking = false
      connect_timeout_seconds                      = 90
      user_known_hosts_file                        = ""
      bastion_user_known_hosts_file                = ""
    }
  }
  triggers = {
    build = timestamp()
  }
}
