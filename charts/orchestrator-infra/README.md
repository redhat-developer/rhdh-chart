
# orchestrator-infra

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

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

