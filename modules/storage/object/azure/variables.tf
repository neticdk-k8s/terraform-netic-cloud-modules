variable "name" {
  description = "Storage account name (3-24 chars, lowercase alphanumeric only, globally unique)"
  type        = string
}

variable "resource_group" {
  description = "Azure resource group name"
  type        = string
}

variable "location" {
  description = "Azure region (e.g. 'denmarkeast')"
  type        = string
}

variable "replication_type" {
  description = "Storage account replication type (e.g. 'LRS', 'GRS')"
  type        = string
  default     = "LRS"
}

variable "versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Soft-delete retention days (0 = disabled)"
  type        = number
  default     = 7
}

variable "container_name" {
  description = "Name of the blob container"
  type        = string
  default     = "data"
}
