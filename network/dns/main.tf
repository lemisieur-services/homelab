locals {
  dns_records = jsondecode(file("${path.module}/records.json"))
}
resource "unifi_dns_record" "a" {
  for_each = { for record in local.dns_records.A : record.name => record }

  name        = each.value.name
  record_type = "A"
  value       = each.value.value
  enabled     = true
  port        = 0
  priority    = 0
  ttl         = 0
}