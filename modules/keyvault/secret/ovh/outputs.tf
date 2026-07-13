output "secret_ids" {
  description = "Map: secret-navn → path i OKMS (okms_secret har intet selvstændigt id — identificeres af okms_id + path)"
  value       = { for k, s in ovh_okms_secret.this : k => s.path }
}
