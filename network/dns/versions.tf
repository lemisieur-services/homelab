terraform {
  cloud {
    organization = "lab-lemisieur-com"
    workspaces {
      name = "homelab-network-dns"
    }
  }
  required_providers {
    unifi = {
      source = "ubiquiti-community/unifi"
      version = "0.41.12"
    }
  }
}

provider "unifi" {} # Credentials injected in the Terraform workspace environment
## https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs#example-usage