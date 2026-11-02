# 1Password Connect

ArgoCD deploys the Connect API and sync containers, a ClusterIP Service on port
8080, and a namespaced SecretStore for the `lab-01` vault. There is no Ingress
or external Service exposure.

## Existing Secrets

Following the [External Secrets 1Password guide](https://external-secrets.io/latest/provider/1password-automation/),
these Secrets must already exist in the `onepassword-connect` namespace:

| Secret | Key | Value |
| --- | --- | --- |
| `connect-server-credentials` | `1password-credentials.json` | Base64-encoded contents of the credentials JSON |
| `onepassword-connect-token` | `token` | Connect access token with access to `lab-01` |

Both containers read `OP_SESSION` from the credentials Secret. Its decoded
Kubernetes Secret value must itself be base64-encoded JSON, as required by the
guide's environment-variable approach. The access token is a separate client
credential used by the SecretStore, not a replacement for the server credentials.
Neither Secret is created or managed by this application.

## Usage

ExternalSecrets in this namespace can reference `kind: SecretStore`,
`name: onepassword-connect`. Other in-cluster clients can reach
`http://onepassword-connect.onepassword-connect.svc.cluster.local:8080`.

The API and sync containers share an ephemeral cache and use health probes.
The existing Reloader restarts them when credentials change. HTTP assumes a
trusted cluster network; the [guide recommends encrypted connections](https://external-secrets.io/latest/provider/1password-automation/#deploy-a-connect-server).
