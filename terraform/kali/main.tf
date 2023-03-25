# Set DigitalOcean provider
terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

variable "inventory_path" {}

variable "project_path" {
  default = "kali"
}

locals {
  combined_path      = join("/", [var.inventory_path, var.project_path])
  inventory_path     = "${local.combined_path}/inventory.ini"
  root_password_path = "${local.combined_path}/root-password.txt"
  private_key_path   = "${local.combined_path}/private.key"
  public_key_path    = "${local.combined_path}/cert.pub"
  ip_address_path    = "${local.combined_path}/ip-address.txt"
}

resource "random_password" "root_password" {
  length  = 20
  special = true
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "linode_instance" "kali" {
  image           = "linode/kali"
  region          = "us-east"
  type            = "g6-nanode-1"
  label           = "kali"
  authorized_keys = [chomp(tls_private_key.ssh.public_key_openssh)]
  root_pass       = random_password.root_password.result
}

data "http" "home_ip" {
  url    = "https://ifconfig.me/"
  method = "GET"
}

resource "linode_firewall" "home_firewall" {
  label = "home"
  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["${data.http.home_ip.response_body}/32"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["${data.http.home_ip.response_body}/32"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["${data.http.home_ip.response_body}/32"]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = [linode_instance.kali.id]
}

resource "local_file" "root_password" {
  content         = random_password.root_password.result
  filename        = local.root_password_path
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

resource "local_file" "kali_ip" {
  content         = linode_instance.kali.ip_address
  filename        = local.ip_address_path
  file_permission = "0600"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tftpl", {
    kali_ip : linode_instance.kali.ip_address
  })
  filename   = local.inventory_path
  depends_on = [linode_instance.kali]
}
