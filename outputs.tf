// Copyright (c) 2018, 2021, Oracle and/or its affiliates.

locals {
  instances_details = [
    // display name, Primary VNIC Public/Private IP for each instance
    for i in oci_core_instance.this : <<EOT
    ${i.display_name}
    Primary-PublicIP: ${i.public_ip != "" ? i.public_ip : "N/A"}
    Primary-PrivateIP: ${i.private_ip}
    EOT
  ]
}

output "instances_summary" {
  description = "Private and Public IPs for each instance."
  value       = local.instances_details
}

output "instance_ids" {
  description = "OCIDs of the instances"
  value = [for inst in oci_core_instance.this : inst.id]
}

output "instance_ssh_public_key" {
  description = "SSH public key for login to the Linux instance."
  value       = var.ssh_public_key_root_sneadm001
}

output "instances_name_ip" {
  description = "Hostname and private IP of each instance"
  value = [
    for inst in oci_core_instance.this :
    "${inst.display_name}, ${inst.create_vnic_details[0].private_ip}"
  ]
}

output "instance_private_ips" {
  description = "Private IPs of the instances"
  value = [for inst in oci_core_instance.this : inst.create_vnic_details[0].private_ip]
}

output "instance_disks_summary" {
  description = "Readable summary of the disks per instance"

  value = [
    for k, v in local.volumes_map :
    format(
      "%s | %s | device=%s | type=%s | size=%dGB | vpu=%d",
      v.instance_hostname,
      k,
      v.os_type == "windows"
        ? "N/A"
        : "/dev/oracleoci/oraclevd${local.disk_letters[v.disk_index]}",
      v.type,
      v.size_gb,
      v.vpu
    )
  ]
}

output "instances_full_map" {
  description = "Full map of the instances with compute, network, and disks"
  value = {
    for inst in oci_core_instance.this :
    inst.display_name => {
      id             = inst.id
      shape          = inst.shape
      ocpu           = inst.shape_config[0].ocpus
      memory_gb      = inst.shape_config[0].memory_in_gbs
      fault_domain   = inst.fault_domain
      availability_domain = inst.availability_domain
      private_ip     = inst.create_vnic_details[0].private_ip
      public_ip      = inst.public_ip != "" ? inst.public_ip : null

      disks = [
        for k, v in local.volumes_map :
        {
          name            = k
          device          = "/dev/oracleoci/oraclevd${local.disk_letters[v.disk_index]}"
          type            = v.type
          size_gb         = v.size_gb
          vpu             = v.vpu
        }
        if v.instance_hostname == inst.display_name
      ]
    }
  }
}
