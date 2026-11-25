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
   client ID as an OIDC audience. Configure it to read the `groups` claim with
   the `oidc:` group prefix (for example, `--oidc-groups-claim=groups` and
   `--oidc-groups-prefix=oidc:`), and ensure Pocket ID includes the `headlamp`
   group name (not just its display name) in the token. Headlamp requests the
   `groups` scope for this.
   API-server configuration is managed separately; see
   `talos/patches/headlamp-oidc.yaml.example` and the instructions below.
   The application's ClusterRoleBinding grants `cluster-admin` to
   `oidc:headlamp`, giving its members unrestricted access to the cluster,
   including Secrets. The chart's default cluster-admin binding is disabled.
4. Ensure DNS resolves the hostname to Traefik and the
   `k8s-lab-lemisieur-com` certificate covers it. Apply
   `k8s/argocd/apps/headlamp.yaml` to Argo CD if Applications in that directory
   are not already registered automatically. The `argocd-config` Application
   manages the required `headlamp` AppProject from `k8s/argocd/projects`.

Check the Application, secrets, PVC, pod, HTTPS and login using an authorized
identity. Restart the Headlamp pod after OIDC credential or CA changes:
credentials and the Go system certificate pool are loaded at startup.

## Talos API server OIDC

The Talos patch is not applied by Argo CD. On a machine with authorized
`talosctl` access, copy `talos/patches/headlamp-oidc.yaml.example` outside the
repository and replace both placeholders. Use the Headlamp client ID from
`headlamp-oauth` and the PEM root CA that validates the Pocket ID issuer's
certificate chain (the `root.crt` attachment in `sslcert-rootca` if it is that
CA). Never include the client secret or a private key in the patch.
Validate the CA with `openssl x509 -in root.crt -noout` and check that
`https://fed.lab.lemisieur.com/.well-known/openid-configuration` is reachable
and trusted from the control-plane network.

Before applying, back up each node's Talos machine configuration securely;
it contains sensitive credentials. Check the existing API-server
authentication settings and extra volumes, and review the merged configuration
for conflicts. In particular, do not mix OIDC flags with an existing
`authentication-config`, and avoid appending duplicate entries when reapplying
or rotating the CA. Keep administrative access available.

Apply the completed patch to each control-plane node, one at a time:

```sh
talosctl -n <control-plane-ip> patch machineconfig --patch @headlamp-oidc.yaml
```

Wait for the API server to become healthy before proceeding to the next node.
After Argo CD syncs the binding, sign in through Headlamp. To verify the
mapping separately, use an OIDC-authenticated kubectl context and run
`kubectl auth whoami`; its groups should include `oidc:headlamp`.

The chart uses the default rolling deployment strategy and does not expose a
strategy override. A rollout can stall if Longhorn cannot attach the
`ReadWriteOnce` volume to the new pod while the old pod is running on another
node. If that occurs, remove the old Headlamp pod to allow the volume to detach
and the replacement to start; this briefly interrupts service. The storage
class uses the `Retain` reclaim policy, so deleting the PVC may leave its
volume behind.
