variable "key_vault" {
  type = object({
    name       = string
    region     = string # OKMS-region, fx gra11 (lowercased by the module, so GRA11 also works)
    subsidiary = string # OVH subsidiary (FR / GB / DE / IE / ...) — OKMS er konto-scoped
  })
  description = "OVHcloud KMS (OKMS) instans — konto-scoped, ikke projekt-scoped."
}
