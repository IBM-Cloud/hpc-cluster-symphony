# hpc-cluster-symphony
Repository for the HPC Cluster Symphony implementation files.

# Deployment with Schematics CLI on IBM Cloud

Initial configuration:

```
$ cp sample/configs/hpc_workspace_config.json config.json
$ ibmcloud iam api-key-create my-api-key --file ~/.ibm-api-key.json -d "my api key"
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

# Deployment with Schematics UI on IBM Cloud

1. Go to <https://cloud.ibm.com/schematics/workspaces> and create a workspace using Schematics
2. After creating the Schematics workspace, at the bottom of the page enter this github repo URL and provide the SSH token to access Github repo, and also select Terraform version as 0.14 and click Save.
3. Go to Schematic Workspace Settings, under variable section, click on "burger icons" to update the following parameters:
    - ssh_key_name with your ibm cloud SSH key name such as "symphony-ssh-key" created in a specific region in IBM Cloud
    - api_key with the api key value and mark it as sensitive to hide the API key in the IBM Cloud Console.
    - Update cluster_prefix value to the specific hostPrefix for your Symphony cluster
    - Update the management_node_count, worker_node_min_count and worker_node_max_count as per your requirement
    - To integrate spectrum scale, update spectrum_scale_enabled to true and update scale_storage_node_count, scale_storage_node_instance_type, scale_filesystem_block_size as per your requirement.
        - Update scale_storage_cluster_gui_username, scale_storage_cluster_gui_password, scale_compute_cluster_gui_username, scale_compute_cluster_gui_password. 
    
   Note: Only static worker nodes (no dynamic worker nodes) are supported with scale enabled.
4. Click on "Generate Plan" and ensure there are no errors and fix the errors if there are any
5. After "Generate Plan" gives no errors, click on "Apply Plan" to create resources.
6. Check the "Jobs" section on the left hand side to view the resource creation progress.
7. See the Log if the "Apply Plan" activity is successful and copy the output SSH command to your laptop terminal to SSH to primary node via a jump host public ip to SSH one of the nodes.
8. Also use this jump host public ip and change the IP address of the node you want to access via the jump host to access specific hosts.


# Storage Node and NFS Setup
The storage node is configured as an NFS server and the data volume is mounted to the /data directory which is exported to share with Symphony cluster nodes.

# Spectrum Scale Storage Node and GPFS Setup
* The Spectrum Scale storage nodes are configured as a GPFS cluster (owningCluster) which owns and serves the file system to be mounted. 
* AccessingCluster, i.e., the compute cluster with Primary, Secondary, Management, and worker nodes, is the cluster that accesses owningCluster, and is also configured as a GPFS cluster. 
* The file system mountpoint on owningCluster(storage gpfs Cluster) is specified in the variable scale_storage_cluster_filesystem_mountpoint. Default value = "/gpfs/fs1"
* The file system mountpoint on accessingCluster(compute gpfs Cluster) is specified in the variable compute_cluster_filesystem_mountpoint. Default value = "/gpfs/fs1"

Note: If the user elects not to use Spectrum Scale storage, the NFS file system will be used for sharing of both cluster management data and worker node application data. However, if the user elects to use Spectrum Scale storage, then that storage will be used for sharing of the worker node application data, and the NFS file system will be used only for sharing of cluster management data."


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

Note: This is applicable when scale is not enabled.
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

###### 5. steps to validate spectrum scale integration
* Login to scale storage node using SSH. (`ssh -J root@52.116.122.64 root@10.240.128.37`, 
  details will be available in the logs output with key `spectrum_scale_storage_ssh_command`)
* The below command shows the gpfs cluster setup on scale storage node.
```buildoutcfg
# /usr/lpp/mmfs/bin/mmlscluster
```
* The below command shows file system mounted on number of nodes
```buildoutcfg
# /usr/lpp/mmfs/bin/mmlsmount all
```
* The below command shows the fileserver details. This command can be used to validate file block size(Inode size in bytes).
```buildoutcfg
#   /usr/lpp/mmfs/bin/mmlsfs all -i
```
* Login to primary node using SSH. (ssh -J root@52.116.122.64 root@10.240.128.41)
* The below command shows the gpfs cluster setup on computes node. This should contain the Primary, Secondary, Management and worker nodes.
```buildoutcfg
# /usr/lpp/mmfs/bin/mmlscluster
```
* Create a file on mountpoint path(e.g `/gpfs/fs1`) and verify on other nodes that the file can be accessed.

###### 6. Steps to login a windows worker node
1. Use a remote desktop client to access your Windows instance.
2. Use corresponding IP/Floating IP of the worker node as host ip.
3. When asked for login credentials use default username - "egoadmin" and password - "Symphony@123"

# Terraform Documentation

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.1.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.65.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | 3.1.0 |
| <a name="provider_ibm"></a> [ibm](#provider\_ibm) | 1.65.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bare_metal_server"></a> [bare\_metal\_server](#module\_bare\_metal\_server) | ./resources/ibmcloud/compute/bare_metal_server | n/a |
| <a name="module_compute_cluster_configuration"></a> [compute\_cluster\_configuration](#module\_compute\_cluster\_configuration) | ./resources/scale_common/compute_configuration | n/a |
| <a name="module_compute_nodes_wait"></a> [compute\_nodes\_wait](#module\_compute\_nodes\_wait) | ./resources/scale_common/wait | n/a |
| <a name="module_dedicated_host"></a> [dedicated\_host](#module\_dedicated\_host) | ./resources/ibmcloud/dedicated_host | n/a |
| <a name="module_dedicated_host_group"></a> [dedicated\_host\_group](#module\_dedicated\_host\_group) | ./resources/ibmcloud/dedicated_host_group | n/a |
| <a name="module_dns_resolver"></a> [dns\_resolver](#module\_dns\_resolver) | ./resources/ibmcloud/network/dns_resolver | n/a |
| <a name="module_dns_service"></a> [dns\_service](#module\_dns\_service) | ./resources/ibmcloud/network/dns_service | n/a |
| <a name="module_inbound_sg_ingress_all_local_rule"></a> [inbound\_sg\_ingress\_all\_local\_rule](#module\_inbound\_sg\_ingress\_all\_local\_rule) | ./resources/ibmcloud/security/security_group_ingress_all_local | n/a |
| <a name="module_inbound_sg_rule"></a> [inbound\_sg\_rule](#module\_inbound\_sg\_rule) | ./resources/ibmcloud/security/security_group_inbound_rule | n/a |
| <a name="module_ingress_vpn"></a> [ingress\_vpn](#module\_ingress\_vpn) | ./resources/ibmcloud/security/vpn_ingress_sg_rule | n/a |
| <a name="module_invoke_compute_network_playbook"></a> [invoke\_compute\_network\_playbook](#module\_invoke\_compute\_network\_playbook) | ./resources/scale_common/ansible_playbook | n/a |
| <a name="module_invoke_compute_playbook"></a> [invoke\_compute\_playbook](#module\_invoke\_compute\_playbook) | ./resources/scale_common/ansible_playbook | n/a |
| <a name="module_invoke_remote_mount"></a> [invoke\_remote\_mount](#module\_invoke\_remote\_mount) | ./resources/scale_common/ansible_playbook | n/a |
| <a name="module_invoke_storage_network_playbook"></a> [invoke\_storage\_network\_playbook](#module\_invoke\_storage\_network\_playbook) | ./resources/scale_common/ansible_playbook | n/a |
| <a name="module_invoke_storage_playbook"></a> [invoke\_storage\_playbook](#module\_invoke\_storage\_playbook) | ./resources/scale_common/ansible_playbook | n/a |
| <a name="module_invoke_windows_security_group_rules"></a> [invoke\_windows\_security\_group\_rules](#module\_invoke\_windows\_security\_group\_rules) | ./resources/windows/security_group_rules | n/a |
| <a name="module_login_fip"></a> [login\_fip](#module\_login\_fip) | ./resources/ibmcloud/network/floating_ip | n/a |
| <a name="module_login_inbound_security_rules"></a> [login\_inbound\_security\_rules](#module\_login\_inbound\_security\_rules) | ./resources/ibmcloud/security/login_sg_inbound_rule | n/a |
| <a name="module_login_outbound_dns_rule"></a> [login\_outbound\_dns\_rule](#module\_login\_outbound\_dns\_rule) | ./resources/ibmcloud/security/login_sg_outbound_dns_rule | n/a |
| <a name="module_login_outbound_security_rule"></a> [login\_outbound\_security\_rule](#module\_login\_outbound\_security\_rule) | ./resources/ibmcloud/security/login_sg_outbound_rule | n/a |
| <a name="module_login_sg"></a> [login\_sg](#module\_login\_sg) | ./resources/ibmcloud/security/login_sg | n/a |
| <a name="module_login_ssh_key"></a> [login\_ssh\_key](#module\_login\_ssh\_key) | ./resources/scale_common/generate_keys | n/a |
| <a name="module_login_subnet"></a> [login\_subnet](#module\_login\_subnet) | ./resources/ibmcloud/network/login_subnet | n/a |
| <a name="module_login_vsi"></a> [login\_vsi](#module\_login\_vsi) | ./resources/ibmcloud/compute/login_vsi | n/a |
| <a name="module_management_node_vsi"></a> [management\_node\_vsi](#module\_management\_node\_vsi) | ./resources/ibmcloud/compute/management_node_vsi | n/a |
| <a name="module_nfs_storage"></a> [nfs\_storage](#module\_nfs\_storage) | ./resources/ibmcloud/compute/nfs_storage_vsi | n/a |
| <a name="module_nfs_volume"></a> [nfs\_volume](#module\_nfs\_volume) | ./resources/ibmcloud/network/nfs_volume | n/a |
| <a name="module_outbound_sg_rule"></a> [outbound\_sg\_rule](#module\_outbound\_sg\_rule) | ./resources/ibmcloud/security/security_group_outbound_rule | n/a |
| <a name="module_prepare_spectrum_scale_ansible_repo"></a> [prepare\_spectrum\_scale\_ansible\_repo](#module\_prepare\_spectrum\_scale\_ansible\_repo) | ./resources/scale_common/git_utils | n/a |
| <a name="module_primary_vsi"></a> [primary\_vsi](#module\_primary\_vsi) | ./resources/ibmcloud/compute/primary_vsi | n/a |
| <a name="module_public_gw"></a> [public\_gw](#module\_public\_gw) | ./resources/ibmcloud/network/public_gw | n/a |
| <a name="module_remote_mount_cluster_configuration"></a> [remote\_mount\_cluster\_configuration](#module\_remote\_mount\_cluster\_configuration) | ./resources/scale_common/remote_mount_configuration | n/a |
| <a name="module_remove_ssh_key"></a> [remove\_ssh\_key](#module\_remove\_ssh\_key) | ./resources/scale_common/remove_ssh | n/a |
| <a name="module_schematics_sg_tcp_rule"></a> [schematics\_sg\_tcp\_rule](#module\_schematics\_sg\_tcp\_rule) | ./resources/ibmcloud/security/security_tcp_rule | n/a |
| <a name="module_secondary_vsi"></a> [secondary\_vsi](#module\_secondary\_vsi) | ./resources/ibmcloud/compute/secondary_vsi | n/a |
| <a name="module_sg"></a> [sg](#module\_sg) | ./resources/ibmcloud/security/security_group | n/a |
| <a name="module_spectrum_scale_storage"></a> [spectrum\_scale\_storage](#module\_spectrum\_scale\_storage) | ./resources/ibmcloud/compute/scale_storage_vsi | n/a |
| <a name="module_storage_bare_metal_server_cluster"></a> [storage\_bare\_metal\_server\_cluster](#module\_storage\_bare\_metal\_server\_cluster) | ./resources/ibmcloud/compute/scale_storage_bare_metal_server | n/a |
| <a name="module_storage_cluster_configuration"></a> [storage\_cluster\_configuration](#module\_storage\_cluster\_configuration) | ./resources/scale_common/storage_configuration | n/a |
| <a name="module_storage_dns_permitted"></a> [storage\_dns\_permitted](#module\_storage\_dns\_permitted) | ./resources/ibmcloud/network/dns_permitted_network | n/a |
| <a name="module_storage_nodes_wait"></a> [storage\_nodes\_wait](#module\_storage\_nodes\_wait) | ./resources/scale_common/wait | n/a |
| <a name="module_storage_zone"></a> [storage\_zone](#module\_storage\_zone) | ./resources/ibmcloud/network/dns_zone | n/a |
| <a name="module_subnet"></a> [subnet](#module\_subnet) | ./resources/ibmcloud/network/subnet | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./resources/ibmcloud/network/vpc | n/a |
| <a name="module_vpc_address_prefix"></a> [vpc\_address\_prefix](#module\_vpc\_address\_prefix) | ./resources/ibmcloud/network/vpc_address_prefix | n/a |
| <a name="module_vpn"></a> [vpn](#module\_vpn) | ./resources/ibmcloud/network/vpn | n/a |
| <a name="module_vpn_connection"></a> [vpn\_connection](#module\_vpn\_connection) | ./resources/ibmcloud/network/vpn_connection | n/a |
| <a name="module_windows_worker"></a> [windows\_worker](#module\_windows\_worker) | ./resources/ibmcloud/compute/windows_worker_vsi | n/a |
| <a name="module_worker_dns_permitted"></a> [worker\_dns\_permitted](#module\_worker\_dns\_permitted) | ./resources/ibmcloud/network/dns_permitted_network | n/a |
| <a name="module_worker_vsi"></a> [worker\_vsi](#module\_worker\_vsi) | ./resources/ibmcloud/compute/worker_vsi | n/a |
| <a name="module_worker_zone"></a> [worker\_zone](#module\_worker\_zone) | ./resources/ibmcloud/network/dns_zone | n/a |
| <a name="module_write_compute_cluster_inventory"></a> [write\_compute\_cluster\_inventory](#module\_write\_compute\_cluster\_inventory) | ./resources/scale_common/write_inventory | n/a |
| <a name="module_write_storage_cluster_inventory"></a> [write\_storage\_cluster\_inventory](#module\_write\_storage\_cluster\_inventory) | ./resources/scale_common/write_inventory | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.delete_schematics_ingress_security_rule](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.entitlement_check](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.upgrade_jinja](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [http_http.fetch_myip](https://registry.terraform.io/providers/hashicorp/http/3.1.0/docs/data-sources/http) | data source |
| [ibm_dns_custom_resolvers.dns_custom_resolver](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/dns_custom_resolvers) | data source |
| [ibm_iam_auth_token.token](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/iam_auth_token) | data source |
| [ibm_is_bare_metal_server_profile.storage_bare_metal_server_profile](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_bare_metal_server_profile) | data source |
| [ibm_is_bare_metal_server_profile.worker_bare_metal_server_profile](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_bare_metal_server_profile) | data source |
| [ibm_is_dedicated_host_profiles.worker](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_dedicated_host_profiles) | data source |
| [ibm_is_image.baremetal_image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_image) | data source |
| [ibm_is_image.image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_image) | data source |
| [ibm_is_image.scale_image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_image) | data source |
| [ibm_is_image.stock_image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_image) | data source |
| [ibm_is_image.windows_worker_image](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_image) | data source |
| [ibm_is_instance_profile.login](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.management_node](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.spectrum_scale_storage](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.storage](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.worker](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_region.region](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_region) | data source |
| [ibm_is_ssh_key.ssh_key](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_ssh_key) | data source |
| [ibm_is_subnet.subnet_id](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_subnet) | data source |
| [ibm_is_subnet_reserved_ips.dns_reserved_ips](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_subnet_reserved_ips) | data source |
| [ibm_is_volume_profile.nfs](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_volume_profile) | data source |
| [ibm_is_vpc.existing_vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_vpc) | data source |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_vpc) | data source |
| [ibm_is_vpc_address_prefixes.existing_vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_vpc_address_prefixes) | data source |
| [ibm_is_zone.zone](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/is_zone) | data source |
| [ibm_resource_group.rg](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.65.1/docs/data-sources/resource_group) | data source |
| [template_file.login_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.management_node_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.primary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.scale_storage_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.secondary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.storage_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.windows_worker_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.worker_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TF_PARALLELISM"></a> [TF\_PARALLELISM](#input\_TF\_PARALLELISM) | Parallelism/ concurrent operations limit. Valid values are between 1 and 256, both inclusive. [Learn more](https://www.terraform.io/docs/internals/graph.html#walking-the-graph). | `string` | `"250"` | no |
| <a name="input_TF_VERSION"></a> [TF\_VERSION](#input\_TF\_VERSION) | The version of the Terraform engine that's used in the Schematics workspace. | `string` | `"1.1"` | no |
| <a name="input_TF_WAIT_DURATION"></a> [TF\_WAIT\_DURATION](#input\_TF\_WAIT\_DURATION) | wait duration time set for the storage and worker node to complete the entire setup | `string` | `"180s"` | no |
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | This is the IBM Cloud API key for IBM Cloud account where the IBM Spectrum Symphony cluster needs to be deployed. For more information on how to create an API key, see [Managing user API keys](https://cloud.ibm.com/docs/account?topic=account-userapikey). | `string` | n/a | yes |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Unique ID of the cluster used by Symphony for configuration of resources. This must be up to 39 alphanumeric characters including the underscore (\_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed. Do not use the name of any host or user as the name of your cluster. You cannot change it after installation. | `string` | `"HPCCluster"` | no |
| <a name="input_cluster_prefix"></a> [cluster\_prefix](#input\_cluster\_prefix) | Prefix that is used to name the Spectrum Symphony cluster and IBM Cloud resources that are provisioned to build the Spectrum Symphony cluster instance. You cannot create more than one instance of the Symphony cluster with the same name. Make sure that the name is unique. | `string` | `"hpcc-symphony"` | no |
| <a name="input_dedicated_host_enabled"></a> [dedicated\_host\_enabled](#input\_dedicated\_host\_enabled) | Set to true to use dedicated hosts for compute hosts (default: false). Note that Symphony still dynamically provisions compute hosts at public virtual server instances and dedicated hosts are used only for static compute hosts provisioned at the time the cluster is created. The number of dedicated hosts and the profile names for dedicated hosts are calculated from worker\_node\_min\_count and worker\_node\_instance\_type. | `bool` | `false` | no |
| <a name="input_dedicated_host_placement"></a> [dedicated\_host\_placement](#input\_dedicated\_host\_placement) | Specify 'pack' or 'spread'. The 'pack' option will deploy virtual server instances on one dedicated host until full before moving on to the next dedicated host. The 'spread' option will deploy virtual server instances in round-robin fashion across all the dedicated hosts. The second option should result in mostly even distribution of instances on the hosts, while the first option might result in one dedicated host being mostly empty. | `string` | `"spread"` | no |
| <a name="input_hyperthreading_enabled"></a> [hyperthreading\_enabled](#input\_hyperthreading\_enabled) | Setting this to true will enable hyper-threading in the worker nodes of the cluster(default). Otherwise, hyper-threading will be disabled. | `bool` | `true` | no |
| <a name="input_ibm_customer_number"></a> [ibm\_customer\_number](#input\_ibm\_customer\_number) | Comma-separated list of the IBM Customer Number(s) (ICN) that is used for the Bring Your Own License (BYOL) entitlement check. For more information on how to find your ICN, see [What is my IBM Customer Number (ICN)?](https://www.ibm.com/support/pages/what-my-ibm-customer-number-icn). | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Name of the custom image that you want to use to create virtual server instances in your IBM Cloud account to deploy the IBM Spectrum Symphony cluster. By default, the automation uses a base image with additional software packages mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you would like to include your application-specific binary files, follow the instructions in [ Planning for custom images ](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the IBM Spectrum Symphony cluster through this offering. | `string` | `"hpcc-symp732-scale5193-rhel88-v1-7"` | no |
| <a name="input_login_node_instance_type"></a> [login\_node\_instance\_type](#input\_login\_node\_instance\_type) | Specify the virtual server instance profile type to be used to create the login node for the Spectrum Symphony cluster. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-2x8"` | no |
| <a name="input_management_node_count"></a> [management\_node\_count](#input\_management\_node\_count) | Number of management nodes. This is the total number of primary, secondary and management nodes. There will be one Primary, one Secondary and the rest of the nodes will be management nodes. Enter a value in the range 1 - 10. | `number` | `3` | no |
| <a name="input_management_node_instance_type"></a> [management\_node\_instance\_type](#input\_management\_node\_instance\_type) | Specify the virtual server instance profile type to be used to create the management nodes for the Spectrum Symphony cluster. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-4x16"` | no |
| <a name="input_remote_allowed_ips"></a> [remote\_allowed\_ips](#input\_remote\_allowed\_ips) | Comma-separated list of IP addresses that can access the Spectrum Symphony instance through an SSH or RDP interface. For security purposes, provide the public IP addresses assigned to the devices that are authorized to establish SSH or RDP connections (for example, ["169.45.117.34"]). To fetch the IP address of the device, use [https://ipv4.icanhazip.com/](https://ipv4.icanhazip.com/). | `list(string)` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group name from your IBM Cloud account where the VPC resources should be deployed. Note: Do not modify the "Default" value if you would like to use the auto-scaling capability. For additional information on resource groups, see [Managing resource groups](https://cloud.ibm.com/docs/account?topic=account-rgs). | `string` | `"Default"` | no |
| <a name="input_scale_compute_cluster_filesystem_mountpoint"></a> [scale\_compute\_cluster\_filesystem\_mountpoint](#input\_scale\_compute\_cluster\_filesystem\_mountpoint) | Compute cluster (accessingCluster) file system mount point. The accessingCluster is the cluster that accesses the owningCluster. For more information, see [Mounting a remote GPFS file system](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=system-mounting-remote-gpfs-file). | `string` | `"/gpfs/fs1"` | no |
| <a name="input_scale_compute_cluster_gui_password"></a> [scale\_compute\_cluster\_gui\_password](#input\_scale\_compute\_cluster\_gui\_password) | Password for compute cluster GUI. Note: Password should be at least 8 characters, must have one number, one lowercase letter, one uppercase letter, and at least one unique character. Password should not contain username. | `string` | `""` | no |
| <a name="input_scale_compute_cluster_gui_username"></a> [scale\_compute\_cluster\_gui\_username](#input\_scale\_compute\_cluster\_gui\_username) | GUI user to perform system management\_node and monitoring tasks on compute cluster. Note: Username should be at least 4 characters, any combination of lowercase and uppercase letters. | `string` | `""` | no |
| <a name="input_scale_filesystem_block_size"></a> [scale\_filesystem\_block\_size](#input\_scale\_filesystem\_block\_size) | File system [block size](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=considerations-block-size). Spectrum Scale supported block sizes (in bytes) include: 256K, 512K, 1M, 2M, 4M, 8M, 16M. | `string` | `"4M"` | no |
| <a name="input_scale_storage_cluster_filesystem_mountpoint"></a> [scale\_storage\_cluster\_filesystem\_mountpoint](#input\_scale\_storage\_cluster\_filesystem\_mountpoint) | Spectrum Scale storage cluster (owningCluster) file system mount point. The owningCluster is the cluster that owns and serves the file system to be mounted.  For more information, see [Mounting a remote GPFS file system](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=system-mounting-remote-gpfs-file). | `string` | `"/gpfs/fs1"` | no |
| <a name="input_scale_storage_cluster_gui_password"></a> [scale\_storage\_cluster\_gui\_password](#input\_scale\_storage\_cluster\_gui\_password) | Password for Spectrum Scale storage cluster GUI. Note: Password should be at least 8 characters, must have one number, one lowercase letter, one uppercase letter, and at least one unique character. Password should not contain username. | `string` | `""` | no |
| <a name="input_scale_storage_cluster_gui_username"></a> [scale\_storage\_cluster\_gui\_username](#input\_scale\_storage\_cluster\_gui\_username) | GUI user to perform system management\_node and monitoring tasks on storage cluster. Note: Username should be at least 4 characters, any combination of lowercase and uppercase letters. | `string` | `""` | no |
| <a name="input_scale_storage_image_name"></a> [scale\_storage\_image\_name](#input\_scale\_storage\_image\_name) | Name of the custom image that you would like to use to create virtual machines in your IBM Cloud account to deploy the Spectrum Scale storage cluster. By default, our automation uses a base image plus the Spectrum Scale software and any other software packages that it requires. If you'd like, you can follow the instructions for [Planning for custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the Spectrum Scale storage cluster through this offering. | `string` | `"hpcc-scale5193-rhel88"` | no |
| <a name="input_scale_storage_node_count"></a> [scale\_storage\_node\_count](#input\_scale\_storage\_node\_count) | Total number of storage cluster instances that you need to provision. A minimum of three nodes and a maximum of eighteen nodes are supported if the storage\_type selected is scratch. A minimum of three nodes and a maximum of ten nodes are supported if the storage type selected is persistent. | `number` | `3` | no |
| <a name="input_scale_storage_node_instance_type"></a> [scale\_storage\_node\_instance\_type](#input\_scale\_storage\_node\_instance\_type) | Specify the virtual server instance storage profile type name to be used to create the Spectrum Scale storage nodes for the Spectrum Symphony cluster. For more information, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"cx2d-8x16"` | no |
| <a name="input_spectrum_scale_enabled"></a> [spectrum\_scale\_enabled](#input\_spectrum\_scale\_enabled) | Setting this to 'true' will enable Spectrum Scale integration with the cluster. Otherwise, Spectrum Scale integration will be disabled (default). By entering 'true' for the property you have also agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of [IBM International Program License Agreement](https://www.ibm.com/software/passportadvantage/programlicense.html). | `bool` | `false` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Comma-separated list of names of the SSH keys that is configured in your IBM Cloud account that is used to establish a connection to the Symphony primary node. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given at [SSH Keys](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys). | `string` | n/a | yes |
| <a name="input_storage_node_instance_type"></a> [storage\_node\_instance\_type](#input\_storage\_node\_instance\_type) | Specify the virtual server instance profile type to be used to create the storage node for the Spectrum Symphony cluster. The storage node is the one that would be used to create an NFS instance to manage the data for HPC workloads. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-2x8"` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Select the Spectrum Scale file system deployment method. Note: The Spectrum Scale scratch type deploys the Spectrum Scale file system on virtual server instances, and the persistent type deploys the Spectrum Scale file system on bare metal servers. | `string` | `"scratch"` | no |
| <a name="input_volume_capacity"></a> [volume\_capacity](#input\_volume\_capacity) | Size in GB for the block storage that would be used to build the NFS instance and would be available as a mount on Spectrum Symphony primary node. Enter a value in the range 10 - 16000. | `number` | `100` | no |
| <a name="input_volume_iops"></a> [volume\_iops](#input\_volume\_iops) | Number to represent the IOPS configuration for block storage to be used for NFS instance (valid only for volume\_profile=custom, dependent on volume\_capacity). Enter a value in the range 100 - 48000. For possible options of IOPS, see [Custom IOPS profile](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles#custom). | `number` | `300` | no |
| <a name="input_volume_profile"></a> [volume\_profile](#input\_volume\_profile) | Name of the block storage volume type to be used for NFS instance. For possible options, see[Block storage profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles). | `string` | `"general-purpose"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | Creates the address prefix for the new VPC, when the vpc\_name variable is empty. Only a single address prefix is allowed. For more information, see [Setting IP ranges](https://cloud.ibm.com/docs/vpc?topic=vpc-vpc-addressing-plan-design). | `list(string)` | <pre>[<br>  "10.241.0.0/18"<br>]</pre> | no |
| <a name="input_vpc_cluster_login_private_subnets_cidr_blocks"></a> [vpc\_cluster\_login\_private\_subnets\_cidr\_blocks](#input\_vpc\_cluster\_login\_private\_subnets\_cidr\_blocks) | The CIDR block that's required for the creation of the login cluster private subnet. Modify the CIDR block if it has already been reserved or used for other applications within the VPC or conflicts with any on-premises CIDR blocks when using a hybrid environment. Provide only one CIDR block for the creation of the login subnet. Since login subnet is used only for the creation of login virtual server instance provide a CIDR range of /28. | `list(string)` | <pre>[<br>  "10.241.4.0/28"<br>]</pre> | no |
| <a name="input_vpc_cluster_private_subnets_cidr_blocks"></a> [vpc\_cluster\_private\_subnets\_cidr\_blocks](#input\_vpc\_cluster\_private\_subnets\_cidr\_blocks) | The CIDR block that's required for the creation of the compute and storage cluster private subnet. Modify the CIDR block if it has already been reserved or used for other applications within the VPC or conflicts with any on-premises CIDR blocks when using a hybrid environment. Provide only one CIDR block for the creation of the compute and storage subnet. Make sure to select a CIDR block size that will accommodate the maximum number of management, storage, and both static and dynamic worker nodes that you expect to have in your cluster.  For more information on CIDR block size selection, see [Choosing IP ranges for your VPC](https://cloud.ibm.com/docs/vpc?topic=vpc-choosing-ip-ranges-for-your-vpc). | `list(string)` | <pre>[<br>  "10.241.0.0/22"<br>]</pre> | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of an existing VPC in which the cluster resources will be deployed. If no value is given, then a new VPC will be provisioned for the cluster. [Learn more](https://cloud.ibm.com/docs/vpc) | `string` | `""` | no |
| <a name="input_vpc_scale_storage_dns_domain"></a> [vpc\_scale\_storage\_dns\_domain](#input\_vpc\_scale\_storage\_dns\_domain) | IBM Cloud DNS Services domain name to be used for the Scale Storage cluster. Note: The domain name should not be the same as vpc\_worker\_dns\_domain when spectrum\_scale\_enabled is set to true. | `string` | `"dnsscale.com"` | no |
| <a name="input_vpc_worker_dns_domain"></a> [vpc\_worker\_dns\_domain](#input\_vpc\_worker\_dns\_domain) | IBM Cloud DNS Services domain name to be used for the compute cluster, e.g., test.example.corp. | `string` | `"dnsworker.com"` | no |
| <a name="input_vpn_enabled"></a> [vpn\_enabled](#input\_vpn\_enabled) | Set the value as true to deploy a VPN gateway for VPC in the cluster. | `bool` | `false` | no |
| <a name="input_vpn_peer_address"></a> [vpn\_peer\_address](#input\_vpn\_peer\_address) | The peer public IP address to which the VPN will be connected. | `string` | `""` | no |
| <a name="input_vpn_peer_cidrs"></a> [vpn\_peer\_cidrs](#input\_vpn\_peer\_cidrs) | Comma separated list of peer CIDRs (e.g., 192.168.0.0/24) to which the VPN will be connected. | `string` | `""` | no |
| <a name="input_vpn_preshared_key"></a> [vpn\_preshared\_key](#input\_vpn\_preshared\_key) | The pre-shared key for the VPN. | `string` | `""` | no |
| <a name="input_windows_image_name"></a> [windows\_image\_name](#input\_windows\_image\_name) | Name of the custom image that you want to use to create Windows® virtual server instances in your IBM Cloud account to deploy the IBM Spectrum Symphony cluster. By default, the solution uses a base image with additional software packages, which are mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you want to include your application-specific binary files, follow the instructions in [Planning for custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images&interface=ui) to create your own custom image and use that to build the IBM Spectrum Symphony cluster through this offering. | `string` | `"hpcc-sym732-win2016-v1-2"` | no |
| <a name="input_windows_worker_node"></a> [windows\_worker\_node](#input\_windows\_worker\_node) | Set to true to deploy Windows® worker nodes in the cluster. By default, the cluster deploys Linux® worker nodes. If the variable is set to true, the values of both worker\_node\_min\_count and worker\_node\_max\_count should be equal because the current implementation doesn't support dynamic creation of worker nodes through Host Factory. | `bool` | `false` | no |
| <a name="input_worker_node_instance_type"></a> [worker\_node\_instance\_type](#input\_worker\_node\_instance\_type) | Specify the virtual server instance or bare metal server profile type name to be used to create the worker nodes for the Spectrum Symphony cluster based on worker\_node\_type. The worker nodes are the ones where the workload execution takes place and the choice should be made according to the characteristic of workloads. For more information, see [virtual server instance ](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles) and [bare metal server profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-bare-metal-servers-profile&interface=ui). NOTE: If dedicated\_host\_enabled == true, available instance prefix (e.g., bx2 and cx2) can be limited depending on your target region. Check `ibmcloud target -r {region_name}; ibmcloud is dedicated-host-profiles`. | `string` | `"bx2-4x16"` | no |
| <a name="input_worker_node_max_count"></a> [worker\_node\_max\_count](#input\_worker\_node\_max\_count) | The maximum number of virtual server instance or bare metal server worker nodes that can be provisioned in the cluster. To take advantage of the auto-scale feature from [Host Factory](https://www.ibm.com/docs/en/spectrum-symphony/7.3.1?topic=factory-overview), the value needs to be greater than worker\_node\_min\_count. If using virtual server instances, enter a value in the range 1 - 500. If using bare metal servers, the value needs to match worker\_node\_min\_count, and the permitted value is in the range 1 - 16. Note: If you plan to use Spectrum Scale storage, the value for this parameter should be equal to worker\_node\_min\_count. | `number` | `10` | no |
| <a name="input_worker_node_min_count"></a> [worker\_node\_min\_count](#input\_worker\_node\_min\_count) | The minimum number of virtual server instance or bare metal server worker nodes that will be provisioned at the time the cluster is created. For bare metal servers, enter a value in the range 1 - 16. For virtual server instances with NFS storage, enter a value in the range 0 - 500. For virtual server instances with Spectrum Scale storage, enter a value in the range 1 - 64. Note: Spectrum Scale requires a minimum of 3 compute nodes (combination of primary, secondary, management, and worker nodes) to establish a [quorum](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=failure-quorum#nodequo) and maintain data consistency if a node fails. Therefore, the minimum value of 1 might need to be larger if the value specified for management\_node\_count is less than 2. | `number` | `0` | no |
| <a name="input_worker_node_type"></a> [worker\_node\_type](#input\_worker\_node\_type) | The type of server that's used for the worker nodes: virtual server instance or bare metal server. If you choose vsi, the worker nodes are deployed on virtual server instances, or if you choose baremetal, the worker nodes are deployed on bare metal servers. Note: If baremetal is selected, only static worker nodes are supported; you will not be able to use the Spectrum Symphony Host Factory feature for auto-scaling on the cluster. | `string` | `"vsi"` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | IBM Cloud zone name within the selected region where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_map_entry_found"></a> [image\_map\_entry\_found](#output\_image\_map\_entry\_found) | n/a |
| <a name="output_region_name"></a> [region\_name](#output\_region\_name) | n/a |
| <a name="output_spectrum_scale_storage_ssh_command"></a> [spectrum\_scale\_storage\_ssh\_command](#output\_spectrum\_scale\_storage\_ssh\_command) | n/a |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | n/a |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | n/a |
| <a name="output_vpn_config_info"></a> [vpn\_config\_info](#output\_vpn\_config\_info) | n/a |
