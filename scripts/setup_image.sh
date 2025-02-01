#!/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

set -x
export CLUSTERADMIN=egoadmin
export CLUSTERNAME=IBMCloudSym731Cluster
export IBM_SPECTRUM_SYMPHONY_LICENSE_ACCEPT=Y
DERBY_DB_HOST=$(hostname -f)
export DERBY_DB_HOST
export BASEPORT=17869

export EGO_TOP=/opt/ibm/spectrumcomputing
export ARG_SYM_VERSION=7.3.1
export ARG_BINARY_TYPE=linux-x86_64
export ARG_EGO_VERSION=3.9

yum install ed -y -q
yum install bc -y -q
yum install python3 -y -q
yum install dejavu-serif-fonts -y -q
yum install net-tools -y -q
yum install bind-utils -y -q
yum install nfs-utils -y -q

curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
pip3.6 install --upgrade "ibm-vpc>=0.0.3"
pip3.6 install --upgrade "ibm-cloud-networking-services>=0.4.1"
ibmcloud plugin install vpc-infrastructure

useradd -m ${CLUSTERADMIN} -d /home/${CLUSTERADMIN} -u 1001 -g 0 -s /bin/bash && echo "${CLUSTERADMIN}:$(cat /proc/sys/kernel/random/uuid)" | chpasswd
sed -i -e "s|4096|unlimited|g" /etc/security/limits.d/20-nproc.conf
{
  echo "egoadmin    soft    nproc    65536"
  echo "egoadmin    hard    nproc    65536"
  echo "egoadmin    soft    nofile   65536"
  echo "egoadmin    hard    nofile   65536"
} >> /etc/security/limits.conf


chmod 700 ./sym-7.3.1.0_x86_64.bin
./sym-7.3.1.0_x86_64.bin --quiet
rm -f ./sym-7.3.1.0_x86_64.bin
tar -zxf hfcore-1.1.0.0_x86_64_build600420.tar.gz -C ${EGO_TOP}
tar -zxf hfmgmt-1.1.0.0_noarch_build600420.tar.gz -C ${EGO_TOP}
cp ${EGO_TOP}/hostfactory/.install/mgconf.txt ${EGO_TOP}/hostfactory/.install/mgconf.txt.tmp
chown -R ${CLUSTERADMIN}:root ${EGO_TOP}/hostfactory
chown -R ${CLUSTERADMIN}:root ${EGO_TOP}/wlp
# shellcheck disable=SC1083
chown {CLUSTERADMIN}:root ${EGO_TOP}/*.txt
rm -f hf*.tar.gz
{
  echo "# Parameters related to dynamic adding/removing host"
  echo "EGO_DYNAMIC_HOST_TIMEOUT=5M"
  echo "# Parameters related to the preferred subnet 10.*"
  echo "EGO_PREFERRED_IP_MASK=\"10.0.0.0/8\""
  echo "# Setup SSH for cluster start/stop"
  echo "EGO_RSH=\"ssh -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no'\""
  echo "EGO_RESOURCE_UPDATE_INTERVAL=1"
  echo "EGO_ENABLE_RG_UPDATE_MEMBERSHIP=Y"
  echo "EGO_RG_UPDATE_MEMBERSHIP_INTERVAL=10"
  echo "EGO_LIM_IGNORE_CHECKSUM=Y"
} >> "${EGO_TOP}/kernel/conf/ego.conf"

# Update the EGO_DYNAMIC_HOST_WAIT_TIME using sed
sed -i 's/^\(EGO_DYNAMIC_HOST_WAIT_TIME=\).*/\130/' "${EGO_TOP}/kernel/conf/ego.conf"


# remove unsupported services
[ -f ${EGO_TOP}/${ARG_EGO_VERSION}/${ARG_BINARY_TYPE}/etc/ussd ] && rm ${EGO_TOP}/${ARG_EGO_VERSION}/${ARG_BINARY_TYPE}/etc/ussd
[ -f ${EGO_TOP}/eservice/esc/conf/services/ussd.xml ] && rm ${EGO_TOP}/eservice/esc/conf/services/ussd.xml

# disable some EGO services
[ -f ${EGO_TOP}/eservice/esc/conf/services/wsg.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" ${EGO_TOP}/eservice/esc/conf/services/wsg.xml
[ -f ${EGO_TOP}/eservice/esc/conf/services/named.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" ${EGO_TOP}/eservice/esc/conf/services/named.xml
[ -f ${EGO_TOP}/eservice/esc/conf/services/rsa.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" ${EGO_TOP}/eservice/esc/conf/services/rsa.xml
[ -f ${EGO_TOP}/eservice/esc/conf/services/symrest.xml ] && sed -i -e "s|MANUAL|AUTOMATIC|g" ${EGO_TOP}/eservice/esc/conf/services/symrest.xml
[ -f ${EGO_TOP}/.install/sym_advanced_edition/mrss.xml ] && rm ${EGO_TOP}/.install/sym_advanced_edition/mrss.xml
# shellcheck disable=SC2144
[ -f ${EGO_TOP}/.install/sym_advanced_edition/MapReduce*.xml ] && rm ${EGO_TOP}/.install/sym_advanced_edition/MapReduce*.xml
# disable REST job monitoring
[ -f ${EGO_TOP}/eservice/esc/conf/services/rest_service.xml ] && sed -i "/monitor-rest.sh/d" ${EGO_TOP}/eservice/esc/conf/services/rest_service.xml

#cleanup
# Reduce image size by removing irrelevant files
find "${EGO_TOP}" -type d -name activation -print0 | xargs -0 rm -rf
find "${EGO_TOP}" -type d -name upgrade -print0 | xargs -0 rm -rf
find "${EGO_TOP}" -type d -name uninstall -print0 | xargs -0 rm -rf
find "${EGO_TOP}" -type f -name rpi\* -print0 | xargs -0 rm -rf
# shellcheck disable=SC2038
find ${EGO_TOP}/soam/${ARG_SYM_VERSION}/${ARG_BINARY_TYPE}/lib64 -name \*.so\* ! -type l | xargs -L 1 basename | xargs -L 1 -I '{}' find ${EGO_TOP}/${ARG_EGO_VERSION}/${ARG_BINARY_TYPE}/lib -name {} | xargs -L 1 -I '{}' ln -sf {} ${EGO_TOP}/soam/${ARG_SYM_VERSION}/${ARG_BINARY_TYPE}/lib64

#/etc/cloud/cloud.cfg
#manage_etc_hosts: False
sed -i "s/manage_etc_hosts: True/manage_etc_hosts: False/" /etc/cloud/cloud.cfg
rm /etc/hosts
touch /etc/hosts
#patches?
find ${EGO_TOP} \! -user ${CLUSTERADMIN} -print
