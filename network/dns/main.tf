data unifi_dns_record "dns_record" {
  name    = "lab.lemisieur.com"
}
output "dns_test" {
  value = data.unifi_dns_record.dns_record
}