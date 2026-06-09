# Kubernetes Bootstrap — GitOps

Bootstrapper en Kubernetes-cluster med GitOps via et bootstrap-script. Opretter namespace `netic-gitops-system` med git-auth secrets og kører bootstrap-scriptet.

> Dette modul kræver at `kubectl` og de nødvendige CLI-værktøjer er tilgængelige i det miljø Terraform kører i.

## Usage

```hcl
module "gitops" {
  source = "./modules/kubernetes/bootstrap/gitops"

  kubeconfig     = module.kubernetes.kubeconfig
  cluster_repo   = "https://github.com/my-org/my-cluster-repo"
  bootstrap_path = "clusters/production"

  git_auth = {
    netic = {
      username = var.git_username
      password = var.git_token
    }
    kubernetes-config = {
      identity = var.deploy_key
    }
  }
}
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `kubeconfig` | `string` | Raw kubeconfig-indhold til target-clusteren *(sensitive)* |
| `cluster_repo` | `string` | Git URL til cluster-repositoriet |
| `bootstrap_path` | `string` | Sti til cluster-reconciliation inden i repositoriet |
| `git_auth` | `map(object)` | Git-credentials til `netic-gitops-system`-namespace. Forventede nøgler: `netic` (username/password) og `kubernetes-config` (identity) |

## Outputs

Ingen outputs.
