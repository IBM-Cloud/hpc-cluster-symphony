#!/usr/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

logfile=/tmp/user_data.log
echo START `date '+%Y-%m-%d %H:%M:%S'`

#
# Export user data, which is defined with the "UserData" attribute
# in the template
#
%EXPORT_USER_DATA%

#input parameters
client_mount_path="${client_mount_path}"
cluster_name="${cluster_id}"
dns_domain_name="${dns_domain_name}"
numExpectedManagementHosts="${mgmt_count}"
hyperthreading="${hyperthreading}"
cluster_cidr="${cluster_cidr}"
egoHostRole="${ego_host_role}"
spectrum_scale="${spectrum_scale}"
temp_public_key="${temp_public_key}"
worker_node_type="${worker_node_type}"
storage_type="${storage_type}"
mount_path="${mount_path}"
