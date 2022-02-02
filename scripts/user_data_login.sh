#!/bin/bash

###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

if [ ${spectrum_scale_enabled} == true ]; then
  echo "${vsi_login_temp_public_key}" >> /root/.ssh/authorized_keys
fi
chmod 0755 /usr/bin/pkexec
