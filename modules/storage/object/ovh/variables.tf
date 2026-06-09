variable "ovh_project_id" {
  description = "OVH Cloud project ID / service name"
  type        = string
}

variable "name" {
  description = "Name of the object storage bucket"
  type        = string
}

variable "region" {
  description = "OVH region (e.g. 'GRA')"
  type        = string
  default     = "GRA"
}

variable "versioning" {
  description = "Versioning status: 'enabled' or 'disabled'"
  type        = string
  default     = "enabled"
}

variable "encryption_sse" {
  description = "Server-side encryption algorithm (e.g. 'AES256')"
  type        = string
  default     = "AES256"
}

variable "object_lock_days" {
  description = "Retention period in days (0 = disabled)"
  type        = number
  default     = 0
}
