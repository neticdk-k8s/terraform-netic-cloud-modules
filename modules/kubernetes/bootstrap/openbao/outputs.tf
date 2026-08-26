output "kubernetes_auth_path" {
  description = "Path of the mounted Kubernetes auth backend"
  value       = vault_auth_backend.kubernetes.path
}

output "kubernetes_auth_accessor" {
  description = "Accessor of the mounted Kubernetes auth backend"
  value       = vault_auth_backend.kubernetes.accessor
}

output "kv_mount_path" {
  description = "Path of the KV v2 engine holding the secrets. Must match spec.provider.vault.path in the SecretStores that External Secrets uses."
  value       = var.cluster_provider
}

output "kv_mount_created" {
  description = "Whether this module mounted the KV engine, or expects it to exist already"
  value       = var.create_kv_mount
}

output "secret_path_prefix" {
  description = "Where secrets for this cluster belong: <mount>/k8s/<cluster>/<namespace>/<app>. The external-secrets policy grants read/list under this prefix."
  value       = "${var.cluster_provider}/k8s/${local.cluster_name}"
}

output "cluster_name" {
  description = "Unique cluster name used for registration"
  value       = local.cluster_name
}
