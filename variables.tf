# common variables for both OCI environment and on-prem simulation

variable "tenancy_ocid" {
  description = "Your Tenancy OCID"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment where resources are to be created & maintained"
  type        = string
}

variable "instance_shape" {
  default     = "VM.Standard.A1.Flex"
  description = "Shape for backend instances"
  type        = string
}

variable "instance_ocpus" {
  default     = 3
  description = "OCPU count for backend instances"
  type        = number
}

variable "instance_memory_in_gbs" {
  default     = 8
  description = "RAM size for backend instances"
  type        = number
}

variable "ssh_public_key" {
  description = "Contents of SSH public key file. Used to enable login to instance with corresponding private key. Required for automation with Ansible. Will be used for all VMs of all backend sets."
  type        = string
}

variable "ssh_private_key_local_path" {
  description = "Local Path of SSH private key file. Used to login to instance. Required for automation with Ansible. Will be used for all VMs of all backend sets."
  type        = string
}


variable "oci_region" {
  description = "OCI region. Full name like us-ashburn-1."
  type        = string
  default = "us-phoenix-1"
}
variable "oci_vcn_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "oci_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "backend_hs1_count" {
  type = number
  default = 1
}

variable "backend_hs2_count" {
  type = number
  default = 1
}

variable "backend_hs3_count" {
  type = number
  default = 1
}

data "oci_core_images" "oracle_linux_images_oci" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.instance_shape #"VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Grab AD data for OCI VCN
data "oci_identity_availability_domains" "ad_list" {
  compartment_id = var.tenancy_ocid
}


