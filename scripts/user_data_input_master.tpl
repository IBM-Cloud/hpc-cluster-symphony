#!/usr/bin/bash

###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
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
sym_entitlement1="${sym_entitlement_ego}"
sym_entitlement2="${sym_entitlement_soam}"
vpcAPIKeyValue="${vpc_apikey_value}"
hostPrefix="${host_prefix}"
hf_cidr_block="${hf_cidr_block}"
storage_ips="${storage_ips}"
cluster_name="${cluster_id}"
numExpectedManagementHosts="${mgmt_count}"
egoHostRole="${ego_host_role}"
cluster_cidr="${cluster_cidr}"
