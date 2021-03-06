# **CHANGELOG**

## **1.2.2**
### **CHANGES**
- RHEL 8.4 Custom image updated with polkit vulnerability fix.
- Fixed bug to use users custom image for scale storage nodes. 
- Fixed bug to create dynamic host with different resource group.
- Fixed fip issue with ssh allowed ips provided.
- Scale version has been updated from 5.1.2 to 5.1.3.1
- Terraform version has been updated from v0.14 to v1.1
- Wait duration time for storage and compute set up has been increased to 180s

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