variable "public_ip" {
  type = object({
    name            = string
    location        = string
    resource_group  = string
    prevent_destroy = optional(bool, true)
    tags            = optional(map(string), {})
  })
}
