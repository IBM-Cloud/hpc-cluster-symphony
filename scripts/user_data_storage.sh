###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

LSF_CONF=/opt/ibm/lsf/conf
SHARED_TOP=/shared

env

#Update Master host name based on internal IP address
privateIP=$(ip addr show eth0 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
hostName=ibm-gen2host-${privateIP//./-}
hostnamectl set-hostname ${hostName}

# NOTE: On ibm gen2, the default DNS server do not have reverse hostname/IP resolution.
# 1) put the master server hostname and ip into lsf hosts.
# 2) put all possible VMs' hostname and ip into lsf hosts.
python -c "import ipaddress; print('\n'.join([str(ip) + ' ibm-gen2host-' + str(ip).replace('.', '-') for ip in ipaddress.IPv4Network(bytearray('${hf_cidr_block}'))]))" >> /etc/hosts

yum install -y nfs-utils
lsfadmin=1000
found=0
while [ $found -eq 0 ]; do
    for vdx in `lsblk -d -n --output NAME`; do
        desc=$(file -s /dev/$vdx | grep ': data$' | cut -d : -f1)
        if [ "$desc" != "" ]; then
            mkfs -t xfs $desc
            uuid=`blkid -s UUID -o value $desc`
            echo "UUID=$uuid $SHARED_TOP xfs defaults,noatime 0 0" >> /etc/fstab
            mkdir -p $SHARED_TOP
            mount $SHARED_TOP
            chmod 775 $SHARED_TOP
            mkdir -p $SHARED_TOP/ssh
            touch $SHARED_TOP/ssh/authorized_keys
            chmod 700 $SHARED_TOP/ssh
            chmod 600 $SHARED_TOP/ssh/authorized_keys
            chown -R $egoadmin:$egoadmin $SHARED_TOP
            found=1
            break
        fi
    done
    sleep 1s
done

echo "$SHARED_TOP      ${hf_cidr_block}(rw,no_root_squash)" > /etc/exports.d/export-nfs.exports
exportfs -ar

#Adjust the number of threads for the NFS daemon
#NOTE: This would only work for RH7/CentOS7.
#      On RH8, need to adjust /etc/nfs.conf instead
ncpus=$( nproc )
#default is 8 threads
nthreads=8

if [ "$ncpus" -gt "$nthreads" ]; then
  echo "Adjust the thread number for NFS from $nthreads to $ncpus"
  sed -i "s/^# *RPCNFSDCOUNT.*/RPCNFSDCOUNT=$ncpus/g" /etc/sysconfig/nfs
fi

systemctl start nfs-server
systemctl enable nfs-server

echo END `date '+%Y-%m-%d %H:%M:%S'`
