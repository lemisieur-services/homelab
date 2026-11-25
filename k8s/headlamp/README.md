# Headlamp

The Argo CD Application deploys the official Headlamp Helm chart at
`https://headlamp.k8s.lab.lemisieur.com`. A 5Gi `local-ssd` PVC persists
plugins, not Kubernetes cluster data or browser sessions.

## Prerequisites

1. Create a Pocket ID client with the redirect URI
   `https://headlamp.k8s.lab.lemisieur.com/oidc-callback`. The issuer is
   `https://fed.lab.lemisieur.com`.
2. The `onepassword-labk8s` ClusterSecretStore must have access to
   `headlamp-oauth` for the OIDC client credentials and `sslcert-rootca`
   with its `root.crt` attachment for trust in the issuer. ExternalSecrets
   create the corresponding Secrets in the `headlamp` namespace.
3. Configure the Kubernetes API server to trust the issuer and accept the
   client ID as an OIDC audience, then grant appropriate Kubernetes RBAC
   permissions to the authenticated user or group. API-server configuration
   and RBAC are managed separately; OIDC login alone does not grant cluster
   access. The chart's default cluster-admin binding is disabled.
4. Ensure DNS resolves the hostname to Traefik and the
   `k8s-lab-lemisieur-com` certificate covers it. Apply
   `k8s/argocd/apps/headlamp.yaml` to Argo CD if Applications in that directory
   are not already registered automatically. The `argocd-config` Application
   manages the required `headlamp` AppProject from `k8s/argocd/projects`.

Check the Application, secrets, PVC, pod, HTTPS and login using an authorized
identity. Restart the Headlamp pod after OIDC credential or CA changes:
credentials and the Go system certificate pool are loaded at startup.

The chart uses the default rolling deployment strategy and does not expose a
strategy override. A rollout can stall if Longhorn cannot attach the
`ReadWriteOnce` volume to the new pod while the old pod is running on another
node. If that occurs, remove the old Headlamp pod to allow the volume to detach
and the replacement to start; this briefly interrupts service. The storage
class uses the `Retain` reclaim policy, so deleting the PVC may leave its
volume behind.
