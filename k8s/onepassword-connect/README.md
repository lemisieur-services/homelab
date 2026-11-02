# 1Password Connect

This ArgoCD application runs one 1Password Connect instance in the
`onepassword-connect` namespace on the homelab's proxy nodes. The API and sync
containers share an `emptyDir` volume for their encrypted cache, following
[1Password's two-container architecture](https://developer.1password.com/docs/connect/server-configuration/).

## Bootstrap credentials

Create a Connect server and download its `1password-credentials.json` file using
the [1Password setup instructions](https://developer.1password.com/docs/connect/get-started/).
Upload the raw JSON file contents as an Azure Key Vault secret named
`onepassword-connect-credentials` in the existing `lemisieur-k8s-secrets` vault.
Do not base64-encode the JSON or commit credentials or access tokens to Git.

The existing External Secrets Operator and `lemisieur-k8s-secrets`
ClusterSecretStore must be healthy and authorized to read that secret. The
`ExternalSecret` creates a Kubernetes Secret named
`onepassword-connect-credentials`, with a `1password-credentials.json` key
mounted read-only into both containers. The Deployment will wait for this Secret
to exist; it does not bootstrap credentials from Connect itself.

The ArgoCD Application at `k8s/argocd/apps/onepassword-connect.yaml` follows the
repository's automated sync policy and creates the namespace. If application
discovery is not already configured for that directory, register it explicitly:

```sh
kubectl apply -f k8s/argocd/apps/onepassword-connect.yaml
```

## Service-only access

Set clients' `OP_CONNECT_HOST` to
`http://onepassword-connect.onepassword-connect.svc.cluster.local:8080`.
Provide a scoped Connect access token to each client separately as
`OP_CONNECT_TOKEN`, as described in the
[1Password setup instructions](https://developer.1password.com/docs/connect/get-started/).

The only Service is a `ClusterIP` exposing API port 8080. There is no Ingress,
IngressRoute, Gateway route, NodePort, LoadBalancer, host port, or host networking;
the sync health port and container bus ports are not exposed by the Service.
ClusterIP is not a network access-control policy: use this HTTP endpoint only on
a trusted cluster network, consistent with
[1Password's TLS guidance](https://developer.1password.com/docs/connect/server-configuration/#tls).

## Operations

Both containers have readiness and liveness probes. They run as non-root with
read-only root filesystems and no Kubernetes API token; the shared cache remains
writable. The existing Reloader installation restarts the Deployment when its
credentials Secret changes.

The cache is ephemeral and is repopulated from 1Password after Pod replacement.
Allow outbound connectivity to 1Password for initial synchronization and updates;
there is no PVC or Kubernetes Operator in this deployment.

After ArgoCD syncs, check credentials and rollout:

```sh
kubectl -n onepassword-connect wait \
  --for=condition=Ready externalsecret/onepassword-connect-credentials --timeout=120s
kubectl -n onepassword-connect rollout status deployment/onepassword-connect
kubectl -n onepassword-connect get service onepassword-connect
```
