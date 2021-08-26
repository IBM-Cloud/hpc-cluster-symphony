# hpc-cluster-symphony
Repository for the HPC Cluster Symphony implementation files.

# Deployment with Schematics on IBM Cloud

Initial configuration:

```
$ cp sample/configs/hpc_workspace_config.json config.json
$ ibmcloud iam api-key-create trl-tyos-api-key --file ~/.ibm-api-key.json -d "my api key"
$ cat ~/.ibm-api-key.json | jq -r ."apikey"
# copy your apikey
$ vim config.json
# paste your apikey and set entitlements for Symphony
```

You also need to generate github token if you use private Github repository.

Deployment:

```
$ ibmcloud schematics workspace new -f config.json --github-token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$ ibmcloud schematics workspace list
Name               ID                                            Description   Status     Frozen
hpcc-symphony-test       us-east.workspace.hpcc-symphony-test.7cbc3f6b                     INACTIVE   False

OK
$ ibmcloud schematics apply --id us-east.workspace.hpcc-symphony-test.7cbc3f6b
Do you really want to perform this action? [y/N]> y

Activity ID b0a909030f071f51d6ceb48b62ee1671

OK
$ ibmcloud schematics logs --id us-east.workspace.hpcc-symphony-test.7cbc3f6b
...
 2021/04/05 09:44:54 Terraform apply | Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
 2021/04/05 09:44:54 Terraform apply |
 2021/04/05 09:44:54 Terraform apply | Outputs:
 2021/04/05 09:44:54 Terraform apply |
 2021/04/05 09:44:54 Terraform apply | sshcommand = ssh -J root@52.116.124.67 root@10.241.0.6
 2021/04/05 09:44:54 Command finished successfully.
 2021/04/05 09:45:00 Done with the workspace action

OK
$ ssh -J root@52.116.124.67 root@10.241.0.6

$ ibmcloud schematics destroy --id us-east.workspace.hpcc-symphony-test.7cbc3f6b
```

# symphony-poc-test

1. Go to <https://cloud.ibm.com/schematics/workspaces> and create a workspace using Schematics
2. After creating the Schematics workspace, at the bottom of the page enter this github repo URL and provide the SSH token to access Github repo, and also select Terraform version as 0.13 and click Save.
3. Go to Schematic Workspace Settings, under variable section, click on "burger icons" to update the following parameters:
    - ssh_key_name with your ibm cloud SSH key name such as "sunil-ssh-key" created in a specific region in IBM Cloud
    - api_key with the api key value and mark it as sensitive to hide the API key in the IBM Cloud Console.
    - Update the hostPrefix value to the specific hostPrefix for your Symphony cluster
    - Update the management_node_count, worker_node_min_count and worker_node_max_count as per your requirement
4. Click on "Generate Plan" and ensure there are no errors and fix the errors if there are any
5. After "Generate Plan" gives no errors, click on "Apply Plan" to create resources.
6. Check the "Activity" section on the left hand side to view the resource creation progress.
7. Click on "View log" if the "Apply Plan" activity is successful and copy the output SSH command to your laptop terminal to SSH to primary node via a jump host public ip to SSH one of the nodes.
8. Also use this jump host public ip and change the IP address of the node you want to access via the jump host to access specific hosts.

# Storage Node and NFS Setup
The storage node is configured as an NFS server and the data volume is mounted to the /data directory which is exported to share with Symphony management nodes.

### Steps to validate Cluster setups
###### 1. To validate the NFS storage is setup and exported correctly
* Login to the storage node using SSH (ssh -J root@52.116.122.64 root@10.240.128.36)
* The below command shows that the data volume, /dev/vdd, is mounted to /data on the storage node.
```
# df -k | grep data
/dev/vdd       104806400 1828916 102977484   2% /data`
```
* The command below shows that /data is exported as a NFS shared directory.

```
# exportfs -v
/data         	10.242.66.0/23(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

* At the NFS client end, the Symphony management nodes in this case, we mount the /data directory in NFS server to the local directory, /data.
```
# df -k | grep data
10.242.66.4:/data 104806400  1828864 102977536   2% /data
```
The command above shows that the local directory, /data, is mounted to the remote /data directory on the NFS server, 10.242.66.4.

###### 2. Steps to validate the cluster status
* Login to the primary as shown in the ssh_command output
```
# ssh -J root@52.116.122.64 root@10.241.0.20
```
* Logon as Admin
```
# egosh user logon -u Admin -x Admin
```
* Check if the resource list contains all the hosts with `ok` status
```
# egosh ego info
# egosh resource list -ll
```

###### 3. Steps to validate host factory
```
$ symping -r 10000 -m 100 > stdout.log 2> stderr.log < /dev/null &
$ watch -n 1 egosh resource list -ll
```

###### 4. Steps to validate failover

* Login to the primary as shown in the ssh_command output
```
$ ssh -J root@52.116.122.64 root@10.241.0.20
```
* Logon as Admin
```
# egosh user logon -u Admin -x Admin
```
* Check the primary host
```
# egosh resource list -m
```
* Stop EGO at primary
```
# systemctl stop ego
```
* Login to the secondary and wait for a while
```
# ssh -J root@52.116.122.64 root@10.241.0.21
```
* Check primary host again and see if the primary is changed
```
# egosh resource list -m
```
* Try symping
```
# symping
```
* Restart EGO at primary
```
# systemctl start ego
```
* Check primary host again and see if the primary is changed
```
# egosh resource list -m
```

# Terraform Documentation

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_ibm"></a> [ibm](#provider\_ibm) | 1.30.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [ibm_is_floating_ip.login_fip](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_floating_ip) | resource |
| [ibm_is_instance.login](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_instance.management](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_instance.primary](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_instance.secondary](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_instance.storage](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_instance.worker](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_instance) | resource |
| [ibm_is_public_gateway.mygateway](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_public_gateway) | resource |
| [ibm_is_security_group.login_sg](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group) | resource |
| [ibm_is_security_group.sg](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group) | resource |
| [ibm_is_security_group_rule.egress_all](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.ingress_all_local](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.ingress_tcp](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_egress_tcp](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_egress_tcp_rhsm](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_egress_udp_rhsm](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_ingress_tcp](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_ingress_tcp_rhsm](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_security_group_rule.login_ingress_udp_rhsm](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_security_group_rule) | resource |
| [ibm_is_subnet.login_subnet](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_subnet) | resource |
| [ibm_is_subnet.subnet](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_subnet) | resource |
| [ibm_is_volume.nfs](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_volume) | resource |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/resources/is_vpc) | resource |
| [ibm_is_image.image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_image) | data source |
| [ibm_is_image.stock_image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_image) | data source |
| [ibm_is_instance_profile.login](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.master](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.storage](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.worker](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_region.region](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_region) | data source |
| [ibm_is_ssh_key.ssh_key](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_ssh_key) | data source |
| [ibm_is_volume_profile.nfs](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_volume_profile) | data source |
| [ibm_is_zone.zone](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/is_zone) | data source |
| [ibm_resource_group.rg](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.30.0/docs/data-sources/resource_group) | data source |
| [template_file.management_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.primary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.secondary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.storage_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.worker_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TF_PARALLELISM"></a> [TF\_PARALLELISM](#input\_TF\_PARALLELISM) | Parallelism/ concurrent operations limit. Valid values are between 1 and 256, both inclusive. [Learn more](https://www.terraform.io/docs/internals/graph.html#walking-the-graph). | `string` | `"250"` | no |
| <a name="input_TF_VERSION"></a> [TF\_VERSION](#input\_TF\_VERSION) | The version of the Terraform engine that's used in the Schematics workspace. | `string` | `"0.14"` | no |
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | This is the API key for IBM Cloud account in which the Spectrum Symphony cluster needs to be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-userapikey). | `string` | n/a | yes |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the cluster used by Symphony for configuration of resources. Post deployment the value can be verified using command `egosh ego info`. | `string` | `"HPCCluster"` | no |
| <a name="input_cluster_prefix"></a> [cluster\_prefix](#input\_cluster\_prefix) | Prefix that is used to name the Spectrum Symphony cluster and IBM Cloud resources that are provisioned to build the Spectrum Symphony cluster instance. You cannot create more than one instance of the Symphony cluster with the same name. Make sure that the name is unique. Enter a prefix name, such as my-hpcc. | `string` | `"hpcc-symphony"` | no |
| <a name="input_hyperthreading_enabled"></a> [hyperthreading\_enabled](#input\_hyperthreading\_enabled) | True to enable hyper-threading in the cluster nodes (default). Otherwise, hyper-threading will be disabled. | `bool` | `true` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Name of the custom image that you would like to use to create virtual machines in your IBM Cloud account to deploy Spectrum Symphony Cluster. By default, our automation uses a base image with following HPC related packages documented here [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-symphony). If you would like to include your application specific binaries please follow the instructions [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the Spectrum Symphony cluster through this offering. | `string` | `"sym731centos77image2-ajith"` | no |
| <a name="input_login_node_instance_type"></a> [login\_node\_instance\_type](#input\_login\_node\_instance\_type) | Specify the virtual server instance profile type name to be used to create the login node for the Spectrum Symphony cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-2x8"` | no |
| <a name="input_management_node_count"></a> [management\_node\_count](#input\_management\_node\_count) | Number of management nodes. This is the total number of primary, secondary and management nodes. There will be one Primary, one Secondary and the rest of the nodes will be management nodes. Enter a value in the range 1 - 10. | `number` | `3` | no |
| <a name="input_management_node_instance_type"></a> [management\_node\_instance\_type](#input\_management\_node\_instance\_type) | Specify the virtual server instance profile type name to be used to create the management nodes for the Spectrum Symphony cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-4x16"` | no |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region name where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region). | `string` | `"us-south"` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group name from your IBM Cloud account where the VPC resources should be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs). | `string` | `"Default"` | no |
| <a name="input_ssh_allowed_ips"></a> [ssh\_allowed\_ips](#input\_ssh\_allowed\_ips) | Comma separated list of IP addresses that can access the Spectrum Symphony instance through SSH interface. The default value allows any IP address to access the cluster. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Comma-separated list of names of the SSH key configured in your IBM Cloud account that is used to establish a connection to the Symphony primary node. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given here. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys). | `string` | n/a | yes |
| <a name="input_storage_node_instance_type"></a> [storage\_node\_instance\_type](#input\_storage\_node\_instance\_type) | Specify the virtual server instance profile type to be used to create the storage nodes for the Spectrum Symphony cluster. The storage nodes are the ones that are used to create an NFS instance to manage the data for HPC workloads. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-2x8"` | no |
| <a name="input_sym_entitlement_ego"></a> [sym\_entitlement\_ego](#input\_sym\_entitlement\_ego) | EGO Entitlement file content for Symphony license scheduler. You can either download this from Passport Advantage or get it from an existing Symphony install. NOTE: If the value specified for this field is incorrect the virtual machines would be provisioned to build the Symphony cluster, but cluster would not start to process workload submissions. You would incur charges for the duration the virtual server machines would continue to run. [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-symphony?topic=ibm-spectrum-symphony-getting-started-tutorial). | `string` | `"ego_base   3.9   31/12/2021   ()   ()   ()   6a6f0b9f738ccae7a7258fb7a7429195d3a224fa"` | no |
| <a name="input_sym_entitlement_soam"></a> [sym\_entitlement\_soam](#input\_sym\_entitlement\_soam) | SOAM Entitlement file content for core Spectrum software. You can either download this from Passport Advantage or get it from an existing Symphony install.NOTE: If the value specified for this field is incorrect the virtual machines would be provisioned to build the Spectrum Symphony cluster, but cluster would not start to process workload submissions.You would incur charges for the duration the virtual server machines would continue to run. [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-symphony?topic=ibm-spectrum-symphony-getting-started-tutorial). | `string` | `"sym_advanced_edition   7.3.1   31/12/2021   ()   ()   ()   ddc1cbbd0fab0b1e2c1a7eb87e5c350e7382c0ca"` | no |
| <a name="input_sym_license_confirmation"></a> [sym\_license\_confirmation](#input\_sym\_license\_confirmation) | Confirm your use of IBM Spectrum Symphony licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html). | `string` | n/a | yes |
| <a name="input_volume_capacity"></a> [volume\_capacity](#input\_volume\_capacity) | Size in GB for the block storage that would be used to build the NFS instance and would be available as a mount on Spectrum Symphony primary node. Enter a value in the range 10 - 16000. | `number` | `100` | no |
| <a name="input_volume_iops"></a> [volume\_iops](#input\_volume\_iops) | Number to represent the IOPS(Input Output Per Second) configuration for block storage to be used for NFS instance (valid only for volume\_profile=custom, dependent on volume\_capacity). Enter a value in the range 100 - 48000. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles#custom). | `number` | `300` | no |
| <a name="input_volume_profile"></a> [volume\_profile](#input\_volume\_profile) | Name of the block storage volume type to be used for NFS instance. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles). | `string` | `"general-purpose"` | no |
| <a name="input_worker_node_instance_type"></a> [worker\_node\_instance\_type](#input\_worker\_node\_instance\_type) | Specify the virtual server instance profile type name to be used to create the worker nodes for the Spectrum Symphony cluster. The worker nodes are the ones where the workload execution takes place and the choice should be made according to the characteristic of workloads. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-4x16"` | no |
| <a name="input_worker_node_max_count"></a> [worker\_node\_max\_count](#input\_worker\_node\_max\_count) | The maximum number of worker nodes that should be added to Spectrum Symphony cluster. This is to limit the number of machines that can be added to Spectrum Symphony cluster when auto-scaling configuration is used. This property can be used to manage the cost associated with Spectrum Symphony cluster instance. Enter a value in the range 1 - 500. | `number` | `10` | no |
| <a name="input_worker_node_min_count"></a> [worker\_node\_min\_count](#input\_worker\_node\_min\_count) | The minimum number of worker nodes. This is the number of worker nodes that will be provisioned at the time the cluster is created. Enter a value in the range 0 - 500. | `number` | `0` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | IBM Cloud zone name within the selected region where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli). | `string` | `"us-south-3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | n/a |
