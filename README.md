# terraform-netic-cloud-modules

Terraform-moduler til provisionering af infrastruktur på **Azure** og **OVHcloud**.

Alle moduler følger samme mønster: en `azure/`- og `ovh/`-implementering plus et fælles `wrapper/`-modul, der vælger den rigtige cloud baseret på inputkonfiguration.

## Moduloversigt

| Modul | Beskrivelse |
|-------|-------------|
| [Container Registry](modules/container_registry/wrapper/README.md) | ACR (Azure) eller OVH Container Registry |
| [Kubernetes](modules/kubernetes/wrapper/README.md) | AKS (Azure) eller OVH Managed Kubernetes |
| [Kubernetes Bootstrap GitOps](modules/kubernetes/bootstrap/gitops/README.md) | Bootstrap cluster med GitOps-script |
| [Network](modules/network/network/wrapper/README.md) | VNet/subnets (Azure) eller vRack (OVH) |
| [Public IP](modules/network/public-ip/wrapper/README.md) | Statisk public IP (Azure) eller floating IP (OVH) |
| [Security Group](modules/network/security-group/wrapper/README.md) | NSG (Azure) eller OpenStack security group (OVH) |
| [Object Storage](modules/storage/object/wrapper/README.md) | Blob Storage (Azure) eller S3-bucket (OVH) |
| [VM](modules/vm/wrapper/README.md) | Linux/Windows VM (Azure eller OVH) |

## Hurtig start

De fleste moduler bruger en nested `ovh`/`azure`-blok inde i den primære variabel til at vælge cloud. Container Registry og Object Storage bruger en separat `cloud_provider`-streng.

```hcl
# Eksempel: VM på OVH
module "vm" {
  source = "github.com/netic/terraform-netic-cloud-modules//modules/vm/wrapper"

  vm = {
    name           = "my-server"
    size           = "b2-7"
    location       = "GRA11"
    resource_group = var.ovh_project_id

    ovh = {
      project_id    = var.ovh_project_id
      image_name    = "Ubuntu 24.04"
      network_names = ["my-private-network", "Ext-Net"]
    }
  }
}
```

Se det enkelte moduls README for fuld dokumentation og eksempler.
