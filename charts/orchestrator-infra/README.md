
# orchestrator-infra

![Version: 0.0.2](https://img.shields.io/badge/Version-0.0.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Helm chart to deploy the Orchestrator solution's required infrastructure suite on OpenShift, including OpenShift Serverless Logic Operator and OpenShift Serverless Operator.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat Developer Hub Team |  | <https://github.com/redhat-developer/rhdh-chart> |

## Source Code

* <https://github.com/redhat-developer/rhdh-chart>

## Requirements

Kubernetes: `>= 1.25.0-0`

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| serverlessLogicOperator.enabled |  | bool | `true` |
| serverlessLogicOperator.subscription.namespace |  | string | `"openshift-serverless-logic"` |
| serverlessLogicOperator.subscription.spec.channel |  | string | `"alpha"` |
| serverlessLogicOperator.subscription.spec.installPlanApproval |  | string | `"Manual"` |
| serverlessLogicOperator.subscription.spec.name |  | string | `"logic-operator-rhel8"` |
| serverlessLogicOperator.subscription.spec.source |  | string | `"redhat-operators"` |
| serverlessLogicOperator.subscription.spec.sourceNamespace |  | string | `"openshift-marketplace"` |
| serverlessLogicOperator.subscription.spec.startingCSV |  | string | `"logic-operator-rhel8.v1.35.0"` |
| serverlessOperator.enabled |  | bool | `true` |
| serverlessOperator.subscription.namespace |  | string | `"openshift-serverless"` |
| serverlessOperator.subscription.spec.channel |  | string | `"stable"` |
| serverlessOperator.subscription.spec.installPlanApproval |  | string | `"Manual"` |
| serverlessOperator.subscription.spec.name |  | string | `"serverless-operator"` |
| serverlessOperator.subscription.spec.source |  | string | `"redhat-operators"` |
| serverlessOperator.subscription.spec.sourceNamespace |  | string | `"openshift-marketplace"` |
| tests.enabled |  | bool | `true` |
| tests.image |  | string | `"bitnami/kubectl:latest"` |


### Installing Knative Serving CRDs

The orchestrator-infra chart requires several CRDs for Knative Eventing and Knative Serving. These CRDs will be applied prior to installing the chart, ensuring that Knative CRs can be created as part of the chart’s deployment process. This approach eliminates the need to wait for the OpenShift Serverless Operator’s subscription to install them beforehand.

```bash
# To install a specific version, change to an existing release version
curl -L https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-crds.yaml -o eserving-crds.yaml

# To install the latest version
curl -L https://github.com/knative/serving/releases/latest/download/serving-crds.yaml -o serving-crds.yaml
```

### Installing Knative Eventing CRDs
```bash
# To install a specific version, change to an existing release version
curl -L https://github.com/knative/eventing/releases/download/knative-v1.17.3/eventing-crds.yaml -o eventing-crds.yaml

# To install the latest version
curl -L https://github.com/knative/eventing/releases/latest/download/eventing-crds.yaml -o eventing-crds.yaml
```