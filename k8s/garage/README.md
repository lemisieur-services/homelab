# Garage

The Argo CD Application renders the official Garage 0.10.7 Helm chart
(Garage v2.6.0) from its pinned Git revision and applies the local manifests
for its ExternalSecrets and Traefik route. It runs one Garage node with
automatic single-node layout and replication factor 1. Its metadata and data
use separate 1 GiB and 20 GiB `local-ssd` PVCs. Longhorn maintains two replicas
of each volume; this is not the same as Garage-level replication or a backup,
and the 21 GiB of PVCs can
consume roughly 42 GiB across Longhorn replicas. Adjust the sizes before
deployment to suit the available SSD capacity.

## Prerequisites and deployment

1. In the 1Password `lab-k8s` vault, create an item named `garage-rpc` with
   a `password` field containing a new 32-byte random secret encoded as 64
   hexadecimal characters. Generate it privately with `openssl rand -hex 32`;
   do not commit or share the value. The existing `onepassword-labk8s`
   ClusterSecretStore and External Secrets operator must be working. No sealed
   secret is needed. The store must also have access to the existing
   `sslcert-lab_lemisieur_com` item with `tls.crt` and `tls.key` fields for
   the TLS certificate.
2. Ensure `local-ssd` and Longhorn are healthy and an amd64 Kubernetes node
   can run the pod. Point `s3.lab.lemisieur.com` DNS to Traefik and ensure
   the certificate covers that name. Merge these files to `main` and wait for
   the `argocd-config` Application to create the Garage AppProject. If
   Applications under `k8s/argocd/apps` are not automatically registered,
   apply the Application once with `kubectl apply -f k8s/argocd/apps/garage.yaml`.
3. Check `kubectl -n garage get externalsecret,ingressroute,pvc,pods` and
   `kubectl -n garage exec garage-0 -- /garage status`. The pod cannot start
   until External Secrets has created `garage-rpc`.

The S3 endpoint is `https://s3.lab.lemisieur.com`, region `garage`; use
path-style S3 addressing. It is also available inside the cluster at
`http://garage.garage.svc.cluster.local:3900`. Traefik forwards the host header
without an authentication middleware so S3 signature authentication works.
No website ingress or admin API Service is enabled.
Create a bucket and a scoped S3 access key with the Garage CLI, and store the
resulting credentials in 1Password for consumers; these are distinct from the
RPC secret. See the [Garage quick start](https://garagehq.deuxfleurs.fr/documentation/quick-start/)
for bucket creation and key permissions. Do not send credentials to Git or
logs.

The AppProject permits only the Garage namespace, its two Git sources, the
namespaced resource kinds used by the chart and manifests, and namespace
creation.
Kubernetes discovery is disabled in this single-node configuration, so the
Garage CRD and cluster-wide RBAC are not required or allowed.

The RPC secret is copied into the runtime configuration by the chart's init
container. After changing it in 1Password, wait for the ExternalSecret to
refresh and restart the StatefulSet pod to load it. The single-node mode is
for a fresh deployment; migrating to a multi-node Garage layout requires a
deliberate configuration and data migration plan.

Back up both PVCs consistently, quiescing Garage as appropriate. The
StatefulSet retains its PVCs by default, but deleting the namespace deletes
the claims; `local-ssd` uses Longhorn's `Retain` reclaim policy. Volume
expansion requires more than editing the chart values: follow the upstream
[PVC expansion procedure](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/#increase-pvc-size-on-running-garage-instances)
and update the Garage layout capacity as appropriate.
