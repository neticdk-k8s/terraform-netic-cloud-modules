variable "key_vault" {
  type = object({
    name       = string
    region     = string # OKMS-region, fx eu-west-gra
    subsidiary = string # OVH subsidiary (FR / GB / DE / IE / ...) — OKMS er konto-scoped
  })
  description = "OVHcloud KMS (OKMS) instans — konto-scoped, ikke projekt-scoped."
}
