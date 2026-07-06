# Public IP (Additional IP) — OVH

Knytter en **forudbestilt** OVH **Additional IP** (failover IP) til en compute-instans
via `ovh_cloud_project_failover_ip_attach`, med valgfri `prevent_destroy`-beskyttelse
(default: `false`).

> **Vigtigt — dette modul *opretter ikke* en IP.** I modsætning til Azure PIP, der
> allokerer en helt ny adresse, forudsætter en OVH Additional IP at IP-blokken
> allerede er **bestilt out-of-band** hos OVH. Modulet *router* blot den eksisterende
> IP til en instans. Du skal derfor selv angive `ip` (den forudbestilte adresse) og
> `routed_to` (instansens GUID).
>
> Skal du i stedet have en NAT'et pool-IP, brug [`network/floating-ip/ovh`](../../floating-ip/ovh).

## Usage

```hcl
module "aip" {
  source = "./modules/network/public-ip/ovh"

  public_ip = {
    service_name = var.ovh_project_id
    ip           = "203.0.113.10"
    routed_to    = module.vm.instance_id
  }
}

output "ip" { value = module.aip.ip_address }
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `public_ip.service_name` | `string` | — | OVH public cloud project ID (ovh_project_id) |
| `public_ip.ip` | `string` | — | Den forudbestilte Additional IP-adresse der skal attaches |
| `public_ip.routed_to` | `string` | — | GUID på instansen IP'en skal routes til |
| `public_ip.prevent_destroy` | `bool` | `false` | Beskyt mod utilsigtet detach |

## Outputs

| Name | Description |
|------|-------------|
| `ip_address` | Den attachede Additional IP-adresse |
| `id` | ID på Additional IP-blokken |
