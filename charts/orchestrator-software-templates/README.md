
# Orchestrator Software Templates Chart for Red Hat Developer Hub

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart to install Openshift GitOps and Openshift Pipelines, which are required operators for installing Software Templates to be avaliable on RHDH.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat Developer Hub Team |  | <https://github.com/redhat-developer/rhdh-chart> |

## Source Code

* <https://github.com/redhat-developer/rhdh-chart>

## Requirements

Kubernetes: `>= 1.25.0-0`

## Overview

This Helm chart deploys the Orchestrator Software Templates for Red Hat Developer Hub (RHDH). It creates the necessary configurations and resources to enable orchestrator functionality within RHDH, including:

- Software template configurations for RHDH integration
- Tekton pipelines and tasks for workflow orchestration
- ArgoCD project configurations for GitOps workflows
- Authentication and catalog configurations for various SCM providers (GitHub, GitLab)

## Prerequisites

Before installing this chart, ensure you have installed the following:

0. Orchestrator-infra chart: responsible for installing necessary resources for Orchestrator to work.
1. Backstage chart: responsible for **Red Hat Developer Hub** and Orchestrator. It should be deployed and configured with Orchestrator enabled.
2. Orchestrator-software-templates-infra chart: responsible for deploying **OpenShift Pipelines** (Tekton) operator and **OpenShift GitOps** (ArgoCD) operator. It should be deployed in the same namespace as the backstage chart.
3. Running the setup script: responsible for creating the required secret for the software templates chart.
4. Optional: To make full use of ArgoCD and Tekton, you must following the instruction to configure the docker secret and ssh credentials, here: https://github.com/rhdhorchestrator/orchestrator-helm-operator/blob/main/docs/gitops/README.md.

## TL;DR

```console
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-orchestrator-templates redhat-developer/orchestrator-software-templates
```

> **Tip**: List all releases using `helm list`

## Configuration

The chart requires a secret named `orchestrator-auth-secret` in the RHDH namespace containing the following keys:

- `BACKEND_SECRET`: Backend authentication secret
- `K8S_CLUSTER_TOKEN`: Kubernetes cluster token
- `K8S_CLUSTER_URL`: Kubernetes cluster URL
- `GITHUB_TOKEN`: GitHub access token (optional)
- `GITHUB_CLIENT_ID`: GitHub OAuth client ID (optional)
- `GITHUB_CLIENT_SECRET`: GitHub OAuth client secret (optional)
- `GITLAB_HOST`: GitLab host URL (optional)
- `GITLAB_TOKEN`: GitLab access token (optional)
- `ARGOCD_URL`: ArgoCD server URL (optional)
- `ARGOCD_USERNAME`: ArgoCD username (optional)
- `ARGOCD_PASSWORD`: ArgoCD password (optional)

### Creating the Required Secret

You can use the provided setup script to create the secret:

```bash
./hack/orchestrator-templates-setup.sh
```

Or create it manually:

```bash
oc create secret generic orchestrator-auth-secret \
  -n rhdh \
  --from-literal=BACKEND_SECRET=your-backend-secret \
  --from-literal=K8S_CLUSTER_TOKEN=your-k8s-token \
  --from-literal=K8S_CLUSTER_URL=https://your-cluster-url \
  --from-literal=GITHUB_TOKEN=your-github-token
```

## Installation Examples

### Basic Installation

```bash
helm install orchestrator-templates redhat-developer/orchestrator-software-templates
```

### Custom RHDH Namespace

```bash
helm install orchestrator-templates redhat-developer/orchestrator-software-templates \
  --set orchestratorTemplates.rhdhChartNamespace=my-rhdh-namespace
```

### Disable Components

```bash
helm install orchestrator-templates redhat-developer/orchestrator-software-templates \
  --set tekton.enabled=false \
  --set argocd.enabled=false
```

### Custom ArgoCD Configuration

```bash
helm install orchestrator-templates redhat-developer/orchestrator-software-templates \
  --set argocd.argocdNamespace=my-gitops-namespace \
  --set argocd.argocdUrl=https://my-argocd-server.com
```

## Uninstalling the Chart

To uninstall/delete a Helm release named `orchestrator-templates`:

```console
helm uninstall orchestrator-templates
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Troubleshooting

### Common Issues

1. **Secret not found error**: Ensure the `orchestrator-auth-secret` exists in the correct namespace
2. **CRD not available**: Verify that Tekton and ArgoCD operators are installed and their CRDs are available
3. **RHDH not picking up configurations**: Check that the ConfigMaps have the correct label `rhdh.redhat.com/ext-config-sync: "true"`
4. **Tekton PipelineRuns are not successful**: Make sure that affinity-assistant is disabled in the TektonConfig CR.

### Checking Prerequisites

The chart will validate that required CRDs are available:
- `tekton.dev/v1/Task`
- `tekton.dev/v1/Pipeline`
- `argoproj.io/v1alpha1/AppProject`

Check the Helm release notes after installation for any warnings about missing CRDs.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| argocd.argocdNamespace |  | string | `"orchestrator-gitops"` |
| argocd.argocdPassword |  | string | `"ARGOCD_PASSWORD"` |
| argocd.argocdUrl |  | string | `"ARGOCD_URL"` |
| argocd.argocdUsername |  | string | `"ARGOCD_USERNAME"` |
| argocd.enabled |  | bool | `true` |
| orchestratorTemplates.enabled |  | bool | `true` |
| orchestratorTemplates.rhdhChartNamespace |  | string | `"rhdh"` |
| orchestratorTemplates.rhdhChartReleaseName |  | string | `"rhdh"` |
| rhdhConfig.catalogBranch |  | string | `"main"` |
| rhdhConfig.enableGuestProvider |  | bool | `false` |
| rhdhConfig.enabled |  | bool | `true` |
| rhdhConfig.secretRef.argocd.password |  | string | `"ARGOCD_PASSWORD"` |
| rhdhConfig.secretRef.argocd.url |  | string | `"ARGOCD_URL"` |
| rhdhConfig.secretRef.argocd.username |  | string | `"ARGOCD_USERNAME"` |
| rhdhConfig.secretRef.backstage.backendSecret |  | string | `"BACKEND_SECRET"` |
| rhdhConfig.secretRef.github.clientId |  | string | `"GITHUB_CLIENT_ID"` |
| rhdhConfig.secretRef.github.clientSecret |  | string | `"GITHUB_CLIENT_SECRET"` |
| rhdhConfig.secretRef.github.token |  | string | `"GITHUB_TOKEN"` |
| rhdhConfig.secretRef.gitlab.host |  | string | `"GITLAB_HOST"` |
| rhdhConfig.secretRef.gitlab.token |  | string | `"GITLAB_TOKEN"` |
| rhdhConfig.secretRef.k8s.clusterToken |  | string | `"K8S_CLUSTER_TOKEN"` |
| rhdhConfig.secretRef.k8s.clusterUrl |  | string | `"K8S_CLUSTER_URL"` |
| rhdhConfig.secretRef.name |  | string | `"orchestrator-auth-secret"` |
| tekton.enabled |  | bool | `true` |

## Additional Resources

- [Red Hat Developer Hub Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub)
- [OpenShift Pipelines Documentation](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html)
- [OpenShift GitOps Documentation](https://docs.openshift.com/container-platform/latest/cicd/gitops/understanding-openshift-gitops.html)
