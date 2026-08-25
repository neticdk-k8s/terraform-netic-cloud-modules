output "secret_name" {
  description = "Name of the seal Secret that was created"
  value       = var.secret_name
}

output "namespace" {
  description = "Namespace the seal Secret was created in"
  value       = var.namespace
}

output "auth_method" {
  description = "Which auth mode the Secret was written for — \"mtls\" or \"token\". Determines the Helm values the chart needs."
  value       = local.use_mtls ? "mtls" : "token"
}

output "client_cert_path" {
  description = "Secret key holding the client certificate (mTLS only). Project this into the pod as a file and point OVHCLOUDKMS_CLIENT_CERT at it."
  value       = local.use_mtls ? "client_cert.pem" : null
}

output "client_key_path" {
  description = "Secret key holding the client private key (mTLS only). Project this into the pod as a file and point OVHCLOUDKMS_CLIENT_KEY at it."
  value       = local.use_mtls ? "client_key.pem" : null
}
