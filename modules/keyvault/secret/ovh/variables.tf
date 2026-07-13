variable "ovh_project_id" {
  type        = string
  description = "OVH Public Cloud project ID (service_name)."
}

variable "region" {
  type        = string
  description = "KMS-region hvor secrets oprettes (skal matche vaulten)."
}

variable "secrets" {
  type        = map(string)
  description = "Map af secret-navn → værdi, fx { login = \"kodeord\" }."
  sensitive   = true
}

variable "secret_type" {
  type        = string
  description = "OVH secret-type: SYMMETRIC / PUBLIC / PRIVATE / PASSPHRASE / CERTIFICATE / OPAQUE."
  default     = "OPAQUE"

  validation {
    condition     = contains(["SYMMETRIC", "PUBLIC", "PRIVATE", "PASSPHRASE", "CERTIFICATE", "OPAQUE"], var.secret_type)
    error_message = "secret_type skal være en af SYMMETRIC, PUBLIC, PRIVATE, PASSPHRASE, CERTIFICATE, OPAQUE."
  }
}

variable "payload_content_type" {
  type        = string
  description = "Content-type på payload. TEXT_PLAIN sender værdien som klartekst; APPLICATION_OCTET_STREAM kræver base64."
  default     = "TEXT_PLAIN"
}
