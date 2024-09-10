###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

### About VPC resources

/*
Note: Any variable in all capitalized letters is an environment variable that will be marked as hidden in the catalog title.  This variable will not be visible to customers using our offering catalog...
*/


variable "vpc_name" {
  type        = string
  description = "Name of an existing VPC in which the cluster resources will be deployed. If no value is given, then a new VPC will be provisioned for the cluster. [Learn more](https://cloud.ibm.com/docs/vpc)"
  default     = ""
}

variable "ssh_key_name" {
  type        = string
  description = "Comma-separated list of names of the SSH keys that is configured in your IBM Cloud account that is used to establish a connection to the Symphony primary node. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given at [SSH Keys](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)."
}

variable "api_key" {
  type        = string
  sensitive   = true
  description = "This is the IBM Cloud API key for IBM Cloud account where the IBM Spectrum Symphony cluster needs to be deployed. For more information on how to create an API key, see [Managing user API keys](https://cloud.ibm.com/docs/account?topic=account-userapikey)."
  validation {
    condition     = var.api_key != ""
    error_message = "API key for IBM Cloud must be set."
  }
}

variable "ibm_customer_number" {
  type        = string
  sensitive   = true
  description = "Comma-separated list of the IBM Customer Number(s) (ICN) that is used for the Bring Your Own License (BYOL) entitlement check. For more information on how to find your ICN, see [What is my IBM Customer Number (ICN)?](https://www.ibm.com/support/pages/what-my-ibm-customer-number-icn)."
  validation {
    condition     = trimspace(var.ibm_customer_number) != ""
    error_message = "Specified input for \"ibm_customer_number\" cannot be empty."
  }
}

variable "resource_group" {
  type        = string
  default     = "Default"
  description = "Resource group name from your IBM Cloud account where the VPC resources should be deployed. Note: Do not modify the \"Default\" value if you would like to use the auto-scaling capability. For additional information on resource groups, see [Managing resource groups](https://cloud.ibm.com/docs/account?topic=account-rgs)."
}

variable "cluster_prefix" {
  type        = string
  default     = "hpcc-symphony"
  description = "Prefix that is used to name the Spectrum Symphony cluster and IBM Cloud resources that are provisioned to build the Spectrum Symphony cluster instance. You cannot create more than one instance of the Symphony cluster with the same name. Make sure that the name is unique."
}

variable "cluster_id" {
  type        = string
  default     = "HPCCluster"
  description = "Unique ID of the cluster used by Symphony for configuration of resources. This must be up to 39 alphanumeric characters including the underscore (_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed. Do not use the name of any host or user as the name of your cluster. You cannot change it after installation."
  validation {
    condition     = 0 < length(var.cluster_id) && length(var.cluster_id) < 40 && can(regex("^[a-zA-Z0-9_.-]+$", var.cluster_id))
    error_message = "The ID must be up to 39 alphanumeric characters including the underscore (_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed."
  }
}

variable "zone" {
  type        = string
  description = "IBM Cloud zone name within the selected region where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli)."
}

variable "vpc_cidr_block" {
  type        = list(string)
  default     = ["10.241.0.0/18"]
  description = "Creates the address prefix for the new VPC, when the vpc_name variable is empty. Only a single address prefix is allowed. For more information, see [Setting IP ranges](https://cloud.ibm.com/docs/vpc?topic=vpc-vpc-addressing-plan-design)."
  validation {
    condition     = length(var.vpc_cidr_block) <= 1
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide one CIDR range of address prefix."
  }
}

variable "vpc_cluster_private_subnets_cidr_blocks" {
  type        = list(string)
  default     = ["10.241.0.0/22"]
  description = "The CIDR block that's required for the creation of the compute and storage cluster private subnet. Modify the CIDR block if it has already been reserved or used for other applications within the VPC or conflicts with any on-premises CIDR blocks when using a hybrid environment. Provide only one CIDR block for the creation of the compute and storage subnet. Make sure to select a CIDR block size that will accommodate the maximum number of management, storage, and both static and dynamic worker nodes that you expect to have in your cluster.  For more information on CIDR block size selection, see [Choosing IP ranges for your VPC](https://cloud.ibm.com/docs/vpc?topic=vpc-choosing-ip-ranges-for-your-vpc)."
  validation {
    condition     = length(var.vpc_cluster_private_subnets_cidr_blocks) <= 1
    error_message = "Our Solution supports only a single AZ to deploy resources. Provide one CIDR range of subnet creation."
  }
}

variable "vpc_cluster_login_private_subnets_cidr_blocks" {
  type        = list(string)
  default     = ["10.241.4.0/28"]
  description = "The CIDR block that's required for the creation of the login cluster private subnet. Modify the CIDR block if it has already been reserved or used for other applications within the VPC or conflicts with any on-premises CIDR blocks when using a hybrid environment. Provide only one CIDR block for the creation of the login subnet. Since login subnet is used only for the creation of login virtual server instance provide a CIDR range of /28."
  validation {
    condition     = length(var.vpc_cluster_login_private_subnets_cidr_blocks) <= 1
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide one CIDR range of subnet creation."
  }
  validation {
    condition     = tonumber(regex("/(\\d+)", join(",", var.vpc_cluster_login_private_subnets_cidr_blocks))[0]) <= 28
    error_message = "Our solution uses this subnet to create only a login virtual server instance, providing a bigger CIDR size will waste the usage of available IP. A CIDR range of /28 is sufficient for the creation of login subnet."
  }
}

variable "image_name" {
  type        = string
  default     = "hpcc-symp732-scale5201-rhel88-v2"
  description = "Name of the custom image that you want to use to create virtual server instances in your IBM Cloud account to deploy the IBM Spectrum Symphony cluster. By default, the automation uses a base image with additional software packages mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you would like to include your application-specific binary files, follow the instructions in [ Planning for custom images ](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the IBM Spectrum Symphony cluster through this offering."
}

variable "windows_image_name" {
  type        = string
  default     = "hpcc-sym732-win2016-v1-3"
  description = "Name of the custom image that you want to use to create Windows® virtual server instances in your IBM Cloud account to deploy the IBM Spectrum Symphony cluster. By default, the solution uses a base image with additional software packages, which are mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you want to include your application-specific binary files, follow the instructions in [Planning for custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images&interface=ui) to create your own custom image and use that to build the IBM Spectrum Symphony cluster through this offering."
}

variable "management_node_instance_type" {
  type        = string
  default     = "bx2-4x16"
  description = "Specify the virtual server instance profile type to be used to create the management nodes for the Spectrum Symphony cluster. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.management_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "worker_node_type" {
  description = "The type of server that's used for the worker nodes: virtual server instance or bare metal server. If you choose vsi, the worker nodes are deployed on virtual server instances, or if you choose baremetal, the worker nodes are deployed on bare metal servers. Note: If baremetal is selected, only static worker nodes are supported; you will not be able to use the Spectrum Symphony Host Factory feature for auto-scaling on the cluster."
  default     = "vsi"
  validation {
    condition = can(regex("^(vsi|baremetal)$", lower(var.worker_node_type)))
    #condition     = contains(["scratch", "persistent"], lower(var.storage_type))
    error_message = "Our automation support only worker node type as vsi and baremetal, provide any one of the value."
  }
}

variable "worker_node_instance_type" {
  type        = string
  default     = "bx2-4x16"
  description = "Specify the virtual server instance or bare metal server profile type name to be used to create the worker nodes for the Spectrum Symphony cluster based on worker_node_type. The worker nodes are the ones where the workload execution takes place and the choice should be made according to the characteristic of workloads. For more information, see [virtual server instance ](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles) and [bare metal server profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-bare-metal-servers-profile&interface=ui). NOTE: If dedicated_host_enabled == true, available instance prefix (e.g., bx2 and cx2) can be limited depending on your target region. Check `ibmcloud target -r {region_name}; ibmcloud is dedicated-host-profiles`."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.worker_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "vpc_worker_dns_domain" {
  type        = string
  default     = "dnsworker.com"
  description = "IBM Cloud DNS Services domain name to be used for the compute cluster, e.g., test.example.corp."
}


variable "login_node_instance_type" {
  type        = string
  default     = "bx2-2x8"
  description = "Specify the virtual server instance profile type to be used to create the login node for the Spectrum Symphony cluster. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.login_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "storage_node_instance_type" {
  type        = string
  default     = "bx2-2x8"
  description = "Specify the virtual server instance profile type to be used to create the storage node for the Spectrum Symphony cluster. The storage node is the one that would be used to create an NFS instance to manage the data for HPC workloads. For choices on profile types, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.storage_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "worker_node_min_count" {
  type        = number
  default     = 0
  description = "The minimum number of virtual server instance or bare metal server worker nodes that will be provisioned at the time the cluster is created. For bare metal servers, enter a value in the range 1 - 16. For virtual server instances with NFS storage, enter a value in the range 0 - 500. For virtual server instances with Spectrum Scale storage, enter a value in the range 1 - 64. Note: Spectrum Scale requires a minimum of 3 compute nodes (combination of primary, secondary, management, and worker nodes) to establish a [quorum](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=failure-quorum#nodequo) and maintain data consistency if a node fails. Therefore, the minimum value of 1 might need to be larger if the value specified for management_node_count is less than 2."
  validation {
    condition     = 0 <= var.worker_node_min_count && var.worker_node_min_count <= 500
    error_message = "Input \"worker_node_min_count\" must be >= 0 and <= 500."
  }
}

variable "worker_node_max_count" {
  type        = number
  default     = 10
  description = "The maximum number of virtual server instance or bare metal server worker nodes that can be provisioned in the cluster. To take advantage of the auto-scale feature from [Host Factory](https://www.ibm.com/docs/en/spectrum-symphony/7.3.1?topic=factory-overview), the value needs to be greater than worker_node_min_count. If using virtual server instances, enter a value in the range 1 - 500. If using bare metal servers, the value needs to match worker_node_min_count, and the permitted value is in the range 1 - 16. Note: If you plan to use Spectrum Scale storage, the value for this parameter should be equal to worker_node_min_count."
  validation {
    condition     = 1 <= var.worker_node_max_count && var.worker_node_max_count <= 500
    error_message = "Input \"worker_node_max_count must\" be >= 1 and <= 500."
  }
}

variable "windows_worker_node" {
  type        = bool
  default     = false
  description = "Set to true to deploy Windows® worker nodes in the cluster. By default, the cluster deploys Linux® worker nodes. If the variable is set to true, the values of both worker_node_min_count and worker_node_max_count should be equal because the current implementation doesn't support dynamic creation of worker nodes through Host Factory."
}

variable "volume_capacity" {
  type        = number
  default     = 100
  description = "Size in GB for the block storage that would be used to build the NFS instance and would be available as a mount on Spectrum Symphony primary node. Enter a value in the range 10 - 16000."
  validation {
    condition     = 10 <= var.volume_capacity && var.volume_capacity <= 16000
    error_message = "Input \"volume_capacity\" must be >= 10 and <= 16000."
  }
}

variable "volume_iops" {
  type        = number
  default     = 300
  description = "Number to represent the IOPS configuration for block storage to be used for NFS instance (valid only for volume_profile=custom, dependent on volume_capacity). Enter a value in the range 100 - 48000. For possible options of IOPS, see [Custom IOPS profile](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles#custom)."
  validation {
    condition     = 100 <= var.volume_iops && var.volume_iops <= 48000
    error_message = "Input \"volume_iops\" must be >= 100 and <= 48000."
  }
}

variable "management_node_count" {
  type        = number
  default     = 3
  description = "Number of management nodes. This is the total number of primary, secondary and management nodes. There will be one Primary, one Secondary and the rest of the nodes will be management nodes. Enter a value in the range 1 - 10."
  validation {
    condition     = 1 <= var.management_node_count && var.management_node_count <= 10
    error_message = "Input \"management_node_count\" must be >= 1 and <= 10."
  }
}

variable "hyperthreading_enabled" {
  type        = bool
  default     = true
  description = "Setting this to true will enable hyper-threading in the worker nodes of the cluster(default). Otherwise, hyper-threading will be disabled."
}

variable "vpn_enabled" {
  type        = bool
  default     = false
  description = "Set the value as true to deploy a VPN gateway for VPC in the cluster."
}

variable "vpn_peer_cidrs" {
  type        = string
  default     = ""
  description = "Comma separated list of peer CIDRs (e.g., 192.168.0.0/24) to which the VPN will be connected."
}

variable "vpn_peer_address" {
  type        = string
  default     = ""
  description = "The peer public IP address to which the VPN will be connected."
}

variable "vpn_preshared_key" {
  type        = string
  default     = ""
  description = "The pre-shared key for the VPN."
}

variable "remote_allowed_ips" {
  type        = list(string)
  description = "Comma-separated list of IP addresses that can access the Spectrum Symphony instance through an SSH or RDP interface. For security purposes, provide the public IP addresses assigned to the devices that are authorized to establish SSH or RDP connections (for example, [\"169.45.117.34\"]). To fetch the IP address of the device, use [https://ipv4.icanhazip.com/](https://ipv4.icanhazip.com/)."
  validation {
    condition = alltrue([
      for o in var.remote_allowed_ips : !contains(["0.0.0.0/0", "0.0.0.0"], o)
    ])
    error_message = "For the purpose of security provide the public IP address(es) assigned to the device(s) authorized to establish SSH connections. Use https://ipv4.icanhazip.com/ to fetch the ip address of the device."
  }
  validation {
    condition = alltrue([
      for a in var.remote_allowed_ips : can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", a))
    ])
    error_message = "Provided IP address format is not valid. Check if Ip address format has comma instead of dot and there should be double quotes between each IP address range if using multiple ip ranges. For multiple IP address use format [\"169.45.117.34\",\"128.122.144.145\"]."
  }
}

variable "volume_profile" {
  type        = string
  default     = "general-purpose"
  description = "Name of the block storage volume type to be used for NFS instance. For possible options, see[Block storage profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles)."
}

variable "dedicated_host_enabled" {
  type        = bool
  default     = false
  description = "Set to true to use dedicated hosts for compute hosts (default: false). Note that Symphony still dynamically provisions compute hosts at public virtual server instances and dedicated hosts are used only for static compute hosts provisioned at the time the cluster is created. The number of dedicated hosts and the profile names for dedicated hosts are calculated from worker_node_min_count and worker_node_instance_type."
}

variable "dedicated_host_placement" {
  type        = string
  default     = "spread"
  description = "Specify 'pack' or 'spread'. The 'pack' option will deploy virtual server instances on one dedicated host until full before moving on to the next dedicated host. The 'spread' option will deploy virtual server instances in round-robin fashion across all the dedicated hosts. The second option should result in mostly even distribution of instances on the hosts, while the first option might result in one dedicated host being mostly empty."
  validation {
    condition     = var.dedicated_host_placement == "spread" || var.dedicated_host_placement == "pack"
    error_message = "Supported values for dedicated_host_placement: spread or pack."
  }
}

variable "TF_VERSION" {
  type        = string
  default     = "1.5"
  description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable "TF_PARALLELISM" {
  type        = string
  default     = "250"
  description = "Parallelism/ concurrent operations limit. Valid values are between 1 and 256, both inclusive. [Learn more](https://www.terraform.io/docs/internals/graph.html#walking-the-graph)."
  validation {
    condition     = 1 <= var.TF_PARALLELISM && var.TF_PARALLELISM <= 256
    error_message = "Input \"TF_PARALLELISM\" must be >= 1 and <= 256."
  }
}

variable "spectrum_scale_enabled" {
  type        = bool
  default     = false
  description = "Setting this to 'true' will enable Spectrum Scale integration with the cluster. Otherwise, Spectrum Scale integration will be disabled (default). By entering 'true' for the property you have also agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of [IBM International Program License Agreement](https://www.ibm.com/software/passportadvantage/programlicense.html)."
}

variable "vpc_scale_storage_dns_domain" {
  type        = string
  default     = "dnsscale.com"
  description = "IBM Cloud DNS Services domain name to be used for the Scale Storage cluster. Note: The domain name should not be the same as vpc_worker_dns_domain when spectrum_scale_enabled is set to true."
}

variable "scale_storage_image_name" {
  type        = string
  default     = "hpcc-scale5201-rhel88"
  description = "Name of the custom image that you would like to use to create virtual machines in your IBM Cloud account to deploy the Spectrum Scale storage cluster. By default, our automation uses a base image plus the Spectrum Scale software and any other software packages that it requires. If you'd like, you can follow the instructions for [Planning for custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the Spectrum Scale storage cluster through this offering."
}

variable "scale_storage_node_count" {
  type        = number
  default     = 3
  description = "Total number of storage cluster instances that you need to provision. A minimum of three nodes and a maximum of eighteen nodes are supported if the storage_type selected is scratch. A minimum of three nodes and a maximum of ten nodes are supported if the storage type selected is persistent."
}

variable "scale_storage_node_instance_type" {
  type        = string
  default     = "cx2d-8x16"
  description = "Specify the virtual server instance storage profile type name to be used to create the Spectrum Scale storage nodes for the Spectrum Symphony cluster. For more information, see [Instance profiles](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
}


variable "scale_storage_cluster_filesystem_mountpoint" {
  type        = string
  default     = "/gpfs/fs1"
  description = "Spectrum Scale storage cluster (owningCluster) file system mount point. The owningCluster is the cluster that owns and serves the file system to be mounted.  For more information, see [Mounting a remote GPFS file system](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=system-mounting-remote-gpfs-file)."

  validation {
    condition     = can(regex("^\\/[a-z0-9A-Z-_]+\\/[a-z0-9A-Z-_]+$", var.scale_storage_cluster_filesystem_mountpoint))
    error_message = "Specified value for \"storage_cluster_filesystem_mountpoint\" is not valid (valid: /gpfs/fs1)."
  }
}

variable "scale_filesystem_block_size" {
  type        = string
  default     = "4M"
  description = "File system [block size](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=considerations-block-size). Spectrum Scale supported block sizes (in bytes) include: 256K, 512K, 1M, 2M, 4M, 8M, 16M."

  validation {
    condition     = can(regex("^256K$|^512K$|^1M$|^2M$|^4M$|^8M$|^16M$", var.scale_filesystem_block_size))
    error_message = "Specified block size must be a valid IBM Spectrum Scale supported block sizes (256K, 512K, 1M, 2M, 4M, 8M, 16M)."
  }
}

variable "scale_storage_cluster_gui_username" {
  type        = string
  sensitive   = true
  default     = ""
  description = "GUI user to perform system management_node and monitoring tasks on storage cluster. Note: Username should be at least 4 characters, any combination of lowercase and uppercase letters."
  validation {
    condition     = var.scale_storage_cluster_gui_username == "" || (length(var.scale_storage_cluster_gui_username) >= 4 && length(var.scale_storage_cluster_gui_username) <= 32)
    error_message = "Specified input for \"storage_cluster_gui_username\" is not valid. username should be greater or equal to 4 letters."
  }
}

variable "scale_storage_cluster_gui_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Password for Spectrum Scale storage cluster GUI. Note: Password should be at least 8 characters, must have one number, one lowercase letter, one uppercase letter, and at least one unique character. Password should not contain username."
  validation {
    condition     = var.scale_storage_cluster_gui_password == "" || (length(var.scale_storage_cluster_gui_password) >= 8 && length(var.scale_storage_cluster_gui_password) <= 32)
    error_message = "Password should be at least 8 characters, must have one number, one lowercase letter, and one uppercase letter, at least one unique character. Password Should not contain username."
  }
}

variable "scale_compute_cluster_gui_username" {
  type        = string
  sensitive   = true
  default     = ""
  description = "GUI user to perform system management_node and monitoring tasks on compute cluster. Note: Username should be at least 4 characters, any combination of lowercase and uppercase letters."
  validation {
    condition     = var.scale_compute_cluster_gui_username == "" || (length(var.scale_compute_cluster_gui_username) >= 4 && length(var.scale_compute_cluster_gui_username) <= 32)
    error_message = "Specified input for \"storage_cluster_gui_username\" is not valid. username should be greater or equal to 4 letters."
  }
}

variable "scale_compute_cluster_gui_password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Password for compute cluster GUI. Note: Password should be at least 8 characters, must have one number, one lowercase letter, one uppercase letter, and at least one unique character. Password should not contain username."
  validation {
    condition     = var.scale_compute_cluster_gui_password == "" || (length(var.scale_compute_cluster_gui_password) >= 8 && length(var.scale_compute_cluster_gui_password) <= 32)
    error_message = "Password should be at least 8 characters, must have one number, one lowercase letter, and one uppercase letter, at least one unique character. Password Should not contain username."
  }
}

variable "scale_compute_cluster_filesystem_mountpoint" {
  type        = string
  default     = "/gpfs/fs1"
  description = "Compute cluster (accessingCluster) file system mount point. The accessingCluster is the cluster that accesses the owningCluster. For more information, see [Mounting a remote GPFS file system](https://www.ibm.com/docs/en/spectrum-scale/5.1.5?topic=system-mounting-remote-gpfs-file)."

  validation {
    condition     = can(regex("^\\/[a-z0-9A-Z-_]+\\/[a-z0-9A-Z-_]+$", var.scale_compute_cluster_filesystem_mountpoint))
    error_message = "Specified value for \"compute_cluster_filesystem_mountpoint\" is not valid (valid: /gpfs/fs1)."
  }
}

variable "TF_WAIT_DURATION" {
  type        = string
  default     = "180s"
  description = "wait duration time set for the storage and worker node to complete the entire setup"
}

variable "storage_type" {
  type        = string
  default     = "scratch"
  description = "Select the Spectrum Scale file system deployment method. Note: The Spectrum Scale scratch type deploys the Spectrum Scale file system on virtual server instances, and the persistent type deploys the Spectrum Scale file system on bare metal servers."
  validation {
    condition     = can(regex("^(scratch|persistent)$", lower(var.storage_type)))
    error_message = "The solution only support scratch and persistent. Provide any one of the value."
  }
}
