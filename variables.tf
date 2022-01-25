variable "src_region" {
  description = "source region"
}

variable "dest_region" {
  description = "destination region"
}

variable "kms_delete_windows" {
  description = "kms key deletion window in days"
  default     = 30
}

variable "s3_acl" {
  description = "s3 bucket access list"
  default     = "private"
}

