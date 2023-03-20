# Operations

A repository of IaC to modularize and standardize cyber operations.

# Requirements

Run all commands from the project root.

# Setup

- `python3 -m venv .ops`
- `source .ops/bin/activate`
- `pip install -r requirements.txt`

## System

- Debian flavor linux (works with wsl)
- Ansible
- Terraform

## Accounts

- Digital Ocean account
- Linode account

## Environment Variables

Cloud provider default environment variables.

- `DIGITALOCEAN_TOKEN=...`
- `LINODE_TOKEN=...`

# Examples

```shell
terraform \
  -chdir=terraform/proxies/ apply \
  -auto-approve \
  -var-file ../variables.tfvars \
  -var "digitalocean_count=1"
```

```shell
terraform \
  -chdir=terraform/kali/ apply \
  -auto-approve \
  -var-file ../variables.tfvars
```
