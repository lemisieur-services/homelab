# Garage

The Argo CD Application renders the datahub-local Garage chart 1.0.0, pinned
to its Git revision. The Garage image remains at v2.6.0; the chart's default
v2.5.0 would be a downgrade. One node uses separate 1 GiB metadata and 20 GiB
data `local-ssd` PVCs. Longhorn maintains two replicas of each volume; this
is not Garage-level replication or a backup.

## Prerequisites and cutover

Before merging, rename the existing `garage-rpc` 1Password item to
`garage-secrets` in the `lab-k8s` vault and prepare these fields:

- `rpc-token`: Keep the existing RPC secret. For a fresh installation,
  generate its 64 hexadecimal characters privately with `openssl rand -hex 32`.
- `admin-token`: A new random admin API token, for example generated privately
  with `openssl rand -hex 32`.
- `webui-auth`: The complete `username:bcrypt-hash` output from
  `htpasswd -nBC 10 USERNAME` (which prompts for the password). Generate it
  privately; do not commit credentials.

The `onepassword-labk8s` ClusterSecretStore and External Secrets operator must
be working. The store also needs the existing `sslcert-lab_lemisieur_com`
item. Point `s3.lab.lemisieur.com` and `garage.lab.lemisieur.com` to Traefik;
the certificate must cover both names.

The previous chart and this chart use different immutable StatefulSet
selectors. For an existing installation, the first sync cannot update the
StatefulSet in place. After merging and letting Argo CD update the AppProject,
delete **only the StatefulSet** with
`kubectl -n garage delete statefulset garage --cascade=foreground`, then sync
the Garage Application. Expect S3 downtime during replacement. Do not delete
the PVCs: the new StatefulSet reuses `meta-garage-0` and `data-garage-0`.
If the application is being installed fresh, no deletion is needed.

Check `kubectl -n garage get externalsecret,ingressroute,pvc,pods,job` and
`kubectl -n garage exec garage-0 -- /garage status`. The chart's configuration
job assigns the single-node layout with 18G capacity; inspect its logs if
layout or bucket creation fails. Garage and the job require the RPC and admin
secrets; the UI also requires its authentication secret.

## Access and declarative configuration

The S3 endpoint is `https://s3.lab.lemisieur.com`, region `garage`, using
path-style addressing. Inside the cluster it is
`http://garage.garage.svc.cluster.local:3900`. Traefik forwards the host header
without authentication middleware so S3 signatures work. The authenticated UI
is at `https://garage.lab.lemisieur.com`; the admin API is not exposed by
Traefik.

Define buckets under `clusterConfig.buckets` in
`k8s/argocd/apps/garage.yaml`. No bucket names are configured initially:

```yaml
clusterConfig:
  enabled: true
  buckets:
    - name: example
  keys:
    example-client:
      secretName: example-s3-credentials
      keyId: keyId
      secretKey: secretKey
      buckets:
        - name: example
          read: true
          write: true
```

Supply key credentials via a Kubernetes Secret, preferably sourced from
1Password with an ExternalSecret. Garage key IDs must be `GK` followed by
24 hexadecimal characters, and secret keys must be 64 hexadecimal characters.
Do not put credentials in Git. For lifecycle management, explicitly grant
`owner: true` to the appropriate key. See the
[chart documentation](https://github.com/datahub-local/garage-helm/tree/garage-1.0.0/garage)
for further options.

The chart's job creates buckets, imports keys and grants permissions on sync;
it does not remove buckets, keys or permissions when they are removed from
values. Its script suppresses errors for several of these operations, so
verify the resulting state using the UI or Garage CLI rather than relying
solely on job success.

The chart unconditionally creates a ClusterRole and ClusterRoleBinding granting
its service account permissions on CRDs and GarageNode resources, although
this single-node configuration does not enable Kubernetes discovery. The
AppProject must allow those cluster-scoped resources as well as the chart's
namespaced resources. Restrict access to the namespace and service account
accordingly.

ExternalSecret updates do not restart pods automatically. After rotating the
RPC secret, admin token or UI credentials, wait for the secret to refresh and
restart both the Garage StatefulSet and WebUI Deployment.
