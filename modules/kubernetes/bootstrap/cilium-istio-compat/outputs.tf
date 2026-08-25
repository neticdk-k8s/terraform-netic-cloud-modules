output "enabled" {
  description = "Whether the overrides were applied"
  value       = var.enabled
}

output "name" {
  description = "Name of the CiliumNodeConfig object"
  value       = var.enabled ? var.name : null
}

output "settings" {
  description = "The Cilium options that were overridden"
  value       = var.enabled ? var.settings : {}
}
