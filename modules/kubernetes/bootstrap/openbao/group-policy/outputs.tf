output "policy_name" {
  description = "Name of the created OpenBao policy"
  value       = vault_policy.policy.name
}

output "group_id" {
  description = "Canonical id of the created external identity group"
  value       = one(concat(vault_identity_group.group[*].id, vault_identity_group.group_jwt[*].id))
}
