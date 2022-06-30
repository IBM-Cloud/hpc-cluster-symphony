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
storage_ips="${storage_ips}"
cluster_name="${cluster_id}"
numExpectedManagementHosts="${mgmt_count}"
hyperthreading="${hyperthreading}"
cluster_cidr="${cluster_cidr}"
hf_cidr_block="${cluster_cidr}"
spectrum_scale="${spectrum_scale}"
<<<<<<< HEAD
temp_public_key="${temp_public_key}"
=======
temp_public_key="${temp_public_key}"
>>>>>>> 09669b716c4db8e8001a2784111871c5844e0300
