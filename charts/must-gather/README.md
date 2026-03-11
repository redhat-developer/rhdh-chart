
# Must Gather Chart for Red Hat Developer Hub (RHDH)

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
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
helm install my-rhdh-must-gather rhdh-must-gather \
  --repo https://redhat-developer.github.io/rhdh-chart \
  --version 0.1.0
```

Then follow the instructions that will be printed to retrieve the gathered data.

> **Tip**: List all releases using `helm list`

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
  --set test.image=<image>
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
| dataRetriever | This pod allows you to retrieve the gathered data after the job completes | object | `{"enabled":true,"image":{"pullPolicy":"","repository":"registry.access.redhat.com/ubi9","tag":"latest"},"resources":{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}}` |
| dataRetriever.enabled | Enable the data retriever pod | bool | `true` |
| dataRetriever.image | Image for the data retriever pod | object | `{"pullPolicy":"","repository":"registry.access.redhat.com/ubi9","tag":"latest"}` |
| dataRetriever.resources | Resource configuration | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` |
| fullnameOverride |  | string | `""` |
| gather | Gather script configuration | object | `{"clusterInfo":false,"cmdTimeout":"30","extraArgs":[],"logLevel":"INFO","namespaces":"","since":"","sinceTime":"","withHeapDumps":false,"withSecrets":false,"withoutHelm":false,"withoutIngress":false,"withoutNamespaceInspect":false,"withoutOperator":false,"withoutOrchestrator":false,"withoutPlatform":false,"withoutRoute":false}` |
| gather.cmdTimeout | Command timeout for individual kubectl/helm commands (seconds) | string | `"30"` |
| gather.extraArgs | Additional custom arguments to pass to the gather script | list | `[]` |
| gather.logLevel | Log level: INFO, DEBUG, TRACE | string | `"INFO"` |
| gather.namespaces | Example: "rhdh-prod,rhdh-staging" | string | `""` |
| gather.since | Relative time for log collection (e.g., "2h", "30m") | string | `""` |
| gather.sinceTime | Absolute timestamp for log collection (RFC3339 format) | string | `""` |
| gather.withSecrets | Optional collection features (disabled by default) | bool | `false` |
| gather.withoutOperator | Exclusion options (set to true to skip collection) | bool | `false` |
| image | Container image configuration | object | `{"pullPolicy":"","repository":"quay.io/rhdh-community/rhdh-must-gather","tag":"latest"}` |
| imagePullSecrets | Secrets for pulling images from a private registry | list | `[]` |
| job | Job configuration | object | `{"activeDeadlineSeconds":3600,"backoffLimit":3,"ttlSecondsAfterFinished":""}` |
| job.activeDeadlineSeconds | Job timeout in seconds (default: 1 hour) | int | `3600` |
| job.backoffLimit | Number of retries before marking job as failed | int | `3` |
| job.ttlSecondsAfterFinished | Set to a positive value to enable automatic cleanup | string | `""` |
| nameOverride | Override the chart name | string | `""` |
| nodeSelector | Node selector for pod scheduling | object | `{}` |
| persistence | Persistent volume configuration for storing gathered data | object | `{"accessMode":"ReadWriteOnce","size":"1Gi","storageClass":""}` |
| persistence.accessMode | Access mode | string | `"ReadWriteOnce"` |
| persistence.size | Storage size | string | `"1Gi"` |
| persistence.storageClass | Storage class (empty = use cluster default) | string | `""` |
| podAnnotations | Pod annotations | object | `{}` |
| podLabels | Pod labels | object | `{}` |
| podSecurityContext | Pod security context | object | `{}` |
| rbac | RBAC configuration | object | `{"create":true}` |
| rbac.create | Create ClusterRole and ClusterRoleBinding for cluster-wide read access | bool | `true` |
| resources | Resource requests and limits for the gather job | object | `{"limits":{"cpu":"500m","ephemeral-storage":"128Mi","memory":"512Mi"},"requests":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"}}` |
| securityContext | Container security context | object | `{}` |
| serviceAccount | Service account configuration | object | `{"annotations":{},"automount":true,"create":true,"name":""}` |
| serviceAccount.annotations | Annotations to add to the service account | object | `{}` |
| serviceAccount.automount | Automatically mount a ServiceAccount's API credentials | bool | `true` |
| serviceAccount.create | Specifies whether a service account should be created | bool | `true` |
| serviceAccount.name | If not set and create is true, a name is generated using the fullname template | string | `""` |
| test | Helm test configuration | object | `{"enabled":true,"image":{"pullPolicy":"","repository":"bitnami/kubectl","tag":"latest"}}` |
| test.enabled | Enable the Helm test | bool | `true` |
| test.image | Image for the test pod | object | `{"pullPolicy":"","repository":"bitnami/kubectl","tag":"latest"}` |
| tolerations | Tolerations for pod scheduling | list | `[]` |

