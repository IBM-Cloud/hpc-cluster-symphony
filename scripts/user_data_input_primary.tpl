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
vpcAPIKeyValue="${vpc_apikey_value}"
imageID="${image_id}"
subnetID="${subnet_id}"
vpcID="${vpc_id}"
securityGroupID="${security_group_id}"
sshkey_ID="${sshkey_id}"
regionName="${region_name}"
zoneName="${zone_name}"
hostPrefix="${host_prefix}"
hf_cidr_block="${hf_cidr_block}"
hf_profile="${hf_profile}"
hf_ncores=${hf_ncores}
hf_memInMB=${hf_mem_in_mb}
hf_maxNum=${hf_max_num}
storage_ips="${storage_ips}"
cluster_name="${cluster_id}"
numExpectedManagementHosts="${mgmt_count}"
egoHostRole="${ego_host_role}"
hyperthreading="${hyperthreading}"
cluster_cidr="${cluster_cidr}"
