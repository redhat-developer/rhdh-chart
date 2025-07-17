
# Orchestrator Software Templates Infra Chart for OpenShift (Community Version)

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart to install Openshift GitOps and Openshift Pipelines, which are required operators for installing the Orchestrator Software Templates to be available on RHDH.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat Developer Hub Team |  | <https://github.com/redhat-developer/rhdh-chart> |

## Source Code

* <https://github.com/redhat-developer/rhdh-software-templates-infrastructure>

## Requirements

Kubernetes: `>= 1.25.0-0`

## TL;DR

```console
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-orchestrator-software-templates-infra redhat-developer/orchestrator-software-templates-infra
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

To uninstall/delete a Helm release named `my-orchestrator-software-templates-infra`:

```console
helm uninstall my-orchestrator-software-templates-infra
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| cleanupContainerImage | A container image and tag, will be used for the post-cleanup tasks. | string | `"bitnami/kubectl:latest"` |
| openshiftGitops.argocd_cr.controller.resources.limits.cpu |  | string | `"2000m"` |
| openshiftGitops.argocd_cr.controller.resources.limits.memory |  | string | `"2048Mi"` |
| openshiftGitops.argocd_cr.controller.resources.requests.cpu |  | string | `"250m"` |
| openshiftGitops.argocd_cr.controller.resources.requests.memory |  | string | `"1024Mi"` |
| openshiftGitops.argocd_cr.ha.enabled |  | bool | `false` |
| openshiftGitops.argocd_cr.ha.resources.limits.cpu |  | string | `"500m"` |
| openshiftGitops.argocd_cr.ha.resources.limits.memory |  | string | `"256Mi"` |
| openshiftGitops.argocd_cr.ha.resources.requests.cpu |  | string | `"250m"` |
| openshiftGitops.argocd_cr.ha.resources.requests.memory |  | string | `"128Mi"` |
| openshiftGitops.argocd_cr.rbac.defaultPolicy |  | string | `""` |
| openshiftGitops.argocd_cr.rbac.policy |  | string | `"g, system:cluster-admins, role:admin\n"` |
| openshiftGitops.argocd_cr.rbac.scopes |  | string | `"[groups]"` |
| openshiftGitops.argocd_cr.redis.resources.limits.cpu |  | string | `"500m"` |
| openshiftGitops.argocd_cr.redis.resources.limits.memory |  | string | `"256Mi"` |
| openshiftGitops.argocd_cr.redis.resources.requests.cpu |  | string | `"250m"` |
| openshiftGitops.argocd_cr.redis.resources.requests.memory |  | string | `"128Mi"` |
| openshiftGitops.argocd_cr.repo.resources.limits.cpu |  | string | `"1000m"` |
| openshiftGitops.argocd_cr.repo.resources.limits.memory |  | string | `"1024Mi"` |
| openshiftGitops.argocd_cr.repo.resources.requests.cpu |  | string | `"250m"` |
| openshiftGitops.argocd_cr.repo.resources.requests.memory |  | string | `"256Mi"` |
| openshiftGitops.argocd_cr.server.resources.limits.cpu |  | string | `"500m"` |
| openshiftGitops.argocd_cr.server.resources.limits.memory |  | string | `"256Mi"` |
| openshiftGitops.argocd_cr.server.resources.requests.cpu |  | string | `"125m"` |
| openshiftGitops.argocd_cr.server.resources.requests.memory |  | string | `"128Mi"` |
| openshiftGitops.argocd_cr.server.route.enabled |  | bool | `true` |
| openshiftGitops.argocd_cr.sso.dex.openShiftOAuth |  | bool | `true` |
| openshiftGitops.argocd_cr.sso.dex.resources.limits.cpu |  | string | `"500m"` |
| openshiftGitops.argocd_cr.sso.dex.resources.limits.memory |  | string | `"256Mi"` |
| openshiftGitops.argocd_cr.sso.dex.resources.requests.cpu |  | string | `"250m"` |
| openshiftGitops.argocd_cr.sso.dex.resources.requests.memory |  | string | `"128Mi"` |
| openshiftGitops.argocd_cr.sso.provider |  | string | `"dex"` |
| openshiftGitops.enabled | whether the operator should be deployed by the chart | bool | `true` |
| openshiftGitops.initialApps | Initial applications to deploy | list | `[]` |
| openshiftGitops.initialRepositories | Initial repositories configuration | list | `[]` |
| openshiftGitops.name | name of instances | string | `"argocd"` |
| openshiftGitops.namespaces | namespace of rhdh instance, will be used to install openshift-gitops. | list | `["rhdh"]` |
| openshiftGitops.repositoryCredentials | Repository credential templates | list | `[]` |
| openshiftGitops.secrets | Secrets for Git access or other repository credentials | list | `[]` |
| openshiftGitops.subscription | subscription config | object | `{"namespace":"openshift-operators","spec":{"channel":"latest","disableDefaultArgoCD":true,"installPlanApproval":"Automatic","name":"openshift-gitops-operator","source":"redhat-operators","sourceNamespace":"openshift-marketplace"}}` |
| openshiftGitops.subscription.spec | namespace where the operator should be deployed | object | `{"channel":"latest","disableDefaultArgoCD":true,"installPlanApproval":"Automatic","name":"openshift-gitops-operator","source":"redhat-operators","sourceNamespace":"openshift-marketplace"}` |
| openshiftGitops.subscription.spec.channel | channel of an operator package to subscribe to | string | `"latest"` |
| openshiftGitops.subscription.spec.installPlanApproval | whether the update should be installed automatically | string | `"Automatic"` |
| openshiftGitops.subscription.spec.name | name of the operator package | string | `"openshift-gitops-operator"` |
| openshiftGitops.subscription.spec.source | name of the catalog source | string | `"redhat-operators"` |
| openshiftPipelines.enabled | whether the operator should be deployed by the chart | bool | `true` |
| openshiftPipelines.subscription.name | name of the operator package | string | `"openshift-pipelines-operator-rh"` |
| openshiftPipelines.subscription.namespace | namespace where the operator should be deployed | string | `"openshift-operators"` |
| openshiftPipelines.subscription.spec.channel | channel of an operator package to subscribe to | string | `"latest"` |
| openshiftPipelines.subscription.spec.installPlanApproval | whether the update should be installed automatically | string | `"Automatic"` |
| openshiftPipelines.subscription.spec.name | name of the operator package | string | `"openshift-pipelines-operator-rh"` |
| openshiftPipelines.subscription.spec.source | name of the catalog source | string | `"redhat-operators"` |
| openshiftPipelines.subscription.spec.sourceNamespace |  | string | `"openshift-marketplace"` |
| resources.limits.cpu |  | string | `"500m"` |
| resources.limits.memory |  | string | `"1Gi"` |
| resources.requests.cpu |  | string | `"250m"` |
| resources.requests.memory |  | string | `"64Mi"` |
| test.enabled | Whether to enable the pod used for testing the Release using `helm test`. | bool | `true` |
| test.image.registry | Test infra-test Tekton Task pod image registry | string | `"bitnami"` |
| test.image.repository | Test infra-test Tekton Task pod image repository. | string | `"kubectl"` |
| test.image.tag | Test infra-test Tekton Task pod image tag. | string | `"latest"` |

