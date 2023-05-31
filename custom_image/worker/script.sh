#!/bin/bash

# Variable declaration
PACKER_FILE_PROVISIONER_PATH='/tmp/packages'
SCALE_PACKAGES_PATH=$PACKER_FILE_PROVISIONER_PATH/scale
SYMPHONY_PACKAGES_PATH=$PACKER_FILE_PROVISIONER_PATH/symphony

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

# Symphony Package prerequisites
SYMPHONY_PREREQS="elfutils iptables ed python38 dejavu-serif-fonts nfs-utils libnsl bc bind-utils nmap-ncat zlib-devel xz-devel libzstd-devel elfutils-devel"
yum install -y $SYMPHONY_PREREQS
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
pip3.8 install ibm-vpc==0.13.0 ibm-cloud-sdk-core==3.16.0 requests==2.28.1 urllib3==1.26.13 charset-normalizer==2.1.1 ibm-cloud-networking-services==0.21.0
ibmcloud plugin install vpc-infrastructure -v 6.1.0

# Export required input paramter value for Symphony installation
export CLUSTERADMIN=egoadmin
export CLUSTERNAME=IBMCloudSym731Cluster
export IBM_SPECTRUM_SYMPHONY_LICENSE_ACCEPT=Y
export BASEPORT=17869
export EGO_TOP=/opt/ibm/spectrumcomputing
export ENTITLEMENT_FILE=$EGO_TOP/kernel/conf/sym_adv_entitlement.dat
export entitlementLine1='ego_base   4.0   ()   ()   ()   ()   5d449d73ca3a88559afdbe8671c28e3554c6c805'
export entitlementLine2='sym_advanced_edition   7.3.2   ()   ()   ()   ()   ce8d7c93b6e7c8b210a39904826bbe51eb4682a7'
export ARG_SYM_VERSION=7.3.2
export ARG_BINARY_TYPE=linux-x86_64
export ARG_EGO_VERSION=4.0
export IBM_BASE_PATH="/opt/IBM"
export HF_PROVIDERS_CONF=$EGO_TOP/hostfactory/conf/providers/hostProviders.json
export HF_PROVIDER_PLUGINS_CONF=$EGO_TOP/hostfactory/conf/providerplugins/hostProviderPlugins.json

#Assign python version to appropriate path
rm -f /usr/bin/python /usr/bin/python3
ln -s /usr/bin/python3.6 /usr/bin/python
ln -s /usr/bin/python3.8 /usr/bin/python3

# Symphony installation
useradd -m $CLUSTERADMIN -d /home/$CLUSTERADMIN -u 1001 -g 0 -s /bin/bash && echo "$CLUSTERADMIN:$(cat /proc/sys/kernel/random/uuid)" | chpasswd
echo "egoadmin??? soft??? nproc???? 65536" >> /etc/security/limits.conf
echo "egoadmin??? hard??? nproc???? 65536" >> /etc/security/limits.conf
echo "egoadmin??? soft??? nofile??? 65536" >> /etc/security/limits.conf
echo "egoadmin??? hard??? nofile??? 65536" >> /etc/security/limits.conf

chmod 700  $SYMPHONY_PACKAGES_PATH/*.bin
/bin/bash $SYMPHONY_PACKAGES_PATH/*.bin --quiet
chown $CLUSTERADMIN:root /opt/ibm
source $EGO_TOP/profile.platform
egoinstallfixes $SYMPHONY_PACKAGES_PATH/*.tar.gz --silent

cp $EGO_TOP/hostfactory/.install/mgconf.txt $EGO_TOP/hostfactory/.install/mgconf.txt.tmp
chown -R $CLUSTERADMIN:root $EGO_TOP/hostfactory
chown -R $CLUSTERADMIN:root $EGO_TOP/wlp
chown -R $CLUSTERADMIN:root $EGO_TOP/integration
chown -R $CLUSTERADMIN:root $EGO_TOP/perf
chown -R $CLUSTERADMIN:root $EGO_TOP/gui
chown -R $CLUSTERADMIN:root $EGO_TOP/is

echo "# Parameters related to dynamic adding/removing host" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_DYNAMIC_HOST_TIMEOUT=5M" >> $EGO_TOP/kernel/conf/ego.conf
echo "# Parameters related to the preferred subnet 10.*" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_PREFERRED_IP_MASK="10.0.0.0/8"" >> $EGO_TOP/kernel/conf/ego.conf
echo "# Setup SSH for cluster start/stop" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_RSH=\"ssh -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no'\"" >> $EGO_TOP/kernel/conf/ego.conf
sed -i 's/EGO_DYNAMIC_HOST_WAIT_TIME=.*/EGO_DYNAMIC_HOST_WAIT_TIME=130/g' $EGO_TOP/kernel/conf/ego.conf
echo "EGO_RESOURCE_UPDATE_INTERVAL=15" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_ENABLE_RG_UPDATE_MEMBERSHIP=Y" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_RG_UPDATE_MEMBERSHIP_INTERVAL=30" >> $EGO_TOP/kernel/conf/ego.conf
echo "EGO_LIM_IGNORE_CHECKSUM=Y" >> $EGO_TOP/kernel/conf/ego.conf
echo "net.ipv4.tcp_max_syn_backlog = 65536 " >> /etc/sysctl.conf
cat $EGO_TOP/kernel/conf/ego.conf

# remove unsupported services from symphony
[ -f $EGO_TOP/$ARG_EGO_VERSION/$ARG_BINARY_TYPE/etc/ussd ] && rm $EGO_TOP/$ARG_EGO_VERSION/$ARG_BINARY_TYPE/etc/ussd
[ -f $EGO_TOP/eservice/esc/conf/services/ussd.xml ] && rm $EGO_TOP/eservice/esc/conf/services/ussd.xml
# disable some EGO services
[ -f $EGO_TOP/eservice/esc/conf/services/wsg.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" $EGO_TOP/eservice/esc/conf/services/wsg.xml
[ -f $EGO_TOP/eservice/esc/conf/services/named.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" $EGO_TOP/eservice/esc/conf/services/named.xml
[ -f $EGO_TOP/eservice/esc/conf/services/rsa.xml ] && sed -i -e "s|AUTOMATIC|MANUAL|g" $EGO_TOP/eservice/esc/conf/services/rsa.xml
[ -f $EGO_TOP/eservice/esc/conf/services/symrest.xml ] && sed -i -e "s|MANUAL|AUTOMATIC|g" $EGO_TOP/eservice/esc/conf/services/symrest.xml
[ -f $EGO_TOP/.install/sym_advanced_edition/mrss.xml ] && rm $EGO_TOP/.install/sym_advanced_edition/mrss.xml
[ -f $EGO_TOP/.install/sym_advanced_edition/MapReduce*.xml ] && rm $EGO_TOP/.install/sym_advanced_edition/MapReduce*.xml
# disable REST job monitoring
[ -f $EGO_TOP/eservice/esc/conf/services/rest_service.xml ] && sed -i "/monitor-rest.sh/d" $EGO_TOP/eservice/esc/conf/services/rest_service.xml

# Reduce image size by removing irrelevant files
find $EGO_TOP -type d -name activation | xargs rm -rf
find $EGO_TOP -type d -name upgrade | xargs rm -rf
find $EGO_TOP -type d -name uninstall | xargs rm -rf
find $EGO_TOP -type f -name rpi\* | xargs rm -rf
find $EGO_TOP/soam/$ARG_SYM_VERSION/$ARG_BINARY_TYPE/lib64 -name \*.so\* ! -type l | xargs -L 1 basename | xargs -L 1 -I '{{}}' find $EGO_TOP/$ARG_EGO_VERSION/$ARG_BINARY_TYPE/lib -name {{}} | xargs -L 1 -I '{{}}' ln -sf {{}} $EGO_TOP/soam/$ARG_SYM_VERSION/$ARG_BINARY_TYPE/lib64

find /var/log -maxdepth 2 -type f -delete
rm -f $EGO_TOP/filelist.txt
rm -f $EGO_TOP/packagedef.txt
rm -f $EGO_TOP/fixlist.txt
echo $entitlementLine1 > $ENTITLEMENT_FILE
echo $entitlementLine2 >> $ENTITLEMENT_FILE
chown $CLUSTERADMIN $ENTITLEMENT_FILE
chmod 755 /opt/ibm
chmod -R 755 /usr/local/lib/
find $EGO_TOP \! -user $CLUSTERADMIN -print
echo check to make sure ibmcloud is enabled $EGO_TOP/hostfactory/conf/providers/hostProviders.json
mkdir -p $IBM_BASE_PATH
mv $PACKER_FILE_PROVISIONER_PATH/* $IBM_BASE_PATH
systemctl stop syslog

## Cleanup
rm -rf $PACKER_FILE_PROVISIONER_PATH
rm -rf /var/log/messages
rm -rf /root/.bash_history