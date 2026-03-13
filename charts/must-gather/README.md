
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
helm upgrade --install my-rhdh-must-gather rhdh-must-gather \
  --repo https://redhat-developer.github.io/rhdh-chart \
  --version 0.1.0
```

Running the command again will automatically replace the previous pod and start a new gather.

Then follow the instructions that will be printed to retrieve the gathered data.

## Running on OpenShift

This chart is optimized for running out of the box on Kubernetes.

For OpenShift, we recommend using the `oc adm must-gather` command, like so:

```sh
oc adm must-gather --image=quay.io/rhdh-community/rhdh-must-gather
```

See the [must-gather tool README](https://github.com/redhat-developer/rhdh-must-gather#for-openshift-clusters) for more details.

But if you still want to use this chart on OpenShift, you will need to unset the `podSecurityContext.fsGroup` value (or set it to a value aligned with your Security Context Constraints).

```sh
helm upgrade --install my-rhdh-must-gather rhdh-must-gather \
  --repo https://redhat-developer.github.io/rhdh-chart \
  --version 0.1.0 \
  --set podSecurityContext.fsGroup=null
```

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
| dataHolder | Runs alongside the gather container and stays alive so you can exec in and retrieve the output. | object | `{"resources":{"limits":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"},"requests":{"cpu":"50m","ephemeral-storage":"32Mi","memory":"64Mi"}}}` |
| dataHolder.resources | Resource requests and limits for the data-holder container | object | `{"limits":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"},"requests":{"cpu":"50m","ephemeral-storage":"32Mi","memory":"64Mi"}}` |
| fullnameOverride |  | string | `""` |
| gather | Gather script configuration | object | `{"clusterInfo":false,"cmdTimeout":"30","extraArgs":[],"logLevel":"info","namespaces":[],"since":"","sinceTime":"","withHeapDumps":false,"withSecrets":false,"withoutHelm":false,"withoutIngress":false,"withoutNamespaceInspect":false,"withoutOperator":false,"withoutOrchestrator":false,"withoutPlatform":false,"withoutRoute":false}` |
| gather.cmdTimeout | Command timeout for individual kubectl/helm commands (seconds) | string | `"30"` |
| gather.extraArgs | Additional custom arguments to pass to the gather script | list | `[]` |
| gather.logLevel | Log level: info, INFO, debug, DEBUG, trace, TRACE | string | `"info"` |
| gather.namespaces | Example: ["rhdh-prod", "rhdh-staging"] | list | `[]` |
| gather.since | Relative time for log collection (e.g., "2h", "30m") | string | `""` |
| gather.sinceTime | Absolute timestamp for log collection (RFC3339 format) | string | `""` |
| gather.withSecrets | Optional collection features (disabled by default) | bool | `false` |
| gather.withoutOperator | Exclusion options (set to true to skip collection) | bool | `false` |
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
| podSecurityContext | On OCP, the SCC may override fsGroup with a value from the namespace's allowed range. | object | `{"fsGroup":1001,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` |
| rbac | RBAC configuration | object | `{"create":true,"scope":"cluster"}` |
| rbac.create | Create RBAC resources (Role/ClusterRole and bindings) | bool | `true` |
| resources | Resource requests and limits for the gather container | object | `{"limits":{"cpu":"500m","ephemeral-storage":"128Mi","memory":"512Mi"},"requests":{"cpu":"100m","ephemeral-storage":"64Mi","memory":"128Mi"}}` |
| securityContext | Container security context | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` |
| serviceAccount | Service account configuration | object | `{"annotations":{},"automount":true,"create":true,"name":""}` |
| serviceAccount.annotations | Annotations to add to the service account | object | `{}` |
| serviceAccount.automount | Automatically mount a ServiceAccount's API credentials | bool | `true` |
| serviceAccount.create | Specifies whether a service account should be created | bool | `true` |
| serviceAccount.name | If not set and create is true, a name is generated using the fullname template | string | `""` |
| strategy | Deployment strategy | object | `{"type":"Recreate"}` |
| test | Helm test configuration | object | `{"enabled":true,"image":{"digest":"","pullPolicy":"","registry":"docker.io","repository":"bitnami/kubectl","tag":"latest"}}` |
| test.enabled | Enable the Helm test | bool | `true` |
| test.image | Image for the test pod | object | `{"digest":"","pullPolicy":"","registry":"docker.io","repository":"bitnami/kubectl","tag":"latest"}` |
| tolerations | Tolerations for pod scheduling | list | `[]` |

