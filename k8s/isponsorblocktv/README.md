# iSponsorBlockTV

iSponsorBlockTV runs as a single replica in the `isponsorblocktv` namespace,
managed by the dedicated `isponsorblocktv` Argo CD Application. Configuration
and device pairing state live on the `isponsorblocktv-data` PVC, mounted at
`/app/data`; no pairing credentials or API keys are stored in Git.

## Deployment

- Image: `ghcr.io/dmunozv04/isponsorblocktv:v2.11.0`, pinned by immutable
  multi-platform digest. This is the latest upstream release, and its registry
  digest matched `latest` when checked on 2026-11-02
  ([release](https://github.com/dmunozv04/iSponsorBlockTV/releases/tag/v2.11.0)).
- Storage: 1 GiB, `ReadWriteOnce`, using the existing Longhorn-backed `local-ssd`
  StorageClass. The `Recreate` strategy avoids overlapping worker replicas during
  updates.
- Scheduling: the same `proxy` node selector and toleration used by other
  homelab application workloads.
- Networking: no Service, Ingress, exposed ports, or host networking. Manual TV
  code pairing does not require LAN discovery; the application needs outbound
  access to YouTube and the SponsorBlock API
  ([upstream usage](https://github.com/dmunozv04/iSponsorBlockTV#usage)).
- Safety: the PVC has Argo CD `Prune=false,Delete=false` so automatic pruning or
  Application deletion does not remove pairing data. Intentional storage
  deletion requires manually deleting the PVC; the existing StorageClass also
  has a `Retain` reclaim policy.

Merge these manifests to `main` before syncing. If your existing application
bootstrap does not discover new files under `k8s/argocd/apps`, register this app
once from the repository checkout:

```sh
kubectl apply -f k8s/argocd/apps/isponsorblocktv.yaml
```

The Application creates the namespace and automatically syncs its Deployment
and PVC. Wait for the PVC to bind and the pod to enter `Running`:

```sh
kubectl -n isponsorblocktv get pvc,pods
```

## Initial TV pairing

The upstream setup wizard must pair at least one device before the worker can
start. On a fresh volume the container stays running but intentionally not
Ready, allowing setup without a crash loop; Argo CD will remain Progressing
until pairing is complete.

Open YouTube on the target TV and go to **Settings > Link with TV code**.
Run the upstream CLI setup interactively in the existing pod, choose to add a
device, and enter the TV code when prompted:

```sh
kubectl -n isponsorblocktv exec -it deployment/isponsorblocktv \
  -c isponsorblocktv -- \
  python3 -u /app/main.pyc --data /app/data --setup-cli
```

Complete all prompts so the wizard saves `/app/data/config.json`. The waiting
worker starts automatically within about 10 seconds of a configuration with a
paired device being saved; readiness checks only verify configuration, not
connectivity to the TV or upstream APIs
([upstream installation and setup](https://github.com/dmunozv04/iSponsorBlockTV/wiki/Installation)).

Verify rollout and device connections:

```sh
kubectl -n isponsorblocktv rollout status deployment/isponsorblocktv --timeout=120s
kubectl -n isponsorblocktv logs deployment/isponsorblocktv -c isponsorblocktv --tail=100
```

For later device additions or configuration changes, run the same wizard,
then restart the worker to load the updated configuration:

```sh
kubectl -n isponsorblocktv rollout restart deployment/isponsorblocktv
kubectl -n isponsorblocktv rollout status deployment/isponsorblocktv --timeout=120s
```

Back up the PVC through your normal Longhorn backup process. Do not commit
`config.json`, paste TV codes into issues, or enable debug logging when sharing
logs, because device identifiers and authentication data may be sensitive.
