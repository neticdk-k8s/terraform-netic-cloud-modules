output "vm_name" {
  description = "The name of the created virtual machine"
  value       = local.is_windows ? one(openstack_compute_instance_v2.VMWindows[*].name) : one(openstack_compute_instance_v2.VMLinux[*].name)
}

output "vm_ip" {
  description = "The primary IPv4 address of the virtual machine"
  value       = local.is_windows ? one(openstack_compute_instance_v2.VMWindows[*].access_ip_v4) : one(openstack_compute_instance_v2.VMLinux[*].access_ip_v4)
}

output "public_ip" {
  description = "Public IP address assigned from the Ext-Net network"
  value       = local.is_windows ? one([for net in flatten(openstack_compute_instance_v2.VMWindows[*].network) : net.fixed_ip_v4 if net.name == "Ext-Net"]) : one([for net in flatten(openstack_compute_instance_v2.VMLinux[*].network) : net.fixed_ip_v4 if net.name == "Ext-Net"])
}

output "ssh_private_key" {
  description = "Generated SSH private key in PEM format. Only set when no sshkey was provided."
  value       = local.create_ssh_key ? tls_private_key.ssh_key[0].private_key_pem : null
  sensitive   = true
}
