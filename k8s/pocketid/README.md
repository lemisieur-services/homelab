# Pocket ID

Pocket ID uses the Anza Labs chart with the existing `pocket-id-data` PVC.
The chart mounts it at `/app/data`, which contains the SQLite database and
uploaded files. The PVC is managed separately from the chart.

The Argo CD application ignores differences in the StatefulSet's immutable
`serviceName` so an existing StatefulSet from the old chart can be updated
without replacing it. A newly created StatefulSet uses the new chart's
`pocket-id` service.
