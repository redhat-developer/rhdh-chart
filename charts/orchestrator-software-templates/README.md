
# Orchestrator Software Templates Chart for Red Hat Developer Hub

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

This Helm chart deploys the Orchestrator Software Templates for Red Hat Developer Hub (RHDH) and other necessary GitOps configurations.

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
4. Optional: To make full use of ArgoCD and Tekton, you must following the instruction to configure the docker secret and ssh credentials, here: https://github.com/rhdhorchestrator/orchestrator-go-operator/blob/main/docs/gitops/README.md.
5. Label the RHDH namespace with `oc label ns rhdh rhdh.redhat.com/argocd-namespace=true` to enable the configuration sync.

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

Acquire the following ArgoCD:

ARGOCD_URL: https://argocd-server.<apps.example.com>
ARGOCD_USERNAME: admin
ARGOCD_PASSWORD: `oc get secret -n openshift-gitops openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d`

The secret can be created by the setup script or manually

```bash
oc create secret generic orchestrator-auth-secret \
  -n rhdh \
  --from-literal=BACKEND_SECRET=your-backend-secret \
  --from-literal=K8S_CLUSTER_TOKEN=your-k8s-token \
  --from-literal=K8S_CLUSTER_URL=https://your-cluster-url \
  --from-literal=GITHUB_TOKEN=your-github-token
```

## Installation

After configuring all prerequisites, you can install the chart with the following command:

```console
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-orchestrator-templates redhat-developer/orchestrator-software-templates --version 0.1.2
```

Now, follow the instruction on the post-installation Notes. They will include the steps to create a custom values.yaml file to allow you to update the backstage chart

## Running a template

In the RHDH UI, you will now have some software templates available. You can select one and click on "Run" to start the workflow.
For example, you can run the "Github Basic workflow bootstrap project" template to create a new workflow project.
After bootstrapping the project, a Tekton pipeline will build and push the workflow, and the ArgoCD project we have configured will deploy it onto the cluster in the rhdh namespace.
After all GitOps components run successfully, you can now run the workflow via Orchestrator.

## Uninstalling the Chart

To uninstall/delete a Helm release named `orchestrator-templates`:

```console
helm uninstall my-orchestrator-templates
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Troubleshooting

### Common Issues

1. **Secret not found error**: Ensure the `orchestrator-auth-secret` exists in the correct namespace
2. **CRD not available**: Verify that Tekton and ArgoCD operators are installed and their CRDs are available
3. **RHDH not picking up configurations**: Check that the ConfigMaps have the correct label `rhdh.redhat.com/ext-config-sync: "true"`
4. **Tekton PipelineRuns are not successful**: Make sure that affinity-assistant is disabled in the TektonConfig CR. To disable it, edit the tekton config and make sure the `coschedule` feature flag is set to `false`
5. **Namespace labeling**: Label the RHDH namespace for ArgoCD management: `oc label ns rhdh argocd.argoproj.io/managed-by=orchestrator-gitops`
6. **Bootstrap project permissions**: When running templates to create bootstrap projects, ensure the bootstrap project repository has write permissions. You can change the permissions by editing the repository in Github.
7. **AppProject creation**: If no AppProject exists, create a new AppProject in the `orchestrator-gitops` namespace
8. **Required secrets**: Ensure the docker merged secret and orchestrator auth secret are present on the cluster
9. **Concurrent pipeline runs**: Avoid running multiple pipelines simultaneously - if a pipeline fails, ensure no other pipelines are running at the same time
10. **GitOps pipeline flow**: Follow the complete workflow: PipelineRun → GitOps pipeline → Workflow deployment on cluster

### Checking Prerequisites

The chart will validate that required CRDs are available:
- `tekton.dev/v1/Task`
- `tekton.dev/v1/Pipeline`
- `argoproj.io/v1alpha1/AppProject`

Check the Helm release notes after installation for any warnings about missing CRDs.

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| argocd.argocdNamespace | References the ArgoCD instance created by infra chart | string | `"orchestrator-gitops"` |
| argocd.enabled |  | bool | `true` |
| orchestratorTemplates.enabled |  | bool | `true` |
| orchestratorTemplates.rhdhChartNamespace |  | string | `"rhdh"` |
| orchestratorTemplates.rhdhChartReleaseName |  | string | `"rhdh"` |
| rhdhConfig.catalogBranch | Branch to use for catalog templates | string | `"main"` |
| rhdhConfig.enableGuestProvider | Enable guest authentication provider | bool | `false` |
| rhdhConfig.enabled | Enable RHDH operator | bool | `true` |
| rhdhConfig.secretRef.argocd.password | Key in the secret for ArgoCD password | string | `"ARGOCD_PASSWORD"` |
| rhdhConfig.secretRef.argocd.url | Key in the secret for ArgoCD URL | string | `"ARGOCD_URL"` |
| rhdhConfig.secretRef.argocd.username | Key in the secret for ArgoCD username | string | `"ARGOCD_USERNAME"` |
| rhdhConfig.secretRef.backstage.backendSecret | Key in the secret for backend authentication | string | `"BACKEND_SECRET"` |
| rhdhConfig.secretRef.github.clientId | Key in the secret for GitHub client ID | string | `"GITHUB_CLIENT_ID"` |
| rhdhConfig.secretRef.github.clientSecret | Key in the secret for GitHub client secret | string | `"GITHUB_CLIENT_SECRET"` |
| rhdhConfig.secretRef.github.token | Key in the secret for GitHub token | string | `"GITHUB_TOKEN"` |
| rhdhConfig.secretRef.gitlab.host | Key in the secret for GitLab host | string | `"GITLAB_HOST"` |
| rhdhConfig.secretRef.gitlab.token | Key in the secret for GitLab token | string | `"GITLAB_TOKEN"` |
| rhdhConfig.secretRef.k8s.clusterToken | Key in the secret for Kubernetes cluster token | string | `"K8S_CLUSTER_TOKEN"` |
| rhdhConfig.secretRef.k8s.clusterUrl | Key in the secret for Kubernetes cluster URL | string | `"K8S_CLUSTER_URL"` |
| rhdhConfig.secretRef.name | Name of the secret containing the configuration | string | `"orchestrator-auth-secret"` |
| tekton.enabled |  | bool | `true` |

## Additional Resources

- [Red Hat Developer Hub Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub)
- [OpenShift Pipelines Documentation](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html)
- [OpenShift GitOps Documentation](https://docs.openshift.com/container-platform/latest/cicd/gitops/understanding-openshift-gitops.html)
