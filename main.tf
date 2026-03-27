terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

####################################################
# Get all Availability Domains for the region
####################################################
data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}

locals {
  # Availability Domains
  ADs = [
    for ad in data.oci_identity_availability_domains.ad.availability_domains :
    ad.name
  ]

  # Default Tags
  merged_freeform_tags = merge(
    {
      module           = "oci-instances"
      create_date_olam = formatdate("YYYYMMDD-hhmmss", timestamp())
    },
    var.freeform_tags
  )

  # Normalize user inputs
  this_normalized = [
    for inst in var.this : merge(
      {
        os_type = "linux"
        disks   = []
      },
      inst
    )
  ]
}

############
# Shapes
############
data "oci_core_shapes" "ad1" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ADs[0]
}

############
# Instance
############
resource "oci_core_instance" "this" {
   for_each = { for inst in var.this : inst.hostname => inst }
  availability_domain   = var.AD != null ? var.AD : "AD-1"
  fault_domain          = each.value.fault_domain
  compartment_id    = var.compartment_ocid
  display_name        = each.value.hostname
  extended_metadata = var.extended_metadata
  ipxe_script       = var.ipxe_script
  preserve_boot_volume = var.preserve_boot_volume
  shape               = each.value.shape
  freeform_tags = local.merged_freeform_tags
  defined_tags  = var.defined_tags
  lifecycle {
    ignore_changes = [
      freeform_tags["create_date_olam"]
    ]
  }

  shape_config {
    memory_in_gbs = each.value.memory
    ocpus         = each.value.ocpu
  }

  create_vnic_details {
    subnet_id           = each.value.subnet_ocid
    assign_public_ip    = each.value.assign_public_ip
    display_name        = "${each.value.hostname}-vnic"
    hostname_label      = each.value.hostname
    skip_source_dest_check = var.skip_source_dest_check
    defined_tags   =  var.defined_tags

  }
metadata = merge(
  each.value.os_type == "linux" ? {
    ssh_authorized_keys = join("\n", compact([ 
      var.ssh_public_key_root_sneadm001,
      var.ssh_public_key_olam
    ]))
  } : {},
  var.user_data != null ? {
    user_data = base64encode(file(var.user_data))
  } : {}
)
  source_details {
    source_type             = each.value.image_type
    source_id               = each.value.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  timeouts {
    create = var.instance_timeout
  }
}

###########################
# Create Volumes
###########################

locals {
  volumes_map = {
    for vol in flatten([
      for inst in local.this_normalized : [
        for idx, disk in inst.disks : {
          key               = "${inst.hostname}-disk-${idx}"
          instance_hostname = inst.hostname
          disk_index        = idx
          size_gb           = disk.size_gb
          vpu               = disk.vpu
          os_type           = inst.os_type

          type = lower(trimspace(lookup(disk, "type", "iscsi")))

          attachment_type = (
            inst.os_type == "windows"
            ? "iscsi"
            : lower(trimspace(lookup(disk, "type", "iscsi")))
          )

          ad = var.AD != null ? var.AD : local.ADs[0]
        }
      ]
    ]) : vol.key => vol
  }
}

locals {
  disk_letters = split("", "bcdefghijklmnopqrstuvwxyz") # starts with 'b' because 'a' is boot
}

resource "oci_core_volume" "disks" {
  for_each = local.volumes_map

  compartment_id      = var.compartment_ocid
  availability_domain = each.value.ad
  display_name        = each.key
  size_in_gbs         = each.value.size_gb
  vpus_per_gb         = each.value.vpu
  defined_tags        = var.disk_tags
}

###########################
# Attach Volumes
###########################

resource "oci_core_volume_attachment" "attach_disks" {
  for_each = local.volumes_map

  attachment_type = each.value.attachment_type
  instance_id     = oci_core_instance.this[each.value.instance_hostname].id
  volume_id       = oci_core_volume.disks[each.key].id

  device = (
    each.value.os_type == "windows"
    ? null
    : "/dev/oracleoci/oraclevd${local.disk_letters[each.value.disk_index]}"
  )
}

# Author: Michel Galvao
