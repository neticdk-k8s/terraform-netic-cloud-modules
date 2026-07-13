variable "okms_id" {
  type        = string
  description = "OKMS-instansens ID (output 'id' fra keyvault-modulet)."
}

variable "secrets" {
  type        = map(string)
  description = "Map af secret-navn (path) → værdi, fx { login = \"kodeord\" }."
  sensitive   = true
}
