terraform {
  cloud {
    organization = "lab-lemisieur-com"
    workspaces {
      name = "digitalocean-website-lemisieur"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}
provider "digitalocean" {}# Credentials injected in the Terraform workspace environment
## https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs#example-usage