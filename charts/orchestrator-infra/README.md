
# Orchestrator Infra Chart for OpenShift

![Version: 0.0.6](https://img.shields.io/badge/Version-0.0.6-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Helm chart to deploy the Orchestrator solution's required infrastructure suite on OpenShift, including OpenShift Serverless Logic Operator and OpenShift Serverless Operator.

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

helm install my-orchestrator-infra redhat-developer/orchestrator-infra
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

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| serverlessLogicOperator.enabled | whether the operator should be deployed by the chart | bool | `true` |
| serverlessLogicOperator.subscription.namespace | namespace where the operator should be deployed | string | `"openshift-serverless-logic"` |
| serverlessLogicOperator.subscription.spec.channel | channel of an operator package to subscribe to | string | `"alpha"` |
| serverlessLogicOperator.subscription.spec.installPlanApproval | whether the update should be installed automatically | string | `"Manual"` |
| serverlessLogicOperator.subscription.spec.name | name of the operator package | string | `"logic-operator-rhel8"` |
| serverlessLogicOperator.subscription.spec.source | name of the catalog source | string | `"redhat-operators"` |
| serverlessLogicOperator.subscription.spec.sourceNamespace |  | string | `"openshift-marketplace"` |
| serverlessLogicOperator.subscription.spec.startingCSV | The initial version of the operator | string | `"logic-operator-rhel8.v1.35.0"` |
| serverlessOperator.enabled | whether the operator should be deployed by the chart | bool | `true` |
| serverlessOperator.subscription.namespace | namespace where the operator should be deployed | string | `"openshift-serverless"` |
| serverlessOperator.subscription.spec.channel | channel of an operator package to subscribe to | string | `"stable"` |
| serverlessOperator.subscription.spec.installPlanApproval | whether the update should be installed automatically | string | `"Manual"` |
| serverlessOperator.subscription.spec.name | name of the operator package | string | `"serverless-operator"` |
| serverlessOperator.subscription.spec.source | name of the catalog source | string | `"redhat-operators"` |
| serverlessOperator.subscription.spec.sourceNamespace |  | string | `"openshift-marketplace"` |
| tests.enabled | Whether to create the test pod used for testing the Release using `helm test`. | bool | `true` |
| tests.image | Test pod image | string | `"bitnami/kubectl:latest"` |

