# Orchestrator Infra Chart for OpenShift

![Version: 0.7.0](https://img.shields.io/badge/Version-0.7.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Helm chart to deploy the Orchestrator solution's required infrastructure suite on OpenShift, including OpenShift Serverless Operator and OpenShift Serverless Logic Operator, both required to configure Red Hat Developer Hub to use the Orchestrator.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat Developer Hub Team |  | <https://github.com/redhat-developer/rhdh-chart> |

## Source Code

* <https://github.com/redhat-developer/rhdh-chart>

## Requirements

Kubernetes: `>= 1.25.0-0`

## TL;DR

```console
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-orchestrator-infra redhat-developer/redhat-developer-hub-orchestrator-infra --version 0.7.0
```

> **Tip**: List all releases using `helm list`

## Testing a Release

Once an Helm Release has been deployed, you can test it using the [`helm test`](https://helm.sh/docs/helm/helm_test/) command:

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

To uninstall/delete a Helm release named `my-orchestrator-infra`:

```console
helm uninstall my-orchestrator-infra
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| olm.catalog.selector | object | `{"matchLabels":{"olm.operatorframework.io/metadata.name":"openshift-redhat-operators"}}` | ClusterCatalog selector for OLM v1 ClusterExtension resources |
| olmVersion | string | `"v0"` | OLM API version to use for operator installation (`v0` or `v1`) |
| serverlessLogicOperator.clusterExtension.serviceAccount.name | string | `"serverless-logic-operator-installer"` | service account used by OLM v1 to install the operator |
| serverlessLogicOperator.enabled | bool | `true` | whether the operator should be deployed by the chart |
| serverlessLogicOperator.subscription.namespace | string | `"openshift-serverless-logic"` | namespace where the operator should be deployed |
| serverlessLogicOperator.subscription.spec.channel | string | `"stable"` | channel of an operator package to subscribe to |
| serverlessLogicOperator.subscription.spec.installPlanApproval | string | `"Manual"` | whether the update should be installed automatically |
| serverlessLogicOperator.subscription.spec.name | string | `"logic-operator"` | name of the operator package |
| serverlessLogicOperator.subscription.spec.source | string | `"redhat-operators"` | name of the catalog source |
| serverlessLogicOperator.subscription.spec.sourceNamespace | string | `"openshift-marketplace"` |  |
| serverlessLogicOperator.subscription.spec.startingCSV | string | `"logic-operator.v1.38.0"` | The initial version of the operator, must match CRDs installed by the chart |
| serverlessOperator.clusterExtension.serviceAccount.name | string | `"serverless-operator-installer"` | service account used by OLM v1 to install the operator |
| serverlessOperator.enabled | bool | `true` | whether the operator should be deployed by the chart |
| serverlessOperator.subscription.namespace | string | `"openshift-serverless"` | namespace where the operator should be deployed |
| serverlessOperator.subscription.spec.channel | string | `"stable"` | channel of an operator package to subscribe to |
| serverlessOperator.subscription.spec.installPlanApproval | string | `"Manual"` | whether the update should be installed automatically |
| serverlessOperator.subscription.spec.name | string | `"serverless-operator"` | name of the operator package |
| serverlessOperator.subscription.spec.source | string | `"redhat-operators"` | name of the catalog source |
| serverlessOperator.subscription.spec.sourceNamespace | string | `"openshift-marketplace"` |  |
| tests.enabled | bool | `true` | Whether to create the test pod used for testing the Release using `helm test`. |
| tests.image | string | `"bitnami/kubectl:latest"` | Test pod image |

### OLM v0 and OLM v1 operator installation

The chart defaults to `olmVersion: v0`.

- `v0`: creates `Subscription` resources
- `v1`: creates `ClusterExtension` resources with an installer ServiceAccount and ClusterRoleBinding

```bash
helm install my-orchestrator-infra ./charts/orchestrator-infra --set olmVersion=v0
helm install my-orchestrator-infra ./charts/orchestrator-infra --set olmVersion=v1
```

### Installing Knative Eventing and Knative Serving CRDs

The orchestrator-infra chart requires several CRDs for Knative Eventing and Knative Serving. These CRDs will be applied prior to installing the chart, ensuring that Knative CRs can be created as part of the chart's deployment process. This approach eliminates the need to wait for the OpenShift Serverless Operator's subscription to install them beforehand.

The KnativeEventing and KnativeServing CRDs are required for this chart to run. These CRDs need to be present under the `crds/` directory before running `helm install`.
After installing the openshift-serverless subscription, more Knative CRDs will be installed on the cluster.

The versions of the CRDs present in the chart and the ones in the subscription must match. In order to verify the correct CRD, use this following command to extract the CRD:

```bash
export osl_bundle=registry.redhat.io/openshift-serverless-1/serverless-operator-bundle:1.38.0
podman container run --rm --entrypoint cat "$osl_bundle" /manifests/operator_v1beta1_knativeeventing_crd.yaml > crds/knative-eventing/knative-eventing-crd.yaml

podman container run --rm --entrypoint cat "$osl_bundle" /manifests/operator_v1beta1_knativeserving_crd.yaml > crds/knative-serving/knative-serving-crd.yaml
```
