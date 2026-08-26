output "root_token" {
  description = <<-EOT
    Initial root token. Persist it to a real secret store, then consider
    replacing it: root tokens carry every capability and cannot be scoped. The
    usual practice is to use it once to create a policy-limited token or AppRole
    for automation, and revoke root afterwards.
  EOT
  value       = local.root_token
  sensitive   = true
}

output "recovery_keys" {
  description = "Recovery key shares, base64. Shown exactly once — without these and without the KMS key, the data is unrecoverable."
  value       = local.recovery_keys
  sensitive   = true
}

# Guards against the failure mode where a field-name mismatch silently yields an
# empty list, so a caller believes it has stored a backup that does not exist.
check "recovery_keys_present" {
  assert {
    condition     = local.root_token == "" || length(local.recovery_keys) > 0
    error_message = "OpenBao was initialised but no recovery keys were parsed from the init output. Do not treat them as backed up — inspect the state file before deleting it."
  }
}

output "api_addr" {
  description = "In-cluster API address of the OpenBao server. Use as VAULT_ADDR from inside the cluster; from outside, use the ingress hostname instead."
  value       = local.bao_addr
}

output "state_file" {
  description = "Path the init JSON was written to. Delete it once the outputs are stored somewhere durable."
  value       = local.state_file
}
