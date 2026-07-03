variable "disk" {
  type = object({
    name        = string
    size_gb     = number
    volume_type = optional(string, "classic") # classic | high-speed | high-speed-gen2
  })
  description = "Block storage volume. Region follows the openstack provider configuration."
}
