variable "region" {
  description = "Region for the state bucket (use the same region as the main stack)."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used in the bucket name and tags."
  type        = string
  default     = "conduit"
}

variable "noncurrent_version_retention_days" {
  description = "How long old state versions are kept for recovery."
  type        = number
  default     = 90
}
