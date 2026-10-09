output "kv_mount_path" {
  description = "KV v2 mount — SecretStore spec.provider.vault.path"
  value       = var.cluster_provider
}

output "kubernetes_auth_path" {
  description = "Kubernetes auth mount — SecretStore spec.provider.vault.auth.kubernetes.mountPath"
  value       = "${var.cluster_provider}/k8s/${var.cluster_name}"
}

output "external_secrets_role" {
  description = "Role for external-secrets — SecretStore spec.provider.vault.auth.kubernetes.role"
  value       = "external-secrets"
}

output "id" {
  description = "Changes on every (re)registration; use for depends_on"
  value       = null_resource.register.id
}
