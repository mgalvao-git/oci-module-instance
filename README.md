## Terraform OCI Module for Instance Creation

This Terraform module creates instances in Oracle Cloud Infrastructure (OCI), automatically configuring VNICs, private IPs, block volumes, and volume attachments, with the ability to distribute the instances across multiple Availability Domains (ADs).

Terraform OCI Instances Module

Terraform module to create one or more instances in Oracle Cloud Infrastructure (OCI), allowing flexible configuration of:

Hostname
Machine shape
OCPUs and memory
Image
Subnet and VCN
Additional disks (size and VPU)
Optional public IP
Metadata and bootstrap via user_data

## Functionality

This module performs the following tasks:

Creates instances in OCI with specific configurations (machine shape, number of CPUs, memory).
Automatically configures VNICs associated with the instances.
Assigns private IPs automatically from the provided VCN/Subnet.
Creates block volumes and attaches them to the instances.
Supports creating multiple instances at the same time, balanced across defined Availability Domains (ADs).
Allows customization of instance details such as hostname, tags, metadata, and more.
Requirements
Terraform: >= 0.12
OCI Provider: >= 3.27

This module is developed to work with modern versions of Terraform and the compatible OCI provider.

## Requirements

- **Terraform**: >= 0.12
- **Provider OCI**: >= 3.27

modules/

└─ oci_instances/

   ├─ main.tf
   
   ├─ variables.tf
   
   ├─ outputs.tf
   
   └─ README.md
   


| Name                            | Type         | Description                                                                                                                                                                                 | Required | Default           |
| ------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------- |
| `compartment_ocid`              | string       | OCID of the compartment                                                                                                                                                                     | yes      | -                 |
| `AD`                            | string       | Availability Domain                                                                                                                                                                       | yes      | -                 |
| `this`                           | list(object) | List of instances to create, each object contains hostname, shape, os_type, ocpu, memory, fault_domain, subnet_ocid, image_type, image_id, disks (list of objects {size_gb, vpu, type}), assign_public_ip | yes      | -                 |
| `ssh_public_key_root_sneadm001` | string       | Root SSH public key                                                                                                                                                                        | yes      | -                 |
| `ssh_public_key_olam`  | string       | OLAM SSH public key                                                                                                                                                                         | yes      | -                 |
| `user_data`                     | string       | Bootstrap file for cloud-init                                                                                                                                                               | no       | null              |
| `preserve_boot_volume`          | bool         | Preserve boot volume when deleting instance                                                                                                                                                   | no       | false             |
| `vm_tags`                       | map(any)     | Tags defined for instances                                                                                                                                                                  | no       | {}                |
| `vnic_tags`                     | map(any)     | Tags defined for VNICs                                                                                                                                                                     | no       | {}                |
| `disk_tags`                     | map(any)     | Tags defined for disks                                                                                                                                                                     | no       | {}                |
| `instance_timeout`              | string       | Creation timeout                                                                                                                                                                           | no       | "25m"             |
| `boot_volume_size_in_gbs`       | number       | Boot volume size                                                                                                                                                                            | no       | 50                |
| `skip_source_dest_check`        | bool         | Disable source/destination check on VNIC                                                                                                                                                    | no       | false             |
| `attachment_type`               | string       | Volume type (iscsi/paravirtualized)                                                                                                                                                        | no       | "iscsi" |
| `use_chap`                      | bool         | Use CHAP if attachment_type=iscsi                                                                                                                                                          | no       | false             |


## Basic Example

- Module Features
- Multi-instance: each instance defined in var.this is created separately.
- Multi-disks: each instance can have 1 or more additional disks.
- Disks with configurable VPU and size.
- Valid device names (oraclevdb, oraclevdc, …).
- Flexible shapes: OCPU and memory defined per instance.
- Subnets and VCN assigned per instance.
- Multi-SSH keys: root + ansible tower.
- Optional user data via base64 script.
- Freeform and defined tags supported.
- Configurable timeout.

###

**Usage Example**

``` 
locals {
  instances = [
    {
      hostname      = "InstanceName-01"
      shape         = "VM.Standard.E5.Flex"
      os_type       = "windows"  # default type = linux
      ocpu          = 4
      memory        = 16
      fault_domain  = var.FD1
      subnet_ocid   = var.subnet_ocids[0]
      image_type    = "image"
      image_id      = "ocid1.image.oc1.sa-vinhedo-1.aaa..."  # OCID of Oracle Image
      disks         = [{size_gb = 50, vpu = 10, type = "iscsi"},{size_gb = 100, vpu = 20, type = "paravirtualized" }]
      assign_public_ip = true
    },
    { hostname = "InstanceName-02", shape = "VM.Standard.E5.Flex", os_type = "windows", ocpu = "2", memory = "8", fault_domain  = var.FD1, subnet_ocid = var.subnet_ocids[0], disks = [{size_gb = 50, vpu = 10, type = "paravirtualized"}], assign_public_ip = false, image_type = "image", image_id = "ocid1.image.oc1.sa-vinhedo-1..."}, # Oracle-Linux-8.10-2025.02.28-0
  ]
}

module "oci_instances" {
  source = "git::https://hello@dev.azure.com/hello/Projeto_IaC/_git/oci-module-instance"

  compartment_ocid               = var.compartment_id
  AD                             = var.AD
  ssh_public_key_root_sneadm001  = var.ssh_public_key_root_sneadm001
  ssh_public_key_olam            = var.ssh_public_key_olam
  user_data                      = "bootstrapol8.sh"
  this                            = local.instances
  preserve_boot_volume           = true
  defined_tags                   = var.vm_tags
  skip_source_dest_check         = false
}

## Outputs

| Name                   | Description                               |
| ---------------------- | ----------------------------------------- |
| `instances_name_ip`    | List of instances and their private IPs   |
| `instance_ids`         | OCIDs of the created instances            |
| `instance_private_ips` | Private IPs of the instances             |
| `instance_public_ips`  | Public IPs of the instances             |
