
# RHDH Helm Chart for OpenShift and Kubernetes

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart for deploying Red Hat Developer Hub, which is a Red Hat supported version of Backstage.

The telemetry data collection feature is enabled by default. Red Hat Developer Hub sends telemetry data to Red Hat by using the `backstage-plugin-analytics-provider-segment` plugin. To disable this and to learn what data is being collected, see https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.10/html-single/telemetry_data_collection_and_analysis/index

**Homepage:** <https://developers.redhat.com/products/rhdh>

## Productized RHDH

This repository now provides the productized RHDH chart.
For the **Generally Available** version of this chart, see:

* https://github.com/openshift-helm-charts/charts - official releases to https://charts.openshift.io/

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat |  | <https://redhat.com> |

## Source Code

* <https://github.com/redhat-developer/rhdh-chart/tree/main/charts/rhdh>
* <https://github.com/redhat-developer/rhdh>
* <https://github.com/redhat-developer/rhdh-plugins>
* <https://github.com/redhat-developer/rhdh-plugin-export-overlays>

## TL;DR

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-rhdh redhat-developer/redhat-developer-hub --version 1.0.0
```

## Introduction

This chart bootstraps a [Red Hat Developer Hub](https://developers.redhat.com/rhdh) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Unlike the legacy `backstage` chart, this chart owns all Kubernetes templates directly (Deployment, Service, ConfigMap, etc.) without depending on an upstream Backstage subchart. It uses an **"add, don't replace"** pattern: system-required volumes, volume mounts, environment variables, and init containers are hardcoded in the Deployment template, while user-provided values (`extraVolumes`, `extraVolumeMounts`, `extraEnv`, `extraInitContainers`, `extraContainers`) are always appended — never replacing the defaults.

## Prerequisites

- Kubernetes 1.27+ ([OpenShift 4.14+](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/release_notes/index#ocp-4-14-about-this-release))
- Helm 3.10+ or [latest release](https://github.com/helm/helm/releases)
- PV provisioner support in the underlying infrastructure

## Usage

Charts are available in the following formats:

- [Chart Repository](https://helm.sh/docs/topics/chart_repository/)
- [OCI Artifacts](https://helm.sh/docs/topics/registries/)

### Note

Up-to-date instructions on installing RHDH through the chart can be found in the [installation docs](https://github.com/redhat-developer/rhdh-chart/tree/main/.rhdh/docs/installation-ci-charts.adoc).

### Installing from the Chart Repository

The following command can be used to add the chart repository:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart
```

Once the chart has been added, install this chart. However before doing so, please review the default `values.yaml` and adjust as needed.

- To get proper connection between frontend and backend of Backstage please update the `apps.example.com` to match your cluster host:

   ```yaml
   openshift:
     clusterRouterBase: apps.example.com
   ```

   > Tip: you can use `helm upgrade -i --set openshift.clusterRouterBase=apps.example.com ...` instead of a value file

- If your cluster doesn't provide PVCs, you should disable PostgreSQL persistence via:

   ```yaml
   postgresql:
     primary:
       persistence:
         enabled: false
   ```

```console
helm upgrade -i <release_name> redhat-developer/redhat-developer-hub
```

### Installing from an OCI Registry

Charts are also available in OCI format. The list of available releases can be found [here](https://quay.io/repository/rhdh/chart?tab=tags).

Install one of the available versions:

```shell
helm upgrade -i <release_name> oci://quay.io/rhdh/chart --version=<version>
```

> **Tip**: List all releases using `helm list`

### Testing a Release

Once an Helm Release has been deployed, you can test it using the [`helm test`](https://helm.sh/docs/helm/helm_test/) command:

```sh
helm test <release_name>
```

This will run a simple Pod in the cluster to check that the application deployed is up and running.

You can control whether to disable this test pod or customize the image, pull policy, and security context it uses.
See the `test.enabled`, `test.image`, and `test.securityContext` parameters in the [`values.yaml`](./values.yaml) file.

> **Tip**: Disabling the test pod will not prevent the `helm test` command from passing later on. It will simply report that no test suite is available.

Below are a few examples:

<details>

<summary>Disabling the test pod</summary>

```sh
helm install <release_name> <repo_or_oci_registry> \
  --set test.enabled=false
```

</details>

<details>

<summary>Customizing the test pod image</summary>

```sh
helm install <release_name> <repo_or_oci_registry> \
  --set test.image.repository=curl/curl-base \
  --set test.image.tag=8.11.1
```

</details>

### Uninstalling the Chart

To uninstall/delete the `my-rhdh` deployment:

```console
helm uninstall my-rhdh
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Upgrading from the backstage chart (RHDH 1.y)

> **Note:** This section is a work in progress. A detailed migration guide will be provided before the GA release of RHDH 2.y.

If you are upgrading from the legacy `backstage` chart (used in RHDH 1.y), the new `redhat-developer-hub` chart is a clean break. The values structure has changed significantly — all `global.*` and `upstream.backstage.*` nesting has been flattened to root-level keys. A `helm upgrade` from the old chart to this one is **not** supported; you will need to perform a fresh install with migrated values.

## Requirements

Kubernetes: `>= 1.31.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | common | 2.40.0 |
| oci://registry-1.docker.io/bitnamicharts | postgresql | 16.2.5 |

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| affinity | Affinity rules for pod assignment. | object | `{}` |
| appConfig | Inline Backstage app-config YAML. Rendered into a ConfigMap and mounted as app-config-from-configmap.yaml. | object | Default config with base URLs, CORS, database connection, and backend auth. |
| argsOverride | Override the container arguments entirely. When set, system config arguments are NOT added automatically; you must include them yourself. | list | `[]` |
| auth | Service-to-service authentication configuration. | object | `{"backend":{"enabled":true,"existingSecretRef":{"key":"backend-secret","name":""},"value":""}}` |
| auth.backend.enabled | Enable backend service-to-service authentication. Generates a random secret unless existingSecretRef is set or value is provided. Disable if you inject the secret via extraEnvFrom or extraEnv instead. | bool | `true` |
| auth.backend.existingSecretRef | Reference an existing Secret instead of generating one. When not set, the chart auto-generates a random token. | object | `{"key":"backend-secret","name":""}` |
| auth.backend.existingSecretRef.key | Key within the Secret that holds the backend auth token. | string | `"backend-secret"` |
| auth.backend.existingSecretRef.name | Name of the existing Secret. When empty, the chart generates one. | string | `""` |
| auth.backend.value | Use a specific value instead of generating one. | string | `""` |
| autoscaling | Horizontal Pod Autoscaler configuration. | object | `{"enabled":false,"maxReplicas":3,"minReplicas":1,"targetCPUUtilizationPercentage":80}` |
| catalogIndex | Catalog index configuration for automatic plugin discovery. | object | `{"extraImages":[],"image":{"digest":"","registry":"quay.io","repository":"rhdh/plugin-catalog-index","tag":"next"}}` |
| catalogIndex.extraImages | Extra catalog index images for additional plugin discovery in the Extensions UI. Each item must include `registry`, `repository`, and `tag` fields; `name` and `digest` are optional. Only catalog entities are extracted from extra images (no `dynamic-plugins.default.yaml` handling). | list | `[]` |
| commandOverride | Override the container command. | list | `[]` |
| commonAnnotations | Annotations applied to ALL chart resources. | object | `{}` |
| commonLabels | Labels applied to ALL chart resources. | object | `{}` |
| containerSecurityContext | Security context for the main RHDH container (not the Lightspeed sidecar or init containers). | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` |
| deploymentAnnotations | Annotations for the Deployment resource (not the pod). | object | `{}` |
| dynamicPlugins | Dynamic plugin system configuration. | object | `{"includes":["dynamic-plugins.default.yaml"],"initContainer":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"resources":{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}},"securityContext":{}},"maxEntrySize":40000000,"plugins":[],"volume":{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"type":"ephemeral"}}` |
| dynamicPlugins.includes | Array of YAML files listing dynamic plugins to include. Relative paths are resolved from the working directory of the initContainer (`/opt/app-root/src`). | list | `["dynamic-plugins.default.yaml"]` |
| dynamicPlugins.initContainer | Configuration for the install-dynamic-plugins init container. | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"resources":{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}},"securityContext":{}}` |
| dynamicPlugins.initContainer.argsOverride | Override the default arguments. Leave empty to use the defaults. | list | `[]` |
| dynamicPlugins.initContainer.commandOverride | Override the default command. Leave empty to use the default (./install-dynamic-plugins.sh /dynamic-plugins-root). | list | `[]` |
| dynamicPlugins.initContainer.extraArgs | Extra arguments appended after the default arguments. Ignored when argsOverride is set. | list | `[]` |
| dynamicPlugins.initContainer.extraEnv | Extra environment variables appended after the system env vars (NPM_CONFIG_USERCONFIG, MAX_ENTRY_SIZE, CATALOG_INDEX_IMAGE, etc.). | list | `[]` |
| dynamicPlugins.initContainer.extraVolumeMounts | Additional volume mounts appended after the system mounts (dynamic-plugins-root, npmrc, registry-auth, npmcacache, extensions-catalog, temp). | list | `[]` |
| dynamicPlugins.initContainer.resources | Resource requests and limits. | object | `{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}}` |
| dynamicPlugins.initContainer.securityContext | Security context for the init container. | object | Same as containerSecurityContext |
| dynamicPlugins.maxEntrySize | Maximum uncompressed size (in bytes) of a single dynamic plugin entry. | int | `40000000` |
| dynamicPlugins.plugins | List of dynamic plugins. Every item defines the plugin `package` as a NPM package spec or OCI reference. | list | `[]` |
| dynamicPlugins.volume | Volume configuration for the dynamic plugins root directory. | object | `{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"type":"ephemeral"}` |
| dynamicPlugins.volume.emptyDir | Raw Kubernetes emptyDir volume spec. Used when type is "emptyDir". | object | `{}` |
| dynamicPlugins.volume.ephemeral | Ephemeral volume configuration. Used when type is "ephemeral". The chart builds the full ephemeral.volumeClaimTemplate.spec from these fields. | object | `{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""}` |
| dynamicPlugins.volume.ephemeral.accessModes | Access modes for the ephemeral PVC. | list | `["ReadWriteOnce"]` |
| dynamicPlugins.volume.ephemeral.resources | Resource requests for the ephemeral PVC. | object | `{"requests":{"storage":"5Gi"}}` |
| dynamicPlugins.volume.ephemeral.storageClassName | StorageClass for the ephemeral volume. When empty, uses global.defaultStorageClass or the cluster default. | string | `""` |
| dynamicPlugins.volume.pvc | Raw Kubernetes persistentVolumeClaim volume spec. Used when type is "pvc". | object | `{"claimName":""}` |
| dynamicPlugins.volume.type | Volume type: "ephemeral" (auto-provisioned PVC per pod), "emptyDir" (scratch space, lost on pod restart), or "pvc" (pre-existing PersistentVolumeClaim). | string | `"ephemeral"` |
| envFromOverride | Override the container envFrom entirely. When set, extraEnvFrom is ignored. Accepts raw Kubernetes envFrom entries (configMapRef, secretRef, prefix). | list | `[]` |
| envOverride | Override the container environment variables entirely. When set, system env vars (BACKEND_SECRET, DB credentials, etc.) are NOT added automatically. | list | `[]` |
| externalDatabase | External database connection. Used when postgresql.enabled is false. When both postgresql.enabled and externalDatabase.host are false/empty, the chart renders no database env vars (BYO configuration via extraEnv or appConfig). | object | `{"existingSecretRef":{"key":"password","name":""},"host":"","port":5432,"user":"postgres"}` |
| externalDatabase.existingSecretRef | Reference to an existing Secret containing the database password. | object | `{"key":"password","name":""}` |
| externalDatabase.existingSecretRef.key | Key within the Secret that holds the password. | string | `"password"` |
| externalDatabase.existingSecretRef.name | Name of the existing Secret. | string | `""` |
| externalDatabase.host | External database hostname. | string | `""` |
| externalDatabase.port | External database port. | int | `5432` |
| externalDatabase.user | External database user. | string | `"postgres"` |
| extraAppConfig | Additional app-config files from existing ConfigMaps. | list | `[]` |
| extraArgs | Extra arguments appended after the system config flags. | list | `[]` |
| extraContainers | Additional sidecar containers. These are ADDED to system containers (e.g. Lightspeed sidecar), never replacing them. | list | `[]` |
| extraEnv | Extra environment variables appended after the system env vars. | list | `[]` |
| extraEnvFrom | Extra envFrom entries appended to the container. Accepts raw Kubernetes envFrom entries (configMapRef, secretRef, prefix). | list | `[]` |
| extraInitContainers | Additional init containers. These are ADDED after system init containers (install-dynamic-plugins, Lightspeed RAG init), never replacing them. | list | `[]` |
| extraVolumeMounts | Additional volume mounts to add to the main container. These are ADDED to system-required mounts, never replacing them. | list | `[]` |
| extraVolumes | Additional volumes to add to the pod. These are ADDED to system-required volumes (dynamic-plugins-root, temp, npmcacache, etc.), never replacing them. | list | `[]` |
| fullnameOverride | Override the full resource name. | string | `""` |
| global | Global parameters shared with bitnami subcharts (postgresql, common). | object | `{"defaultStorageClass":"","imagePullSecrets":[],"imageRegistry":""}` |
| global.defaultStorageClass | Global default StorageClass for PVCs. | string | `""` |
| global.imagePullSecrets | Global Docker registry secret names. | list | `[]` |
| global.imageRegistry | Global Docker image registry. Overrides per-image registries for all containers. | string | `""` |
| host | Custom hostname. Overrides openshift.clusterRouterBase for URL generation. | string | `""` |
| hostAliases | Host aliases for /etc/hosts entries. | list | `[]` |
| httpRoute | Gateway API HTTPRoute configuration. | object | `{"annotations":{},"enabled":false,"hostnames":[],"labels":{},"parentRefs":[],"rules":[]}` |
| httpRoute.labels | Additional labels for the HTTPRoute resource. | object | `{}` |
| image | Container image configuration. | object | `{"digest":"","pullPolicy":"IfNotPresent","registry":"quay.io","repository":"rhdh-community/rhdh","tag":"next"}` |
| image.digest | Overrides the image tag with an image digest. | string | `""` |
| imagePullSecrets | Secrets for pulling images from private registries (merged with global.imagePullSecrets). | list | `[]` |
| ingress | Kubernetes Ingress configuration. | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"{{ .Values.host }}","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` |
| lightspeed | Built-in Lightspeed AI feature configuration. | object | `{"config":{"profile":{"existingConfigMap":{"key":"","name":""}},"server":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}},"core":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"0.5.3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}},"enabled":true,"existingSecret":"","plugins":[{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-lightspeed:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-lightspeed-backend:{{ \"{{inherit}}\" }}"}],"ragInit":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"redhat-ai-dev/rag-content","tag":"release-1.10-lls-0.5.0-8c231a3b5177f12fff9db042dfa4091d8f2f26b3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"100m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"150Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}},"runtimeVolume":{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}}` |
| lightspeed.config | Configuration files mounted into the sidecar. By default, the chart creates ConfigMaps from bundled source files. Set existingConfigMap to use a pre-existing ConfigMap instead. | object | `{"profile":{"existingConfigMap":{"key":"","name":""}},"server":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}}` |
| lightspeed.config.profile | Python profile with prompt templates (rhdh-profile.py). | object | `{"existingConfigMap":{"key":"","name":""}}` |
| lightspeed.config.profile.existingConfigMap | Use an existing ConfigMap instead of the bundled default. | object | Created from bundled rhdh-profile.py |
| lightspeed.config.profile.existingConfigMap.key | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (rhdh-profile.py) if not set. | string | `""` |
| lightspeed.config.profile.existingConfigMap.name | Name of the existing ConfigMap. | string | `""` |
| lightspeed.config.server | Llama Stack server configuration (config.yaml). | object | `{"existingConfigMap":{"key":"","name":""}}` |
| lightspeed.config.server.existingConfigMap | Use an existing ConfigMap instead of the bundled default. | object | Created from bundled config.yaml |
| lightspeed.config.server.existingConfigMap.key | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (config.yaml) if not set. | string | `""` |
| lightspeed.config.server.existingConfigMap.name | Name of the existing ConfigMap. | string | `""` |
| lightspeed.config.stack | Lightspeed Core service configuration (lightspeed-stack.yaml). | object | `{"existingConfigMap":{"key":"","name":""}}` |
| lightspeed.config.stack.existingConfigMap | Use an existing ConfigMap instead of the bundled default. | object | Created from bundled lightspeed-stack.yaml |
| lightspeed.config.stack.existingConfigMap.key | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (lightspeed-stack.yaml) if not set. | string | `""` |
| lightspeed.config.stack.existingConfigMap.name | Name of the existing ConfigMap. | string | `""` |
| lightspeed.core | Lightspeed Core sidecar container. | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"0.5.3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}}` |
| lightspeed.core.argsOverride | Override the container's default args. Leave empty to use the image defaults. | list | `[]` |
| lightspeed.core.commandOverride | Override the container's default command. Leave empty to use the image entrypoint. | list | `[]` |
| lightspeed.core.extraArgs | Extra arguments appended after the default arguments. Ignored when argsOverride is set. | list | `[]` |
| lightspeed.existingSecret | Name of an existing Secret to inject via envFrom into the lightspeed-core container. If empty, no secret is mounted. Expected keys (all optional — only set the ones for the providers you use):   ENABLE_VLLM, VLLM_URL, VLLM_API_KEY, VLLM_MAX_TOKENS, VLLM_TLS_VERIFY,   ENABLE_OPENAI, OPENAI_API_KEY,   ENABLE_VERTEX_AI, VERTEX_AI_PROJECT, VERTEX_AI_LOCATION, GOOGLE_APPLICATION_CREDENTIALS,   ENABLE_OLLAMA, OLLAMA_URL,   ENABLE_VALIDATION, VALIDATION_PROVIDER, VALIDATION_MODEL_NAME,   LLAMA_STACK_LOGGING See files/lightspeed/secret.example.yaml for a reference template. | string | `""` |
| lightspeed.plugins | Lightspeed dynamic plugin packages. | list | `[{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-lightspeed:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-lightspeed-backend:{{ \"{{inherit}}\" }}"}]` |
| lightspeed.ragInit | RAG data bootstrap init container. | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"redhat-ai-dev/rag-content","tag":"release-1.10-lls-0.5.0-8c231a3b5177f12fff9db042dfa4091d8f2f26b3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"100m","memory":"500Mi"},"requests":{"cpu":"50m","memory":"150Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}}` |
| lightspeed.ragInit.argsOverride | Override the default arguments for the RAG init container. | list | `[]` |
| lightspeed.ragInit.commandOverride | Override the default command for the RAG init container. | list | `[]` |
| lightspeed.ragInit.extraArgs | Extra arguments appended after the default arguments. Ignored when argsOverride is set. | list | `[]` |
| lightspeed.runtimeVolume | Writable scratch volume for the sidecar (/tmp). | object | `{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}` |
| lightspeed.runtimeVolume.type | Volume type: "emptyDir" or "persistentVolumeClaim". | string | `"emptyDir"` |
| livenessProbe | Liveness probe configuration. | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/liveness","port":"backend","scheme":"HTTP"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":4}` |
| metrics | Prometheus metrics configuration. | object | `{"serviceMonitor":{"annotations":{},"enabled":false,"interval":"","labels":{},"path":"/metrics","port":"http-metrics"}}` |
| nameOverride | Override the chart name used in resource naming. | string | `""` |
| nodeSelector | Node labels for pod assignment. | object | `{}` |
| openshift | OpenShift-specific configuration. | object | `{"clusterRouterBase":"apps.example.com","route":{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}}` |
| openshift.clusterRouterBase | Cluster router base domain used to auto-generate the hostname. | string | `"apps.example.com"` |
| openshift.route | OpenShift Route configuration. | object | `{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}` |
| orchestrator | Orchestrator (Serverless workflows) configuration. | object | `{"enabled":false,"plugins":[{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-backend:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-form-widgets:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-scaffolder-backend-module-orchestrator:{{ \"{{inherit}}\" }}"}],"serverlessLogicOperator":{"enabled":true},"serverlessOperator":{"enabled":true},"sonataflowPlatform":{"dataIndex":{"image":{"digest":"","registry":"","repository":"","tag":""}},"dbCreationJob":{"activeDeadlineSeconds":120,"backoffLimit":2,"image":{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"},"ttlSecondsAfterFinished":null},"eventing":{"broker":{"name":"","namespace":""}},"externalDB":{"existingSecret":"","host":"","name":"","port":""},"jobService":{"image":{"digest":"","registry":"","repository":"","tag":""}},"monitoring":{"enabled":true},"resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"64Mi"}}}}` |
| orchestrator.sonataflowPlatform.dataIndex | SonataFlow Data Index service configuration. | object | `{"image":{"digest":"","registry":"","repository":"","tag":""}}` |
| orchestrator.sonataflowPlatform.dataIndex.image | Override the Data Index container image. If empty, the operator default is used. | object | `{"digest":"","registry":"","repository":"","tag":""}` |
| orchestrator.sonataflowPlatform.dbCreationJob | Database creation Job configuration. | object | `{"activeDeadlineSeconds":120,"backoffLimit":2,"image":{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"},"ttlSecondsAfterFinished":null}` |
| orchestrator.sonataflowPlatform.dbCreationJob.image | Container image for the create-db Job. | object | `{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"}` |
| orchestrator.sonataflowPlatform.externalDB | External database connection. Used when postgresql.enabled is false. | object | `{"existingSecret":"","host":"","name":"","port":""}` |
| orchestrator.sonataflowPlatform.externalDB.existingSecret | Name of a Secret containing POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD keys. | string | `""` |
| orchestrator.sonataflowPlatform.externalDB.host | Database host (used in JDBC URLs). | string | `""` |
| orchestrator.sonataflowPlatform.externalDB.name | Database name to connect to for the CREATE DATABASE command. | string | `""` |
| orchestrator.sonataflowPlatform.externalDB.port | Database port (used in JDBC URLs). | string | `""` |
| orchestrator.sonataflowPlatform.jobService | SonataFlow Job Service configuration. | object | `{"image":{"digest":"","registry":"","repository":"","tag":""}}` |
| orchestrator.sonataflowPlatform.jobService.image | Override the Job Service container image. If empty, the operator default is used. | object | `{"digest":"","registry":"","repository":"","tag":""}` |
| podAnnotations | Annotations to add to the pod. | object | `{}` |
| podDisruptionBudget | Pod Disruption Budget configuration. | object | `{"create":false,"maxUnavailable":1,"minAvailable":""}` |
| podLabels | Labels to add to the pod. | object | `{}` |
| podSecurityContext | Pod-level security context. | object | `{}` |
| postgresql | Built-in PostgreSQL database (bitnami subchart). | object | `{"auth":{"secretKeys":{"adminPasswordKey":"postgres-password","userPasswordKey":"password"}},"enabled":true,"image":{"digest":"","registry":"quay.io","repository":"fedora/postgresql-15","tag":"latest"},"postgresqlDataDir":"/var/lib/pgsql/data/userdata","primary":{"containerSecurityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":false},"extraEnvVars":[{"name":"POSTGRESQL_ADMIN_PASSWORD","valueFrom":{"secretKeyRef":{"key":"{{- include \"rhdh.postgresql.adminPasswordKey\" . }}","name":"{{- include \"rhdh.postgresql.secretName\" . }}"}}}],"persistence":{"enabled":true,"mountPath":"/var/lib/pgsql/data","size":"1Gi"},"podSecurityContext":{"enabled":false},"resources":{"limits":{"cpu":"250m","ephemeral-storage":"20Mi","memory":"1024Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}},"serviceBindings":{"enabled":true}}` |
| preInitContainers | Init containers to run BEFORE the system init containers (e.g. inject auth credentials before install-dynamic-plugins runs). | list | `[]` |
| readinessProbe | Readiness probe configuration. | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/readiness","port":"backend","scheme":"HTTP"},"periodSeconds":10,"successThreshold":2,"timeoutSeconds":4}` |
| replicaCount | Number of desired pods. | int | `1` |
| resources | Resource requests and limits for the main RHDH container. | object | `{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` |
| revisionHistoryLimit | Number of old ReplicaSets to retain. | int | `10` |
| service | Service configuration. | object | `{"annotations":{},"clusterIP":"","externalTrafficPolicy":"","extraPorts":[{"name":"http-metrics","port":9464,"targetPort":9464}],"ipFamilies":[],"ipFamilyPolicy":"","loadBalancerIP":"","loadBalancerSourceRanges":[],"nodePort":"","port":7007,"sessionAffinity":"","type":"ClusterIP"}` |
| service.extraPorts | Additional service ports. | list | `[{"name":"http-metrics","port":9464,"targetPort":9464}]` |
| service.ipFamilies | IP families for dual-stack networking. | list | `[]` |
| service.ipFamilyPolicy | IP family policy for dual-stack networking. | string | `""` |
| service.nodePort | Node port for NodePort/LoadBalancer service types (range 30000-32767). | string | `""` |
| serviceAccount | ServiceAccount configuration. | object | `{"annotations":{},"automount":true,"create":false,"labels":{},"name":""}` |
| serviceAccount.labels | Additional labels for the ServiceAccount. | object | `{}` |
| serviceAccount.name | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. | string | `""` |
| startupProbe | Startup probe configuration. Gives the application time to start before liveness/readiness probes kick in. | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/liveness","port":"backend","scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":4}` |
| strategy | Deployment update strategy. | object | `{}` |
| test | Test pod configuration for `helm test`. | object | `{"enabled":true,"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"quay.io","repository":"curl/curl","tag":"8.9.1"},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}}` |
| tolerations | Tolerations for pod assignment. | list | `[]` |
| topologySpreadConstraints | Topology spread constraints for pod scheduling. | list | `[]` |

## Opinionated RHDH deployment

This chart defaults to an opinionated deployment of Red Hat Developer Hub that provides users with a usable instance out of the box.

Features enabled by the default chart configuration:

1. Uses [rhdh](https://github.com/redhat-developer/rhdh/) that pre-loads a lot of useful plugins and features
2. Exposes a `Route` for easy access to the instance
3. Enables OpenShift-compatible PostgreSQL database storage
4. Built-in Lightspeed AI feature (enabled by default)
5. Dynamic plugins system with catalog index support

For additional instance features please consult the [documentation for `rhdh`](https://github.com/redhat-developer/rhdh/tree/main/showcase-docs).

Additional features can be enabled by extending the default configuration at:

```yaml
appConfig:
  # Inline app-config.yaml for the instance
extraEnv:
  # Additional environment variables (appended to system defaults)
extraVolumes:
  # Additional volumes (appended to system defaults)
extraVolumeMounts:
  # Additional volume mounts (appended to system defaults)
```

## Features

This charts defaults to using the [RHDH image](https://quay.io/rhdh-community/rhdh:next) that is OpenShift compatible:

```console
quay.io/rhdh-community/rhdh:next
```

### "Add, don't replace" pattern

System-required volumes, volume mounts, environment variables, init containers, and sidecar containers are hardcoded in the Deployment template. User-provided `extra*` values are always **appended** after the system defaults:

- `extraVolumes` — appended after dynamic-plugins-root, temp, npmcacache, extensions-catalog, etc.
- `extraVolumeMounts` — appended after dynamic-plugins-root, extensions, temp mounts
- `extraEnv` — appended after APP_CONFIG_backend_listen_port, BACKEND_SECRET, POSTGRES_* vars
- `extraInitContainers` — appended after install-dynamic-plugins and Lightspeed RAG init
- `extraContainers` — appended after the Lightspeed Core sidecar

This means you never need to copy system defaults to add your own entries.

If you need full control, the corresponding `*Override` fields (`envOverride`, `envFromOverride`, `commandOverride`, `argsOverride`) **replace** the system defaults entirely — nothing is auto-injected when an override is set.

### OpenShift Routes

This chart offers an OpenShift `Route` resource enabled by default. In order to use the chart without it, please set `openshift.route.enabled` to `false` and switch to the `Ingress` resource via `ingress` values.

Routes can be further configured via the `openshift.route` field.

To manually provide the Backstage pod with the right context, please add the following value:

```yaml
# values.yaml
openshift:
  clusterRouterBase: apps.example.com
```

> Tip: you can use `helm upgrade -i --set openshift.clusterRouterBase=apps.example.com ...` instead of a value file

Custom hosts are also supported via the following shorthand:

```yaml
# values.yaml
host: backstage.example.com
```

> Note: The hostname is derived from `host` if set, otherwise from `openshift.clusterRouterBase` (as `<release-name>-<chart-name>.<clusterRouterBase>`).
        When both fields are set, `host` takes precedence.
        These are templating shorthands. For full manual control, configure the values under the `openshift.route` key directly.

Any custom modifications to how backstage is being exposed may require additional changes to the `values.yaml`:

```yaml
# values.yaml
appConfig:
  app:
    baseUrl: 'https://{{- include "rhdh.hostname" . }}'
  backend:
    baseUrl: 'https://{{- include "rhdh.hostname" . }}'
    cors:
      origin: 'https://{{- include "rhdh.hostname" . }}'
```

### Catalog Index Configuration

The chart supports automatic plugin discovery through a catalog index OCI image. This is configured via `catalogIndex.image` (with `registry`, `repository`, and `tag` fields) and lets you use a pre-defined set of dynamic plugins.

You can also configure additional catalog index images via `catalogIndex.extraImages` to make plugins from other sources discoverable in the Extensions UI. Each extra image contributes catalog entities only (no `dynamic-plugins.default.yaml` handling).

For detailed information on configuring the catalog index, including how to override the default image, use a private registry, or add extra catalog index images, see the [Catalog Index Configuration documentation](../../docs/catalog-index-configuration.md).

### Lightspeed

Use `lightspeed.enabled` to enable or disable the built-in Lightspeed feature.

When enabled, the chart adds the default Lightspeed dynamic plugins, a RAG bootstrap init container, a Lightspeed Core sidecar listening on port `8080`, chart-generated ConfigMaps, a chart-generated Secret, and separate runtime and RAG data volumes. Override `lightspeed.plugins` for disconnected environments.

Use `lightspeed.runtimeVolume` to change the writable `/tmp` runtime storage between `emptyDir` and an existing PVC reference. The chart mounts that volume at `/tmp` so both generated temp files and `/tmp/data` remain writable. The `/rag-content` volume stays chart-managed and `emptyDir`-backed because the RAG assets are repopulated by the init container on each Pod start.

When using the built-in Lightspeed feature, do not also keep Lightspeed plugin packages in `dynamicPlugins.plugins`. Existing installations that previously configured Lightspeed there should remove those entries if the built-in defaults are sufficient, or move their custom package definitions to `lightspeed.plugins`; otherwise the rendered `dynamic-plugins.yaml` will contain duplicate Lightspeed plugin entries.

The Lightspeed Core sidecar loads the chart-created Lightspeed Secret as environment variables. If you update that Secret outside of Helm, Kubernetes does not guarantee that the Backstage Pod restarts automatically. Use a no-op `helm upgrade` or manually restart the Backstage deployment after changing the secret data.

### Vanilla Kubernetes compatibility mode

To deploy this chart on vanilla Kubernetes or any other non-OCP platform, apply the following changes. Note that further customizations might be required, depending on your exact Kubernetes setup:

```yaml
# values.yaml
host: # Specify your own Ingress host
openshift:
  route:
    enabled: false  # OpenShift Routes do not exist on vanilla Kubernetes
ingress:
  enabled: true  # Use Kubernetes Ingress instead of OpenShift Route
podSecurityContext:  # Vanilla Kubernetes doesn't feature OpenShift default SCCs with dynamic UIDs, adjust accordingly to the deployed image
  fsGroup: 1001
postgresql:
  primary:
    podSecurityContext:
      enabled: true
      fsGroup: 26
  volumePermissions:
    enabled: true
```

## Installing RHDH with Orchestrator on OpenShift

Orchestrator brings serverless workflows into Backstage, focusing on the journey for application migration to the cloud, onboarding developers, and user-made workflows of Backstage actions or external systems.
Orchestrator is a flavor of RHDH, and can be installed alongside RHDH in the same namespace and in the following way:

1. Have an admin install the [orchestrator-infra Helm Chart](https://github.com/redhat-developer/rhdh-chart/tree/main/charts/orchestrator-infra#readme), which will install the prerequisites required to deploy the Orchestrator-flavored RHDH. This process will include installing cluster-wide resources, so should be done with admin privileges:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install <release_name> redhat-developer/redhat-developer-hub-orchestrator-infra
```
2. Manually approve the Install Plans created by the chart, and wait for the Openshift Serverless and Openshift Serverless Logic Operators to be deployed. To do so, follow the post-install notes given by the chart, or see them [here](https://github.com/redhat-developer/rhdh-chart/blob/main/charts/orchestrator-infra/templates/NOTES.txt)
3. Install the `redhat-developer-hub` chart with Helm, enabling orchestrator, like so:

```
helm install <release_name> redhat-developer/redhat-developer-hub --set orchestrator.enabled=true
```
Note that serverlessLogicOperator, and serverlessOperator are enabled by default. They can be disabled together or seperately by passing the following flags:
`--set orchestrator.serverlessLogicOperator.enabled=false --set orchestrator.serverlessOperator.enabled=false`

### Enablement of Notifications Plugin

Workflows running with Orchestrator may use the Notifications plugin.
For this, you must enable the Notifications and Signals plugins.
To do so, add the plugins listed below to the `dynamicPlugins.plugins` list in your values file.
Do this before installing the Helm Chart, or upgrade the Helm release with the new values file.

```yaml
dynamicPlugins:
  plugins:
    - enabled: true
      package: "./dynamic-plugins/dist/backstage-plugin-notifications"
    - enabled: true
      package: "./dynamic-plugins/dist/backstage-plugin-signals"
    - enabled: true
      package: "./dynamic-plugins/dist/backstage-plugin-notifications-backend-dynamic"
    - enabled: true
      package: "./dynamic-plugins/dist/backstage-plugin-signals-backend-dynamic"
```
Enabling these plugins will allow you to receive notifications from workflows running with Orchestrator.

### Using Orchestrator while configuring an ExternalDB

To use orchestrator with an external DB, please follow the instructions in [our documentation](https://github.com/redhat-developer/rhdh-chart/blob/main/docs/external-db.md)
and populate the following values in the values.yaml:
```yaml
orchestrator:
  sonataflowPlatform:
    externalDB:
      existingSecret: <cred-secret>
      name: ""
      host: ""
      port: ""
```
The values for `host` and `port` should match the ones configured in the credential secret.

Please note that `externalDB.name` is the name of the user-configured existing database, not the database that the orchestrator and sonataflow resources will use.
A Job will run to create the 'sonataflow' database in the external database for the workflows to use.

Finally, install the Helm Chart (including [setting up the external DB](https://github.com/redhat-developer/rhdh-chart/blob/main/docs/external-db.md)):
```
helm install <release_name> redhat-developer/redhat-developer-hub \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.externalDB.existingSecret=<cred-secret> \
  --set orchestrator.sonataflowPlatform.externalDB.name=example \
  --set orchestrator.sonataflowPlatform.externalDB.host=example \
  --set orchestrator.sonataflowPlatform.externalDB.port=example
```
