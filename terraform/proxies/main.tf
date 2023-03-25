# Set DigitalOcean provider
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
    linode = {
      source = "linode/linode"
    }
  }
}

variable "inventory_path" {}

variable "project_path" {
  default = "proxies"
}

variable "squid_user_name" {
  default = "squid"
}

variable "digitalocean_count" {
  default = 0
}

variable "linode_count" {
  default = 0
}

locals {
  combined_path           = join("/", [var.inventory_path, var.project_path])
  inventory_path          = "${local.combined_path}/inventory.ini"
  nginx_conf_path         = "${local.combined_path}/nginx.conf"
  private_key_path        = "${local.combined_path}/private.key"
  proxychains_config_path = "${local.combined_path}/proxychains.config"
  public_key_path         = "${local.combined_path}/cert.pub"
  root_password_path      = "${local.combined_path}/root-password.txt"
  squid_password_path     = "${local.combined_path}/squid-password.txt"
}

resource "random_password" "root_password" {
  length  = 20
  special = true
}

resource "random_password" "squid_password" {
  length  = 24
  special = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "root_password" {
  content         = random_password.root_password.result
  filename        = local.root_password_path
  file_permission = "0600"
}

resource "local_file" "squid_password" {
  content         = random_password.squid_password.result
  filename        = local.squid_password_path
  file_permission = "0600"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = local.private_key_path
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = local.public_key_path
  file_permission = "0600"
}

resource "random_pet" "random_name" {
  length = 2
}

resource "digitalocean_ssh_key" "ssh" {
  name       = "key-${random_pet.random_name.id}"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "linode_instance" "linodes" {
  count           = var.linode_count
  image           = "linode/ubuntu22.04"
  group           = "Terraform"
  region          = "us-east"
  type            = "g6-nanode-1"
  authorized_keys = [chomp(tls_private_key.ssh.public_key_openssh)]
  root_pass       = random_password.root_password.result
}

resource "digitalocean_droplet" "droplets" {
  count    = var.digitalocean_count
  image    = "ubuntu-22-04-x64"
  name     = "proxy-${count.index}"
  region   = "nyc1"
  ipv6     = false
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [digitalocean_ssh_key.ssh.id]
}

resource "local_file" "inventory" {
  content = templatefile("inventory.tftpl", {
    droplets : digitalocean_droplet.droplets.*.ipv4_address
    linodes : linode_instance.linodes.*.ip_address
  })
  filename   = local.inventory_path
  depends_on = [digitalocean_droplet.droplets, linode_instance.linodes]
}

resource "local_file" "proxychains_config" {
  content = templatefile("proxychains.tftpl", {
    droplets : digitalocean_droplet.droplets.*.ipv4_address
    linodes : linode_instance.linodes.*.ip_address
    username : var.squid_user_name
    password : random_password.squid_password.result
  })
  filename   = local.proxychains_config_path
  depends_on = [digitalocean_droplet.droplets, linode_instance.linodes]
}

resource "local_file" "nginx_conf" {
  content = templatefile("nginx.conf.tftpl", {
    droplets : digitalocean_droplet.droplets.*.ipv4_address
    linodes : linode_instance.linodes.*.ip_address
    username : var.squid_user_name
    password : random_password.squid_password.result
  })
  filename   = local.nginx_conf_path
  depends_on = [digitalocean_droplet.droplets, linode_instance.linodes]
}
