# **CHANGELOG**
## **1.7.0**
### ENHANCEMENTS
- Support for Symphony Linux 7.3.2 Build601706, Build602082, Build602143, Build602148, Build602149, Build602158, Build602161, Build602162, Build602163, Build602185, Build602225 fix patches.
- Support for Symphony Windows 7.3.2 Build602163, Build602210 fix patches.
- Spectrum Scale version has been updated from 5.2.0.1 to 5.2.1.1.
- Support for vpc fileshare for rhel and Cos fileshare for windows.
## **1.6.2**
### ENHANCEMENTS
- Support for Symphony Linux 7.3.2 Build602125, Build602100, Build602094, Build602071, Build602061, Build602068, Build602039 fix patches.
- Support for Symphony Windows 7.3.2 Build602052 fix patch.
- Spectrum Scale version has been updated from 5.1.9.3 to 5.2.0.1.
### **BUG FIXES**
- Fixed bug related to the cluster name set incorrectly.

## **1.6.1**
### ENHANCEMENTS
- Support for Symphony Linux 7.3.2 Build601756, Build601774, Build601796, Build601822, Build601823, Build601827, Build601835, Build601838, Build601841, Build601929, Build601937, Build601948, Build601954, Build601974, Build602064, Build602058 fix patches.
- Support for Symphony Windows 7.3.2 Build601860 fix patch.

## **1.6.0**
### ENHANCEMENTS
- Support for Symphony Linux 7.3.2 Build601711 fix patch.
- Symphony Windows has been updated from version 7.3.1 to 7.3.2 and also have Build601711 fix patch.
- Spectrum Scale version has been updated from 5.1.7.0 to 5.1.9.0.
- Symphony Linux OS upgraded from RHEL 8.6 to RHEL 8.8.

## **1.5.0**
### ENHANCEMENTS
- Support for persistent storage type for IBM Spectrum Scale deployment on bare metal servers.
- Spectrum Symphony version has been updated from 7.3.1 to 7.3.2.
- Spectrum Scale version has been updated from 5.1.5.1 to 5.1.7.0.
- Support public gateway creation based on existing vpc functionality.
- Support for DNS functionality.
- Updated Symphony and Scale custom images to use RHEL 8.6 instead of RHEL 8.4.
- Support custom image creation.

## **1.4.1**
### **BUG FIXES**
- Fixed bug related to the creation of new subnets with custom cidr under the existing vpc range.

## **1.4.0**
### ENHANCEMENTS
- Support for Baremetal worker node.
- Spectrum Scale version has been updated from 5.1.3.1 to 5.1.5.1.
- Support custom cidr block for vpc and subnet creation.
- Support Entitlement check for Symphony license validation.

## **1.3.0**
### ENHANCEMENTS
- Support for Windows worker node

## **1.2.5**
### **BUG FIXES**
- Fixed bug related to instance storage datasource lookup when spectrum scale is disabled.

### **CHANGES**
- Updated login node and nfs storage node to use RHEL 8.6 stock image instead of RHEL 8.2 stock image.

## **1.2.4**
### **BUG FIXES**
- Fixed bug related to Ansible version 2.10 upgrade.

## **1.2.3**
### **BUG FIXES**
- Fixed bug related to Http data source body deprecation.

## **1.2.2**
### **CHANGES**
- RHEL 8.4 Custom image updated with polkit vulnerability fix.
- Fixed bug to use users custom image for scale storage nodes.
- Fixed bug to create dynamic host with different resource group.
- Fixed fip issue with ssh allowed ips provided.
- Scale version has been updated from 5.1.2 to 5.1.3.1.
- Terraform version has been updated from v0.14 to v1.1.
- Wait duration time for storage and compute set up has been increased to 180s.

## **1.2.1**
### **CHANGES**
- Changes to post provisioning scripts to mitigate Polkit Local Privilege Escalation Vulnerability (CVE-2021-4034).

## **1.2.0**
### ENHANCEMENTS
- Support for Spectrum Scale storage nodes
- Optimization of NFS for RHEL 8

### **CHANGES**
- Removed RHEL 7.7 and Centos 7.7 custom images and replaced them with RHEL 8.2 custom image.

## **1.1.2**
### **CHANGES**
- New custom image having upgraded log4j version(2.17) to mitigate Log4Shell vulnerability (CVE-2021-44228).

## **1.1.1**
### **CHANGES**
- Remove JNDILookup and JMSAppender from classpath to mitigate Log4Shell vulnerability (CVE-2021-44228).

## **1.1.0**
### ENHANCEMENTS
- Support dedicated hosts for static worker nodes
- Enhance ssh_command output

### **CHANGES**
- Update stock images used for login and storage nodes to RHEL 8.2
- Enable hyperthreading by default
- Clean up symphony entitlements
- Clean up location(region) input properties
- Add parallelism to schematics destroy
- Remove JNDILookup and JMSAppender from classpath to mitigate Log4Shell vulnerability (CVE-2021-44228)

### **BUG FIXES**
- Avoid terraform warning regarding interpolation

## **1.0.0**
- Initial Release
