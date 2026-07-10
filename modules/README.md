# Moduler

## Container Registry

| Modul | Beskrivelse |
|-------|-------------|
| [azure](container_registry/azure/README.md) | Azure Container Registry (ACR) med brugere og IP-restriktioner |
| [ovh](container_registry/ovh/README.md) | OVH Managed Container Registry med brugere og IP-restriktioner |
| [wrapper](container_registry/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `cloud_provider` |

## Kubernetes

| Modul | Beskrivelse |
|-------|-------------|
| [azure](kubernetes/azure/README.md) | Azure Kubernetes Service (AKS) |
| [ovh](kubernetes/ovh/README.md) | OVHcloud Managed Kubernetes |
| [wrapper](kubernetes/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `cloud_settings.cloud_provider` |
| [nodepool/azure](kubernetes/nodepool/azure/README.md) | Ekstra AKS user node pool |
| [nodepool/ovh](kubernetes/nodepool/ovh/README.md) | Ekstra OVH node pool(s) — én pr. zone i 3AZ |
| [nodepool/wrapper](kubernetes/nodepool/wrapper/README.md) | Fælles indgangspunkt — tilføj node pool via `nodepool.azure` / `nodepool.ovh` |
| [bootstrap/gitops](kubernetes/bootstrap/gitops/README.md) | Bootstrap cluster med GitOps og git-auth secrets |

## Network

| Modul | Beskrivelse |
|-------|-------------|
| [network/azure](network/network/azure/README.md) | Azure VNet med subnets og NSG'er |
| [network/ovh](network/network/ovh/README.md) | OVH vRack private network med regionale subnets |
| [network/wrapper](network/network/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `network.azure` / `network.ovh` |
| [public-ip/azure](network/public-ip/azure/README.md) | Statisk Standard public IP i Azure |
| [public-ip/ovh](network/public-ip/ovh/README.md) | Floating IP fra OVH Ext-Net |
| [public-ip/wrapper](network/public-ip/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `public_ip.azure` / `public_ip.ovh` |
| [security-group/azure](network/security-group/azure/README.md) | Azure NSG med regler |
| [security-group/ovh](network/security-group/ovh/README.md) | OpenStack security group med regler |
| [security-group/wrapper](network/security-group/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `security_group.azure` / `security_group.ovh` |
| [gateway/azure](network/gateway/azure/README.md) | Azure NAT Gateway — udgående internet for subnets via én public IP |
| [gateway/ovh](network/gateway/ovh/README.md) | OVH Public Cloud Gateway — udgående internet (SNAT) for privat net |
| [gateway/wrapper](network/gateway/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `gateway.azure` / `gateway.ovh` |

## Storage

| Modul | Beskrivelse |
|-------|-------------|
| [object/azure](storage/object/azure/README.md) | Azure Blob Storage account med container |
| [object/ovh](storage/object/ovh/README.md) | OVH S3-kompatibel object storage bucket |
| [object/wrapper](storage/object/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `cloud_provider` |

## VM

| Modul | Beskrivelse |
|-------|-------------|
| [azure](vm/azure/README.md) | Linux/Windows VM i Azure med NIC og valgfri public IP |
| [ovh](vm/ovh/README.md) | Linux/Windows VM på OVH via OpenStack |
| [wrapper](vm/wrapper/README.md) | Fælles indgangspunkt — vælg cloud via `vm.azure` / `vm.ovh` |
