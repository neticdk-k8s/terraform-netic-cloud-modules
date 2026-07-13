variable "secrets" {
  type        = map(string)
  description = "Map af secret-navn → værdi, fx { login = \"kodeord\" }."
  sensitive   = true
}

variable "vault" {
  type = object({
    ovh = optional(object({
      project_id           = string
      region               = string
      secret_type          = optional(string, "OPAQUE")
      payload_content_type = optional(string, "TEXT_PLAIN")
    }), null)

    azure = optional(object({
      key_vault_id = string
      content_type = optional(string, null)
    }), null)
  })
  description = "Mål-vault for secrets. Sæt præcis én af vault.ovh eller vault.azure."

  validation {
    condition     = (var.vault.ovh != null) != (var.vault.azure != null)
    error_message = "Præcis én af vault.ovh eller vault.azure skal være sat."
  }
}
