variable "src_region" {
  description = "source region"
}

variable "dest_region" {
  description = "destination region"
  type        = string
}

variable "kms_delete_window" {
  description = "kms key deletion window in days"
  type        = number
  default     = 30
}

variable "s3_acl" {
  description = "s3 bucket access list"
  type        = string
  default     = "private"
}

variable "source_bucket_name" {
  description = "name of the source bucket"
  type        = string
  default     = "source"
}

variable "destination_bucket_name" {
  description = "name of the destination bucket"
  type        = string
  default     = "destination"
}
