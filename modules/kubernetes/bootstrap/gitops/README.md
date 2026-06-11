# Kubernetes Bootstrap — GitOps

Bootstrapper en Kubernetes-cluster med GitOps via et bootstrap-script. Opretter namespace `netic-gitops-system` med git-auth secrets og kører bootstrap-scriptet.

> Dette modul kræver at `kubectl` og de nødvendige CLI-værktøjer er tilgængelige i det miljø Terraform kører i.

## Usage

```hcl
module "gitops" {
  source = "./modules/kubernetes/bootstrap/gitops"

  kubeconfig     = module.kubernetes.kubeconfig
  cluster_repo   = "github.com/my-org/my-cluster-repo.git" # uden https:// — scriptet tilføjer selv scheme og credentials
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

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `kubeconfig` | `string` | — | Raw kubeconfig-indhold til target-clusteren *(sensitive)* |
| `cluster_repo` | `string` | — | Git URL til cluster-repositoriet (uden scheme, fx `git.netic.dk/scm/xx/repo.git`) |
| `bootstrap_path` | `string` | — | Sti til cluster-reconciliation inden i repositoriet |
| `git_auth` | `map(object)` | — | Git-credentials til `netic-gitops-system`-namespace. Forventede nøgler: `netic` (username/password) og `kubernetes-config` (identity) |
| `gotk_repo` | `string` | `git.netic.dk/scm/pd/gotk-bootstrap-k8s.git` | Git URL til gotk-bootstrap-repoet (Flux-komponenter) |
| `gotk_path` | `string` | `gotk` | Sti i `gotk_repo` med `gotk-components.yaml` |
| `git_ssh_port` | `number` | `7999` | SSH-port på git-serveren, bruges til `ssh-keyscan` ved patch af `known_hosts` (7999 = Bitbucket Server-default) |

## Outputs

Ingen outputs.
