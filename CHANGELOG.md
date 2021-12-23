# **CHANGELOG**

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