terraform {
  required_version = "~> 1.17.0"

  backend "s3" {
    bucket                      = "terraform-states"
    key                         = "dns/dns-01.tfstate"
    use_lockfile                = true
    use_path_style              = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }

  required_providers {
    technitium = {
      source  = "registry.terraform.io/bartei/technitium"
      version = "1.0.1"
    }
  }
}

provider "technitium" {
  server_url = var.technitium_server_url
  api_token  = var.technitium_api_token
}

locals {
  zone_files = fileset("${path.module}/zones", "*.yaml")
  zone_configs = {
    for file in local.zone_files :
    file => yamldecode(file("${path.module}/zones/${file}"))
  }

  zones = {
    for _, config in local.zone_configs : config.zone => config
    if try(config.manage_zone, true)
  }

  record_entries = flatten([
    for config in values(local.zone_configs) : [
      for id, record in try(config.records, {}) : {
        key   = "${config.zone}/${id}"
        value = merge(record, { zone = config.zone })
      }
    ]
  ])
  records = {
    for record in local.record_entries : record.key => record.value
  }
}

resource "technitium_zone" "zones" {
  for_each = local.zones

  name = each.value.zone
  type = each.value.type

  dynamic "dnssec" {
    for_each = each.value.type == "Primary" || try(each.value.dnssec, null) != null ? [1] : []

    content {
      enabled   = try(each.value.dnssec.enabled, true)
      algorithm = try(each.value.dnssec.algorithm, "ECDSA")
      curve     = try(each.value.dnssec.curve, "P256")
      nx_proof  = try(each.value.dnssec.nx_proof, "NSEC")
    }
  }
}

resource "technitium_record" "records" {
  for_each = local.records

  zone      = each.value.zone
  name      = each.value.name
  type      = each.value.type
  value     = each.value.value
  ttl       = try(each.value.ttl, null)
  priority  = try(each.value.priority, null)
  weight    = try(each.value.weight, null)
  port      = try(each.value.port, null)
  caa_flags = try(each.value.caa_flags, null)
  caa_tag   = try(each.value.caa_tag, null)
  overwrite = false

  depends_on = [technitium_zone.zones]
}