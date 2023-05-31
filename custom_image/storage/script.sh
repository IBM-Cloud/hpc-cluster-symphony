#!/bin/bash

# Variable declaration
PACKER_FILE_PROVISIONER_PATH='/tmp/packages'
SCALE_PACKAGES_PATH=$PACKER_FILE_PROVISIONER_PATH/scale

# Scale Pacakge prerequisites
uname -r
SCALE_PREREQS="kernel-devel-$(uname -r) kernel-headers-$(uname -r) make gcc-c++ binutils elfutils-libelf-devel bind-utils iptables"
yum install 'dnf-command(versionlock)' -y
yum install -y $SCALE_PREREQS
yum versionlock add kernel kernel-devel kernel-headers kernel-modules kernel-core
yum versionlock list

# Scale installation
rpm --import $SCALE_PACKAGES_PATH/SpectrumScale_public_key.pgp
yum install -y $SCALE_PACKAGES_PATH/*.rpm
yum update --security -y
export LINUX_DISTRIBUTION=REDHAT_AS_LINUX
/usr/lpp/mmfs/bin/mmbuildgpl
echo 'export PATH=$PATH:/usr/lpp/mmfs/bin' >> /root/.bashrc

# Cleanup
rm -rf $PACKER_FILE_PROVISIONER_PATH
rm -rf /var/log/messages
rm -rf /root/.bash_history
history -c
