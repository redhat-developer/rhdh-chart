
# orchestrator-infra

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Helm chart to deploy the Orchestrator solution's required infrastructure suite on OpenShift, including OpenShift Serverless Logic Operator and OpenShift Serverless Operator.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| serverlessLogicOperator.enabled |  | bool | `true` |
| serverlessLogicOperator.subscription.channel |  | string | `"alpha"` |
| serverlessLogicOperator.subscription.installPlanApproval |  | string | `"Manual"` |
| serverlessLogicOperator.subscription.name |  | string | `"logic-operator-rhel8"` |
| serverlessLogicOperator.subscription.namespace |  | string | `"openshift-serverless-logic"` |
| serverlessLogicOperator.subscription.sourceName |  | string | `"redhat-operators"` |
| serverlessLogicOperator.subscription.startingCSV |  | string | `"logic-operator-rhel8.v1.35.0"` |
| serverlessOperator.enabled |  | bool | `true` |
| serverlessOperator.subscription.channel |  | string | `"stable"` |
| serverlessOperator.subscription.installPlanApproval |  | string | `"Manual"` |
| serverlessOperator.subscription.name |  | string | `"serverless-operator"` |
| serverlessOperator.subscription.namespace |  | string | `"openshift-serverless"` |
| serverlessOperator.subscription.sourceName |  | string | `"redhat-operators"` |

