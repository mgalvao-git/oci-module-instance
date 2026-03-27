variable "compartment_ocid" {
  description = "Compartment OCID"
  type        = string
} 

variable "AD" {
  description = "Availability Domain"
  type        = string
  default     = null
}

variable "this" {
  description = "List of instances to create"

  type = list(object({
    hostname         = string
    os_type          = optional(string, "linux")  
    shape            = string
    ocpu             = number
    memory           = number
    fault_domain     = string
    subnet_ocid      = string
    image_type       = string
    image_id         = string

    disks = optional(list(object({
      size_gb = number
      vpu     = number
      type    = optional(string, "iscsi")
    })), [])

    assign_public_ip = bool
  }))

  validation {
    condition = alltrue(flatten([
      for inst in var.this : [
        for d in inst.disks :
        inst.os_type == "linux"
        ? contains(["iscsi", "paravirtualized"], d.type)
        : d.type == "iscsi"
      ]
    ]))
    error_message = "Windows only supports iscsi disks. Paravirtualized is allowed only for Linux."
  }
}

variable "ssh_public_key_root_sneadm001" {
  description = "SSH root public key"
  type        = string
}

variable "ssh_public_key_olam" {
  description = "SSH OLAM public key"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Bootstrap file for cloud-init"
  type        = string
  default     = null
}

variable "preserve_boot_volume" {
  description = "Preserve boot volume when deleting instance"
  type        = bool
  default     = false
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size"
  type        = number
  default     = 50
}

variable "instance_timeout" {
  description = "Timeout for instance creation"
  type        = string
  default     = "25m"
}

variable "defined_tags" {
  description = "Defined tags"
  type        = map(any)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags"
  type        = map(string)
  default     = {}
}

variable "skip_source_dest_check" {
  description = "Disable source/destination check on VNIC"
  type        = bool
  default     = false
}

variable "attachment_type" {
  description = "Volume attachment type (iscsi/paravirtualized)"
  type        = string
  default     = "iscsi"
}

variable "use_chap" {
  description = "Use CHAP if attachment_type=iscsi"
  type        = bool
  default     = false
}

variable "extended_metadata" {
  description = "Additional metadata for each instance"
  type        = map(any)
  default     = {}
}

variable "ipxe_script" {
  description = "iPXE script for custom boot"
  type        = string
  default     = null
}

variable "disk_tags" {
  description = "Defined tags for additional disks"
  type        = map(any)
  default     = {}
}

variable "vm_tags" {
  description = "Defined tags for virtual machines"
  type        = map(any)
  default     = {}
}
