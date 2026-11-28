# Technitium DNS

This Terraform configuration manages DNS zones and records on
`https://<my-technitium-server>` using the
[Technitium provider](https://registry.terraform.io/providers/bartei/technitium/1.0.1/docs).
Zone and record definitions are loaded from YAML files in [`zones/`](zones/).
See the [zone documentation](zones/README.md) for the YAML format and import
examples.

## Configure access

Create an API token in Technitium under **Administration > API Tokens**. Supply
the token and server URL through environment variables or a secret manager:

```sh
export TF_VAR_technitium_api_token='<token>'
export TF_VAR_technitium_server_url='https://<my-technitium-server>'
```

Do not commit the token. If the server uses a private CA, set `TECHNITIUM_CACERT`
to the CA certificate's path.

## State backend

The state backend uses Garage's S3 endpoint and the `garage` region. Provide a
Garage key with access to the `terraform-states` bucket through
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` or an AWS credentials profile.
The key needs read and write access to the state and its `.tflock` object,
including permission to delete the lock. Do not commit credentials. Protect and
back up the state because it can contain sensitive data.

After changing an already initialized backend configuration, run
`tofu init -reconfigure`. To move existing state to Garage instead, use
`tofu init -migrate-state` and verify the migration. Locking depends on Garage
correctly enforcing conditional writes; test concurrent locking before relying
on it.

## Plan and apply

From the repository root, initialize Terraform and review the plan before
applying:

```sh
cd terraform/dns
tofu init
tofu plan
tofu apply
```

Existing DNS entries are not discovered automatically. Add matching zone and
record definitions, then import existing entries before applying; see
[Importing existing entries](zones/README.md#importing-existing-entries).
Always review the plan, especially after importing, since configuration
differences can update existing entries. Removing a managed zone can delete the
zone and its records, including records not managed by Terraform.

## GitHub Actions

The [shared OpenTofu workflow](../README.md#github-actions) loads the DNS
provider settings from [`1password.env`](1password.env). Create the
`technitium-dns` item in the `lab-gha` vault with `server-url` and `api-token`
fields.
