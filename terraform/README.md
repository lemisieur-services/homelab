# OpenTofu configurations

Each direct subdirectory of `terraform/` is an independent OpenTofu root. The
[GitHub Actions workflow](../.github/workflows/terraform.yaml) plans each root
changed by a PR against `main`, including changes in nested directories. It
saves the test-merge plans to S3 and applies the matching plans after merge,
only when the merged tree matches and the merge commit is still the tip of
`main`. Review each root's Actions plan log before merging. A rerun for the
same PR head and tree replaces that root's stored plan; review the latest
successful plan.

## Adding a root

1. Add the configuration under `terraform/<root>/`, with a name beginning with
   a letter or digit and containing only letters, digits, dots, underscores or
   hyphens.
2. Configure an S3 backend using the shared `terraform-states` bucket, with a
   **unique state key** for that root. The existing DNS key remains
   `dns/dns-01.tfstate`. Enable locking and ensure the key has read and write
   permissions for state and its `.tflock`, including lock deletion. Do not
   change an existing state key without migrating the state.
3. Generate and commit the root's `.terraform.lock.hcl`; CI uses it in
   read-only mode. The same OpenTofu version, currently 1.13.10, is used for
   all roots and both plan and apply.
4. Add `1password.env` in that folder, even if it is empty. Put only
   1Password secret references there, using the environment variable names
   expected by the provider or by OpenTofu, for example:

   ```dotenv
   TF_VAR_api_token=op://lab-gha/example/api-token
   ```

   The workflow loads these references alongside its shared credentials.
   Never commit secret values. See [`dns/1password.env`](dns/1password.env)
   for the DNS configuration.

All changed roots must still exist and contain configuration. Removing a root
fails discovery instead of silently abandoning its resources. Destroy or
migrate its resources with a reviewed plan first; removing the folder then
requires a separate, manually approved process because this workflow rejects
root deletions.

## GitHub Actions

The `terraform` GitHub environment's `OP_TOKEN` secret must be a 1Password
service account token with read access to the relevant vault items. The
shared `terraform` item in `lab-gha` must contain:

| Field | Value |
| --- | --- |
| `endpoint` | S3 endpoint shared by the state and plan buckets |
| `region` | S3 region (`garage` for Garage) |
| `key-id` | Shared S3 access key ID |
| `secret-key` | Shared S3 secret access key |
| `plan-bucket` | Private bucket used to store plans |

The `sslcert-rootca` Document in `lab-gha` must contain the PEM-encoded
`root.crt` file for the internal lab. After checkout, each job runs the
[lab CA action](../.github/actions/lab-ca/action.yml), which loads the
certificate and adds it to the runner's public CA bundle in temporary storage.
The action sets trust environment variables for OpenTofu, AWS CLI, Git,
curl, Python requests and Node.js. The service account needs read access to
that Document. The runner must already be able to reach GitHub and 1Password
before this bootstrap; tools with their own trust stores may need additional
configuration.

Create a separate private bucket for plans. The shared key needs `PutObject`
and `GetObject` for that bucket as well as the state permissions above. The
S3 endpoint must support path-style access. Restrict plan bucket access and
configure expiration: binary plans include configuration and state, which may
contain secrets. Actions logs can also contain sensitive infrastructure details.

The ephemeral `gh-arc-runners` runner must reach the S3 endpoint, each
provider's endpoint, 1Password, GitHub, and the OpenTofu provider registry.
The workflow installs OpenTofu and uses the
[AWS CLI action](../.github/actions/install-aws-cli/action.yml) for each job.
Both use temporary files; the workflow does not depend on runner storage
surviving a job.

Only same-repository PRs run the jobs; fork PRs are skipped. Same-repository
contributors who can change workflow or OpenTofu code must be trusted with the
runner's network access and the environment's secrets. Protect `main` and
require plan review before merging. Direct pushes do not trigger an apply.
If the base branch changes, update the PR and review its new plans.

If a plan is missing, `main` has advanced, or state has changed since
planning, apply fails rather than creating a new plan. Reconcile the affected
root's current `main` configuration with a freshly reviewed plan. GitHub's PR
file API is limited to 3,000 files; discovery fails at that limit instead of
potentially skipping changed roots.
