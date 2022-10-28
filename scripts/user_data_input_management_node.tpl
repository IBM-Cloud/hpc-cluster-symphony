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
sym_entitlement1="ego_base   3.9   ()   ()   ()   ()   0dd01a5e74fa2cf2851965cf64b1166f242e7843"
sym_entitlement2="sym_advanced_edition   7.3.1   ()   ()   ()   ()   21402f8aebf693f45c9e5a1c595435134be80845"
vpcAPIKeyValue="${vpc_apikey_value}"
hostPrefix="${host_prefix}"
hf_cidr_block="${hf_cidr_block}"
storage_ips="${storage_ips}"
cluster_name="${cluster_id}"
numExpectedManagementHosts="${mgmt_count}"
egoHostRole="${ego_host_role}"
cluster_cidr="${cluster_cidr}"
spectrum_scale="${spectrum_scale}"
temp_public_key="${temp_public_key}"
windows_worker_node="${windows_worker_node}"
EgoUserName="${EgoUserName}"
EgoPassword="${EgoPassword}"