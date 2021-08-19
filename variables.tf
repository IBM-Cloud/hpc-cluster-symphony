###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

### About Symphony licensing
variable "sym_entitlement_ego" {
  type        = string
  default     = "ego_base   3.9   31/12/2021   ()   ()   ()   6a6f0b9f738ccae7a7258fb7a7429195d3a224fa"
  description = "EGO Entitlement file content for Symphony license scheduler. You can either download this from Passport Advantage or get it from an existing Symphony install. NOTE: If the value specified for this field is incorrect the virtual machines would be provisioned to build the Symphony cluster, but cluster would not start to process workload submissions. You would incur charges for the duration the virtual server machines would continue to run. [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-lsf?topic=ibm-spectrum-lsf-getting-started-tutorial)"
  validation {
    condition     = trimspace(var.sym_entitlement_ego) != ""
    error_message = "EGO Entitlement for Symphony must be set."
  }
}

variable "sym_entitlement_soam" {
  type        = string
  default     = "sym_advanced_edition   7.3.1   31/12/2021   ()   ()   ()   ddc1cbbd0fab0b1e2c1a7eb87e5c350e7382c0ca"
  description = "SOAM Entitlement file content for core Spectrum software. You can either download this from Passport Advantage or get it from an existing Symphony install.NOTE: If the value specified for this field is incorrect the virtual machines would be provisioned to build the Spectrum Symphony cluster, but cluster would not start to process workload submissions.You would incur charges for the duration the virtual server machines would continue to run. [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-lsf?topic=ibm-spectrum-lsf-getting-started-tutorial)"
  validation {
    condition     = trimspace(var.sym_entitlement_soam) != ""
    error_message = "SOAM Entitlement for Symphony must be set."
  }
}

### About VPC resources
variable "ssh_key_name" {
  type        = string
  description = "Comma-separated list of names of the SSH keys configured in your IBM Cloud account that will be used to establish a connection to the Symphony master node. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given [here](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)."
}

variable "api_key" {
  type        = string
  description = "This is the API key for IBM Cloud account in which the Spectrum Symphony cluster needs to be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-userapikey)"
  validation {
    condition     = var.api_key != ""
    error_message = "API key for IBM Cloud must be set."
  }
}

variable "sym_license_confirmation" {
  type        = string
  description = "Confirm your use of IBM Spectrum Symphony licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html)."
  validation {
    condition = var.sym_license_confirmation== "true"
    error_message = "Confirm your use of IBM Spectrum Symphony licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html)."
  }
}

variable "resource_group" {
  type        = string
  default     = "Default"
  description = "Resource group name from your IBM Cloud account where the VPC resources should be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs)."
}

variable "cluster_prefix" {
  type        = string
  default     = "hpcc-symphony"
  description = "Prefix that is used to name the Spectrum Symphony cluster and IBM Cloud resources that are provisioned to build the Spectrum Symphony cluster instance. You cannot create more than one instance of the Symphony cluster with the same name. Make sure that the name is unique. Enter a prefix name, such as my-hpcc."
}

variable "cluster_id" {
  type        = string
  default     = "HPCCluster"
  description = "ID of the cluster used by Symphony for configuration of resources. Post deployment the value can be verified using command `egosh ego info`."
}

variable "region" {
  type        = string
  default     = "us-south"
  description = "IBM Cloud region name where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region)."
}

variable "zone" {
  type        = string
  default     = "us-south-3"
  description = "IBM Cloud zone name within the selected region where the Spectrum Symphony cluster should be deployed. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli)."
}

variable "image_name" {
  type        = string
  default     = "sym731centos77image2-ajith"
  description = "Name of the custom image that you would like to use to create virtual machines in your IBM Cloud account to deploy Spectrum Symphony Cluster. By default, our automation uses a base image with following HPC related packages documented here [Learn more](https://cloud.ibm.com/docs/ibm-spectrum-lsf). If you would like to include your application specific binaries please follow the instructions [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the Spectrum Symphony cluster through this offering."
}

variable "management_node_instance_type" {
  type        = string
  default     = "bx2-4x16"
  description = "Specify the virtual server instance profile type name to be used to create the management nodes for the Spectrum Symphony cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.management_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "worker_node_instance_type" {
  type        = string
  default     = "bx2-4x16"
  description = "Specify the virtual server instance profile type name to be used to create the worker nodes for the Spectrum Symphony cluster. The worker nodes are the ones where the workload execution takes place and the choice should be made according to the characteristic of workloads. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.worker_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "login_node_instance_type" {
  type        = string
  default     = "bx2-2x8"
  description = "Specify the virtual server instance profile type name to be used to create the login node for the Spectrum Symphony cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.login_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "storage_node_instance_type" {
  type        = string
  default     = "bx2-2x8"
  description = "Specify the virtual server instance profile type to be used to create the storage nodes for the Spectrum Symphony cluster. The storage nodes are the ones that are used to create an NFS instance to manage the data for HPC workloads. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.storage_node_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "worker_node_min_count" {
  type        = number
  default     = 0
  description = "The minimum number of worker nodes. This is the number of worker nodes that will be provisioned at the time the cluster is created. Enter a value in the range 0 - 500."
  validation {
    condition     = 0 <= var.worker_node_min_count && var.worker_node_min_count <= 500
    error_message = "Input \"worker_node_min_count\" must be >= 0 and <= 500."
  }
}

variable "worker_node_max_count" {
  type        = number
  default     = 10
  description = "The maximum number of worker nodes that should be added to Spectrum Symphony cluster. This is to limit the number of machines that can be added to Spectrum Symphony cluster when auto-scaling configuration is used. This property can be used to manage the cost associated with Spectrum Symphony cluster instance. Enter a value in the range 1 - 500."
  validation {
    condition     = 1 <= var.worker_node_max_count && var.worker_node_max_count <= 500
    error_message = "Input \"worker_node_max_count must\" be >= 1 and <= 500."
  }
}

variable "volume_capacity" {
  type        = number
  default     = 100
  description = "Size in GB for the block storage that would be used to build the NFS instance and would be available as a mount on Spectrum Symphony master node. Enter a value in the range 10 - 16000."
  validation {
    condition     = 10 <= var.volume_capacity && var.volume_capacity <= 16000
    error_message = "Input \"volume_capacity\" must be >= 10 and <= 16000."
  }
}

variable "volume_iops" {
  type        = number
  default     = 300
  description = "Number to represent the IOPS(Input Output Per Second) configuration for block storage to be used for NFS instance (valid only for volume_profile=custom, dependent on volume_capacity). Enter a value in the range 100 - 48000. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles#custom)"
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
  type = bool
  default = true
  description = "True to enable hyper-threading in the cluster (default). Otherwise, hyper-threading will be disabled"
}

variable "ssh_allowed_ips" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Comma separated list of IP addresses that can access the Spectrum Symphony instance through SSH interface. The default value allows any IP address to access the cluster."
}

variable "volume_profile" {
  type        = string
  default     = "general-purpose"
  description = "Name of the block storage volume type to be used for NFS instance. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-block-storage-profiles)"
}

variable "TF_VERSION" {
  type        = string
  default     = "0.14"
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
