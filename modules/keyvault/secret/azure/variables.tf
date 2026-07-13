variable "key_vault_id" {
  type        = string
  description = "Resource ID på den Key Vault secrets skal lægges i (output 'id' fra keyvault-modulet)."
}

variable "secrets" {
  type        = map(string)
  description = "Map af secret-navn → værdi, fx { login = \"kodeord\" }."
  sensitive   = true
}

variable "content_type" {
  type        = string
  description = "Valgfri content-type på secrets (fx \"text/plain\")."
  default     = null
}
