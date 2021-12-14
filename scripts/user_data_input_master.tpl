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
<<<<<<< HEAD
sym_entitlement1="${sym_entitlement_ego}"
sym_entitlement2="${sym_entitlement_soam}"
=======
sym_entitlement1="ego_base   3.9   ()   ()   ()   ()   0dd01a5e74fa2cf2851965cf64b1166f242e7843"
sym_entitlement2="sym_advanced_edition   7.3.1   ()   ()   ()   ()   21402f8aebf693f45c9e5a1c595435134be80845"
>>>>>>> 6b88b1398a58f3b9cbc414062f484dd36c3abdc7
vpcAPIKeyValue="${vpc_apikey_value}"
hostPrefix="${host_prefix}"
hf_cidr_block="${hf_cidr_block}"
storage_ips="${storage_ips}"
cluster_name="${cluster_id}"
numExpectedManagementHosts="${mgmt_count}"
egoHostRole="${ego_host_role}"
cluster_cidr="${cluster_cidr}"
