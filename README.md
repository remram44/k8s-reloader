Kubernetes reloader
===================

This is a simple container you can run on your cluster as a CronJob. It will automatically restart any number of Deployments/StatefulSets/... when a ConfigMap/Secret/... changes.

This can be used for example to restart a deployment when a certificate is updated.

Usage
-----

The container expects two environment variables to be set:

### `INPUTS`

This is the object(s) to watch for changes. The format is `<namespace> <kind> <name>`, where `<kind>` is either `configmap` or `secret`.

For example `kube-system secret my-tls-cert` will watch the Secret with name `my-tls-cert` in the namespace `kube-system`.

You can pass multiple objects in the same format, for example `ns1 secret name1 ns2 secret name2 ns3 configmap name3`.

### `TARGETS`

This is the object(s) to restart in case of changes. The format is `<namespace> <kind> <name>`, where `<kind>` is one of `deployment`, `replicaset`, or `statefulset`.

For example `kube-system deployment my-server` will restart the Deployment with name `my-server` in the namespace `kube-system`.

You can pass multiple objects in the same format, for example `ns1 deployment name1 ns2 deployment name2`.

### Manifest

A full sample manifest defining a CronJob is included in this repo: [`k8s.sample.yaml`](k8s.sample.yaml). It includes sample RBAC rules that allow the container to read its inputs and patch its targets.
