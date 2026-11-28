# Zone and record YAML

The Terraform configuration loads every `*.yaml` file in this directory. Use
one file per zone. Each file defines a zone and, optionally, a map of records:

```yaml
zone: example.com
type: Primary
records:
  web:
    name: www.example.com
    type: A
    value: 192.168.1.100
    ttl: 3600
  alias:
    name: alias.example.com
    type: CNAME
    value: www.example.com
```

`zone` and `type` define the zone. `records` is optional; omit it or use
`records: {}` when a zone has no records. Each record requires a fully qualified
`name`, `type`, and `value`. Optional record fields are `ttl`, `priority`,
`weight`, `port`, `caa_flags`, and `caa_tag`. Supported record types are A,
AAAA, CNAME, MX, TXT, SRV, PTR, NS, and CAA. See the provider's
[zone documentation](https://registry.terraform.io/providers/bartei/technitium/1.0.1/docs/resources/zone)
and [record documentation](https://registry.terraform.io/providers/bartei/technitium/1.0.1/docs/resources/record)
for accepted values and type-specific fields.

The record map key (such as `web` or `alias`) is a stable Terraform identifier
unique within its zone. The zone and identifier together form the record's
Terraform resource key. Changing either can make Terraform treat the record as
a different resource. Records use `overwrite = false` to avoid replacing other
records at the same name and type.

By default, the zone itself is managed. Set `manage_zone: false` to manage
records in a zone that already exists without managing the zone resource.

## DNSSEC

Managed primary zones default to DNSSEC enabled with ECDSA, P256, and NSEC.
Override individual settings in the zone YAML if needed:

```yaml
dnssec:
  enabled: false
```

Disabling DNSSEC on a managed, signed primary zone causes the provider to unsign
it on update. An unsigned primary zone will be signed by default. Match imported
settings and review the plan before applying. Non-primary zones do not receive a
DNSSEC block by default.

## Importing existing entries

Existing DNS entries must be imported explicitly; Terraform does not discover
them automatically. Add the matching zone and record definitions to YAML, then
import them before applying. For the example above:

```sh
tofu import 'technitium_zone.zones["example.com"]' 'example.com'
tofu import 'technitium_record.records["example.com/web"]' 'example.com::www.example.com::A::192.168.1.100'
tofu plan
```

The record resource key uses `<zone>/<record-map-key>`. See the provider's
[record import formats](https://registry.terraform.io/providers/bartei/technitium/1.0.1/docs/resources/record#import)
for MX, SRV, and CAA records. Review the plan before applying; imported
configuration differences can update existing entries.

For backend setup and the general plan/apply workflow, see the
[Terraform DNS README](../README.md).
