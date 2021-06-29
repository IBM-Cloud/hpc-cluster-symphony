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
# RESOURCE_RECORDS_APIKEY_VALUE="${vpc_apikey_value}"
imageID="${image_id}"
subnetID="${subnet_id}"
vpcID="${vpc_id}"
securityGroupID="${security_group_id}"
sshkey_ID="${sshkey_id}"
regionName="${region_name}"
zoneName="${zone_name}"
hostPrefix="${hostPrefix}"
# the CIDR block for dynamic hosts
hf_cidr_block="${hf_cidr_block}"
# the instance profile for dynamic hosts
hf_profile="${hf_profile}"
# number of cores for the instance profile
hf_ncores=${hf_ncores}
# memory size in MB for the instance profile
hf_memInMB=${hf_memInMB}
# the maximum allowed dynamic hosts created by Host Factory
hf_maxNum=${hf_maxNum}
# master_ips="${master_ips}"
# worker_ips="${worker_ips}"
storage_ips="${storage_ips}"
cluster_name="${clusterID}"
numExpectedManagementHosts="${TotalSymphonyMgmtCount}"