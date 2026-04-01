
# Must Gather Chart for Red Hat Developer Hub (RHDH)

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart for deploying the RHDH Must-Gather diagnostic tool on Kubernetes

**Homepage:** <https://github.com/redhat-developer/rhdh-must-gather>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat |  | <https://redhat.com> |

## Source Code

* <https://github.com/redhat-developer/rhdh-must-gather>

## Requirements

Kubernetes: `>= 1.27.0-0`

## TL;DR

```console
helm upgrade --install my-rhdh-must-gather rhdh-must-gather \
  --repo https://redhat-developer.github.io/rhdh-chart \
  --version 0.3.0
```

Running the command again will automatically replace the previous pod and start a new gather.

Then follow the instructions that will be printed to retrieve the gathered data.

## Running on OpenShift

This chart works on both Kubernetes and OpenShift.

But for OpenShift, we recommend using the `oc adm must-gather` command, like so:

```sh
oc adm must-gather --image=quay.io/rhdh-community/rhdh-must-gather
```

See the [must-gather tool README](https://github.com/redhat-developer/rhdh-must-gather#for-openshift-clusters) for more details.

## Testing a Release

Once a Helm Release has been deployed, you can test it using the [`helm test`](https://helm.sh/docs/helm/helm_test/) command:

```sh
helm test <release_name>
```

This will run a simple Pod in the cluster to check that the required resources have been created.

You can control whether to disable this test pod or you can also customize the image it leverages.
See the `test.enabled` and `test.image` parameters in the [`values.yaml`](./values.yaml) file.

> **Tip**: Disabling the test pod will not prevent the `helm test` command from passing later on. It will simply report that no test suite is available.

Below are a few examples:

<details>

<summary>Disabling the test pod</summary>

```sh
helm install <release_name> <repo> \
  --set test.enabled=false
```

</details>

<details>

<summary>Customizing the test pod image</summary>

```sh
helm install <release_name> <repo> \
  --set test.image.registry=docker.io \
  --set test.image.repository=bitnami/kubectl \
  --set test.image.tag=1.30.0
```

</details>

## Uninstalling the Chart

To uninstall/delete a Helm release named `my-rhdh-must-gather`:

```console
helm uninstall my-rhdh-must-gather
```

The command removes all the Kubernetes resources associated with the chart and deletes the release.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| affinity | Affinity rules for pod scheduling | object | `{}` |
| dataHolder | Runs alongside the gather container and stays alive so you can exec in and retrieve the output. | object | `{"resources":{"limits":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"},"requests":{"cpu":"50m","ephemeral-storage":"32Mi","memory":"64Mi"}}}` |
| dataHolder.resources | Resource requests and limits for the data-holder container | object | `{"limits":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"},"requests":{"cpu":"50m","ephemeral-storage":"32Mi","memory":"64Mi"}}` |
| fullnameOverride |  | string | `""` |
| gather | Gather script configuration | object | `{"clusterInfo":false,"cmdTimeout":"30","extraArgs":[],"extraEnvVars":[],"heapDump":{"bufferSize":"","enabled":false,"instances":"","method":"","remoteDir":"","timeout":""},"logLevel":"info","namespaces":[],"since":"","sinceTime":"","withHelm":true,"withIngress":true,"withNamespaceInspect":true,"withOperator":true,"withOrchestrator":true,"withPlatform":true,"withRoute":true,"withSecrets":false}` |
| gather.cmdTimeout | Command timeout for individual kubectl/helm commands (seconds) | string | `"30"` |
| gather.extraArgs | Additional custom arguments to pass to the gather script | list | `[]` |
| gather.extraEnvVars | Additional environment variables to pass to the gather init container.<br/> See [Define Environment variables for a container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/#define-an-environment-variable-for-a-container). | list | `[]` |
| gather.heapDump | Heap dump collection configuration | object | `{"bufferSize":"","enabled":false,"instances":"","method":"","remoteDir":"","timeout":""}` |
| gather.heapDump.bufferSize | WebSocket buffer size in bytes for inspector method | string | `""` |
| gather.heapDump.enabled | Enable collection of heap dumps (disabled by default) | bool | `false` |
| gather.heapDump.instances | Filter for specific heap dump instances (comma-separated pod names or patterns) | string | `""` |
| gather.heapDump.method | Method for heap dump collection: "inspector" or "sigusr2" | string | `""` |
| gather.heapDump.remoteDir | Directory in container where heap dumps are written for SIGUSR2 method. Must be writable inside the gather container. | string | `""` |
| gather.heapDump.timeout | Timeout in seconds for heap dump collection | string | `""` |
| gather.logLevel | Log level: info, INFO, debug, DEBUG, trace, TRACE | string | `"info"` |
| gather.namespaces | Example: ["rhdh-prod", "rhdh-staging"] | list | `[]` |
| gather.since | Relative time for log collection (e.g., "2h", "30m") | string | `""` |
| gather.sinceTime | Absolute timestamp for log collection (RFC3339 format) | string | `""` |
| gather.withOperator | Collection features (enabled by default; set to false to skip) | bool | `true` |
| gather.withSecrets | Optional collection features (disabled by default) | bool | `false` |
| image | Container image configuration | object | `{"digest":"","pullPolicy":"","registry":"quay.io","repository":"rhdh-community/rhdh-must-gather","tag":"latest"}` |
| image.digest | Image digest (e.g., sha256:abc123...). Can be used with or without tag. | string | `""` |
| image.tag | Overrides the image tag whose default is the chart appVersion. | string | `"latest"` |
| imagePullSecrets | Secrets for pulling images from a private registry | list | `[]` |
| nameOverride | Override the chart name | string | `""` |
| nodeSelector | Node selector for pod scheduling | object | `{}` |
| persistence | Persistent volume configuration for storing gathered data | object | `{"accessMode":"ReadWriteOnce","size":"1Gi","storageClass":""}` |
| persistence.accessMode | Access mode | string | `"ReadWriteOnce"` |
| persistence.size | Storage size | string | `"1Gi"` |
| persistence.storageClass | Storage class (empty = use cluster default) | string | `""` |
| podAnnotations | Pod annotations | object | `{}` |
| podLabels | Pod labels | object | `{}` |
| podSecurityContext | Pod security context | object | `{"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` |
| rbac | RBAC configuration | object | `{"create":true,"rules":{"backstages":true,"ingresses":true,"knative":true,"olm":true,"platform":true,"routes":true,"sonataflow":true},"scope":"cluster"}` |
| rbac.create | Create RBAC resources (Role/ClusterRole and bindings) | bool | `true` |
| rbac.rules | a rule here does not require disabling the corresponding gather.with* flag. | object | `{"backstages":true,"ingresses":true,"knative":true,"olm":true,"platform":true,"routes":true,"sonataflow":true}` |
| rbac.rules.backstages | rhdh.redhat.com — Backstage custom resources | bool | `true` |
| rbac.rules.ingresses | networking.k8s.io — Ingresses, NetworkPolicies | bool | `true` |
| rbac.rules.knative | operator.knative.dev, operator.serverless.openshift.io — Knative/Serverless | bool | `true` |
| rbac.rules.olm | operators.coreos.com — OLM resources (subscriptions, CSVs, etc.) | bool | `true` |
| rbac.rules.platform | config.openshift.io — ClusterVersions, Infrastructures (cluster scope only) | bool | `true` |
| rbac.rules.routes | route.openshift.io — OpenShift Routes | bool | `true` |
| rbac.rules.sonataflow | sonataflow.org — SonataFlow custom resources | bool | `true` |
| resources | Resource requests and limits for the gather container | object | `{"limits":{"cpu":"500m","ephemeral-storage":"128Mi","memory":"512Mi"},"requests":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"}}` |
| securityContext | Container security context | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` |
| serviceAccount | Service account configuration | object | `{"annotations":{},"name":"","tokenExpirationSeconds":3600}` |
| serviceAccount.annotations | Annotations to add to the service account | object | `{}` |
| serviceAccount.name | If not set, a name is generated using the fullname template. | string | `""` |
| serviceAccount.tokenExpirationSeconds | into the gather init container (minimum 600). | int | `3600` |
| strategy | Deployment strategy | object | `{"type":"Recreate"}` |
| test | Helm test configuration | object | `{"enabled":true,"image":{"digest":"","pullPolicy":"","registry":"docker.io","repository":"bitnami/kubectl","tag":"latest"}}` |
| test.enabled | Enable the Helm test | bool | `true` |
| test.image | Image for the test pod | object | `{"digest":"","pullPolicy":"","registry":"docker.io","repository":"bitnami/kubectl","tag":"latest"}` |
| tolerations | Tolerations for pod scheduling | list | `[]` |

