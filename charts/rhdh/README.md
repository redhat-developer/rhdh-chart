# RHDH Helm Chart for OpenShift and Kubernetes

![Version: 2.1.0](https://img.shields.io/badge/Version-2.1.0-informational?style=flat-square)
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

helm install my-rhdh redhat-developer/redhat-developer-hub --version 2.1.0
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

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment. |
| appConfig | object | Default config with base URLs, CORS, database connection, and backend auth. | Inline Backstage app-config YAML. Rendered into a ConfigMap and mounted as app-config-from-configmap.yaml. |
| argsOverride | list | `[]` | Override the container arguments entirely. When set, system config arguments are NOT added automatically; you must include them yourself. |
| auth | object | `{"backend":{"enabled":true,"existingSecretRef":{"key":"backend-secret","name":""},"value":""}}` | Service-to-service authentication configuration. |
| auth.backend.enabled | bool | `true` | Enable backend service-to-service authentication. Generates a random secret unless existingSecretRef is set or value is provided. Disable if you inject the secret via extraEnvFrom or extraEnv instead. |
| auth.backend.existingSecretRef | object | `{"key":"backend-secret","name":""}` | Reference an existing Secret instead of generating one. When not set, the chart auto-generates a random token. |
| auth.backend.existingSecretRef.key | string | `"backend-secret"` | Key within the Secret that holds the backend auth token. |
| auth.backend.existingSecretRef.name | string | `""` | Name of the existing Secret. When empty, the chart generates one. |
| auth.backend.value | string | `""` | Use a specific value instead of generating one. |
| autoscaling | object | `{"enabled":false,"maxReplicas":3,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Horizontal Pod Autoscaler configuration. |
| catalogIndex | object | `{"extraImages":[],"image":{"digest":"","registry":"quay.io","repository":"rhdh/plugin-catalog-index","tag":"next"}}` | Catalog index configuration for automatic plugin discovery. |
| catalogIndex.extraImages | list | `[]` | Extra catalog index images for additional plugin discovery in the Extensions UI. Each item must include `registry`, `repository`, and `tag` fields; `name` and `digest` are optional. Only catalog entities are extracted from extra images (no `dynamic-plugins.default.yaml` handling). |
| commandOverride | list | `[]` | Override the container command. |
| commonAnnotations | object | `{}` | Annotations applied to ALL chart resources. |
| commonLabels | object | `{}` | Labels applied to ALL chart resources. |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the main RHDH container (not the Lightspeed Core sidecar or init containers). |
| deploymentAnnotations | object | `{}` | Annotations for the Deployment resource (not the pod). |
| dynamicPlugins | object | `{"includes":["dynamic-plugins.default.yaml"],"initContainer":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"resources":{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}},"securityContext":{}},"maxEntrySize":40000000,"plugins":[],"volume":{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"type":"ephemeral"}}` | Dynamic plugin system configuration. |
| dynamicPlugins.includes | list | `["dynamic-plugins.default.yaml"]` | Array of YAML files listing dynamic plugins to include. Relative paths are resolved from the working directory of the initContainer (`/opt/app-root/src`). |
| dynamicPlugins.initContainer | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"resources":{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}},"securityContext":{}}` | Configuration for the install-dynamic-plugins init container. |
| dynamicPlugins.initContainer.argsOverride | list | `[]` | Override the default arguments. Leave empty to use the defaults. |
| dynamicPlugins.initContainer.commandOverride | list | `[]` | Override the default command. Leave empty to use the default (./install-dynamic-plugins.sh /dynamic-plugins-root). |
| dynamicPlugins.initContainer.extraArgs | list | `[]` | Extra arguments appended after the default arguments. Ignored when argsOverride is set. |
| dynamicPlugins.initContainer.extraEnv | list | `[]` | Extra environment variables appended after the system env vars (NPM_CONFIG_USERCONFIG, MAX_ENTRY_SIZE, CATALOG_INDEX_IMAGE, etc.). |
| dynamicPlugins.initContainer.extraVolumeMounts | list | `[]` | Additional volume mounts appended after the system mounts (dynamic-plugins-root, npmrc, registry-auth, npmcacache, extensions-catalog, temp). |
| dynamicPlugins.initContainer.resources | object | `{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}}` | Resource requests and limits. |
| dynamicPlugins.initContainer.securityContext | object | Same as containerSecurityContext | Security context for the init container. |
| dynamicPlugins.maxEntrySize | int | `40000000` | Maximum uncompressed size (in bytes) of a single dynamic plugin entry. |
| dynamicPlugins.plugins | list | `[]` | List of dynamic plugins. Every item defines the plugin `package` as a NPM package spec or OCI reference. |
| dynamicPlugins.volume | object | `{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"type":"ephemeral"}` | Volume configuration for the dynamic plugins root directory. |
| dynamicPlugins.volume.emptyDir | object | `{}` | Raw Kubernetes emptyDir volume spec. Used when type is "emptyDir". |
| dynamicPlugins.volume.ephemeral | object | `{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""}` | Ephemeral volume configuration. Used when type is "ephemeral". The chart builds the full ephemeral.volumeClaimTemplate.spec from these fields. |
| dynamicPlugins.volume.ephemeral.accessModes | list | `["ReadWriteOnce"]` | Access modes for the ephemeral PVC. |
| dynamicPlugins.volume.ephemeral.resources | object | `{"requests":{"storage":"5Gi"}}` | Resource requests for the ephemeral PVC. |
| dynamicPlugins.volume.ephemeral.storageClassName | string | `""` | StorageClass for the ephemeral volume. When empty, uses global.defaultStorageClass or the cluster default. |
| dynamicPlugins.volume.pvc | object | `{"claimName":""}` | Raw Kubernetes persistentVolumeClaim volume spec. Used when type is "pvc". |
| dynamicPlugins.volume.type | string | `"ephemeral"` | Volume type: "ephemeral" (auto-provisioned PVC per pod), "emptyDir" (scratch space, lost on pod restart), or "pvc" (pre-existing PersistentVolumeClaim). |
| envFromOverride | list | `[]` | Override the container envFrom entirely. When set, extraEnvFrom is ignored. Accepts raw Kubernetes envFrom entries (configMapRef, secretRef, prefix). |
| envOverride | list | `[]` | Override the container environment variables entirely. When set, system env vars (BACKEND_SECRET, DB credentials, etc.) are NOT added automatically. |
| externalDatabase | object | `{"existingSecretRef":{"key":"password","name":""},"host":"","port":5432,"user":"postgres"}` | External database connection. Used when postgresql.enabled is false. See docs/external-db.md for TLS setup and privilege requirements. When both postgresql.enabled and externalDatabase.host are false/empty, the chart renders no database env vars (BYO configuration via extraEnv or appConfig). |
| externalDatabase.existingSecretRef | object | `{"key":"password","name":""}` | Reference to an existing Secret containing the database password. |
| externalDatabase.existingSecretRef.key | string | `"password"` | Key within the Secret that holds the password. |
| externalDatabase.existingSecretRef.name | string | `""` | Name of the existing Secret. |
| externalDatabase.host | string | `""` | External database hostname. |
| externalDatabase.port | int | `5432` | External database port. |
| externalDatabase.user | string | `"postgres"` | External database user. |
| extraAppConfig | list | `[]` | Additional app-config files from existing ConfigMaps. |
| extraArgs | list | `[]` | Extra arguments appended after the system config flags. |
| extraContainers | list | `[]` | Additional sidecar containers. These are ADDED to system containers (e.g. Lightspeed Core sidecar), never replacing them. |
| extraEnv | list | `[]` | Extra environment variables appended after the system env vars. |
| extraEnvFrom | list | `[]` | Extra envFrom entries appended to the container. Accepts raw Kubernetes envFrom entries (configMapRef, secretRef, prefix). |
| extraInitContainers | list | `[]` | Additional init containers. These are ADDED after system init containers (install-dynamic-plugins), never replacing them. |
| extraVolumeMounts | list | `[]` | Additional volume mounts to add to the main container. These are ADDED to system-required mounts, never replacing them. |
| extraVolumes | list | `[]` | Additional volumes to add to the pod. These are ADDED to system-required volumes (dynamic-plugins-root, temp, npmcacache, etc.), never replacing them. |
| fullnameOverride | string | `""` | Override the full resource name. |
| global | object | `{"defaultStorageClass":"","imagePullSecrets":[],"imageRegistry":""}` | Global parameters shared with bitnami subcharts (postgresql, common). |
| global.defaultStorageClass | string | `""` | Global default StorageClass for PVCs. |
| global.imagePullSecrets | list | `[]` | Global Docker registry secret names. |
| global.imageRegistry | string | `""` | Global Docker image registry. Overrides per-image registries for all containers. |
| host | string | `""` | Custom hostname. Overrides openshift.clusterRouterBase for URL generation. |
| hostAliases | list | `[]` | Host aliases for /etc/hosts entries. |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":[],"labels":{},"parentRefs":[],"rules":[]}` | Gateway API HTTPRoute configuration. |
| httpRoute.labels | object | `{}` | Additional labels for the HTTPRoute resource. |
| image | object | `{"digest":"","pullPolicy":"IfNotPresent","registry":"quay.io","repository":"rhdh-community/rhdh","tag":"next"}` | Container image configuration. |
| image.digest | string | `""` | Overrides the image tag with an image digest. |
| imagePullSecrets | list | `[]` | Secrets for pulling images from private registries (merged with global.imagePullSecrets). |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"{{ .Values.host }}","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Kubernetes Ingress configuration. |
| intelligentAssistant | object | `{"config":{"profile":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}},"core":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"dev-20260824-cbd182b"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}},"enabled":true,"existingSecret":"","okp":{"httpd":{"compressed":"true","encrypt":"false","serverName":"localhost"},"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"registry.redhat.io","repository":"offline-knowledge-portal/rhokp-rhel9","tag":"1.2.12-1788274041"},"imagePullSecrets":[],"ingress":{"annotations":{},"className":"","enabled":true,"host":"","tls":{"enabled":false,"secretName":""}},"replicaCount":1,"resources":{"limits":{"cpu":"2","memory":"4Gi"},"requests":{"cpu":"200m","memory":"2Gi"}},"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Allow","termination":"edge"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"type":"ClusterIP"},"solr":{"hostBind":"0.0.0.0","memory":"1g"}},"plugins":[{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend"}],"runtimeVolume":{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}}` | Built-in Intelligent Assistant feature configuration. |
| intelligentAssistant.config | object | `{"profile":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}}` | Configuration files mounted into the sidecar. By default, the chart creates ConfigMaps from bundled source files. Set existingConfigMap to use a pre-existing ConfigMap instead. |
| intelligentAssistant.config.profile | object | `{"existingConfigMap":{"key":"","name":""}}` | Python profile with prompt templates (rhdh-profile.py). |
| intelligentAssistant.config.profile.existingConfigMap | object | Created from bundled rhdh-profile.py | Use an existing ConfigMap instead of the bundled default. |
| intelligentAssistant.config.profile.existingConfigMap.key | string | `""` | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (rhdh-profile.py) if not set. |
| intelligentAssistant.config.profile.existingConfigMap.name | string | `""` | Name of the existing ConfigMap. |
| intelligentAssistant.config.stack | object | `{"existingConfigMap":{"key":"","name":""}}` | Lightspeed Core service configuration (lightspeed-stack.yaml). |
| intelligentAssistant.config.stack.existingConfigMap | object | Created from bundled lightspeed-stack.yaml | Use an existing ConfigMap instead of the bundled default. |
| intelligentAssistant.config.stack.existingConfigMap.key | string | `""` | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (lightspeed-stack.yaml) if not set. |
| intelligentAssistant.config.stack.existingConfigMap.name | string | `""` | Name of the existing ConfigMap. |
| intelligentAssistant.core | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"dev-20260824-cbd182b"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}}` | Lightspeed Core sidecar container. |
| intelligentAssistant.core.argsOverride | list | `[]` | Override the container's default args. Leave empty to use the chart defaults. |
| intelligentAssistant.core.commandOverride | list | `[]` | Override the container's default command. Leave empty to use the image entrypoint. |
| intelligentAssistant.core.extraArgs | list | `[]` | Extra arguments appended after the default arguments. Ignored when argsOverride is set. |
| intelligentAssistant.existingSecret | string | `""` | Name of an existing Secret that supplies credentials and settings to the lightspeed-core container. Configure the provider itself in lightspeed-stack.yaml. If empty, no Secret is loaded. Expected keys (all optional; include only keys used by the configured provider):   VLLM_URL, VLLM_API_KEY, VLLM_MAX_TOKENS, VLLM_TLS_VERIFY,   OPENAI_API_KEY,   VERTEX_AI_PROJECT, VERTEX_AI_LOCATION, GOOGLE_APPLICATION_CREDENTIALS,   ENABLE_VALIDATION, VALIDATION_PROVIDER, VALIDATION_MODEL_NAME Set ENABLE_VALIDATION to question_validity to enable validation. GOOGLE_APPLICATION_CREDENTIALS must be a path to a credentials file mounted in the sidecar. See files/intelligent-assistant/secret.example.yaml for a reference template. |
| intelligentAssistant.okp | object | `{"httpd":{"compressed":"true","encrypt":"false","serverName":"localhost"},"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"registry.redhat.io","repository":"offline-knowledge-portal/rhokp-rhel9","tag":"1.2.12-1788274041"},"imagePullSecrets":[],"ingress":{"annotations":{},"className":"","enabled":true,"host":"","tls":{"enabled":false,"secretName":""}},"replicaCount":1,"resources":{"limits":{"cpu":"2","memory":"4Gi"},"requests":{"cpu":"200m","memory":"2Gi"}},"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Allow","termination":"edge"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"type":"ClusterIP"},"solr":{"hostBind":"0.0.0.0","memory":"1g"}}` | OKP (Offline Knowledge Portal) configuration. Deploys an OKP instance for document retrieval when Intelligent Assistant is enabled. |
| intelligentAssistant.okp.imagePullSecrets | list | `[]` | Image pull secrets for the OKP container image. Required on vanilla Kubernetes to authenticate with registry.redhat.io. Not needed on OpenShift where the cluster-wide pull secret covers Red Hat registries. |
| intelligentAssistant.plugins | list | `[{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend"}]` | Intelligent Assistant dynamic plugin packages. |
| intelligentAssistant.runtimeVolume | object | `{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}` | Writable scratch volume for the sidecar (/tmp). |
| intelligentAssistant.runtimeVolume.type | string | `"emptyDir"` | Volume type: "emptyDir" or "persistentVolumeClaim". |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/liveness","port":"backend","scheme":"HTTP"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":4}` | Liveness probe configuration. |
| metrics | object | `{"serviceMonitor":{"annotations":{},"enabled":false,"interval":"","labels":{},"path":"/metrics","port":"http-metrics"}}` | Prometheus metrics configuration. |
| nameOverride | string | `""` | Override the chart name used in resource naming. |
| nodeSelector | object | `{}` | Node labels for pod assignment. |
| openshift | object | `{"clusterRouterBase":"apps.example.com","route":{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}}` | OpenShift-specific configuration. |
| openshift.clusterRouterBase | string | `"apps.example.com"` | Cluster router base domain used to auto-generate the hostname. |
| openshift.route | object | `{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}` | OpenShift Route configuration. |
| orchestrator | object | `{"enabled":false,"plugins":[{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-backend:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-form-widgets:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator:{{ \"{{inherit}}\" }}"},{"enabled":true,"package":"oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-scaffolder-backend-module-orchestrator:{{ \"{{inherit}}\" }}"}],"serverlessLogicOperator":{"enabled":true},"serverlessOperator":{"enabled":true},"sonataflowPlatform":{"dataIndex":{"image":{"digest":"","registry":"","repository":"","tag":""}},"dbCreationJob":{"activeDeadlineSeconds":120,"backoffLimit":2,"image":{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"},"ttlSecondsAfterFinished":null},"eventing":{"broker":{"name":"","namespace":""}},"externalDB":{"existingSecret":"","host":"","name":"","port":""},"jobService":{"image":{"digest":"","registry":"","repository":"","tag":""}},"monitoring":{"enabled":true},"resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"64Mi"}}}}` | Orchestrator (Serverless workflows) configuration. |
| orchestrator.sonataflowPlatform.dataIndex | object | `{"image":{"digest":"","registry":"","repository":"","tag":""}}` | SonataFlow Data Index service configuration. |
| orchestrator.sonataflowPlatform.dataIndex.image | object | `{"digest":"","registry":"","repository":"","tag":""}` | Override the Data Index container image. If empty, the operator default is used. |
| orchestrator.sonataflowPlatform.dbCreationJob | object | `{"activeDeadlineSeconds":120,"backoffLimit":2,"image":{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"},"ttlSecondsAfterFinished":null}` | Database creation Job configuration. |
| orchestrator.sonataflowPlatform.dbCreationJob.image | object | `{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"}` | Container image for the create-db Job. |
| orchestrator.sonataflowPlatform.externalDB | object | `{"existingSecret":"","host":"","name":"","port":""}` | External database connection. Used when postgresql.enabled is false. |
| orchestrator.sonataflowPlatform.externalDB.existingSecret | string | `""` | Name of a Secret containing POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD keys. |
| orchestrator.sonataflowPlatform.externalDB.host | string | `""` | Database host (used in JDBC URLs). |
| orchestrator.sonataflowPlatform.externalDB.name | string | `""` | Database name to connect to for the CREATE DATABASE command. |
| orchestrator.sonataflowPlatform.externalDB.port | string | `""` | Database port (used in JDBC URLs). |
| orchestrator.sonataflowPlatform.jobService | object | `{"image":{"digest":"","registry":"","repository":"","tag":""}}` | SonataFlow Job Service configuration. |
| orchestrator.sonataflowPlatform.jobService.image | object | `{"digest":"","registry":"","repository":"","tag":""}` | Override the Job Service container image. If empty, the operator default is used. |
| podAnnotations | object | `{}` | Annotations to add to the pod. |
| podDisruptionBudget | object | `{"create":false,"maxUnavailable":1,"minAvailable":""}` | Pod Disruption Budget configuration. |
| podLabels | object | `{}` | Labels to add to the pod. |
| podSecurityContext | object | `{}` | Pod-level security context. |
| postgresql | object | `{"auth":{"secretKeys":{"adminPasswordKey":"postgres-password","userPasswordKey":"password"}},"enabled":true,"image":{"digest":"","registry":"quay.io","repository":"fedora/postgresql-15","tag":"latest"},"postgresqlDataDir":"/var/lib/pgsql/data/userdata","primary":{"containerSecurityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":false},"extraEnvVars":[{"name":"POSTGRESQL_ADMIN_PASSWORD","valueFrom":{"secretKeyRef":{"key":"{{- include \"rhdh.postgresql.adminPasswordKey\" . }}","name":"{{- include \"rhdh.postgresql.secretName\" . }}"}}}],"persistence":{"enabled":true,"mountPath":"/var/lib/pgsql/data","size":"1Gi"},"podSecurityContext":{"enabled":false},"resources":{"limits":{"cpu":"250m","ephemeral-storage":"20Mi","memory":"1024Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}},"serviceBindings":{"enabled":true}}` | Built-in PostgreSQL database (bitnami subchart). |
| preInitContainers | list | `[]` | Init containers to run BEFORE the system init containers (e.g. inject auth credentials before install-dynamic-plugins runs). |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/readiness","port":"backend","scheme":"HTTP"},"periodSeconds":10,"successThreshold":2,"timeoutSeconds":4}` | Readiness probe configuration. |
| replicaCount | int | `1` | Number of desired pods. |
| resources | object | `{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the main RHDH container. |
| revisionHistoryLimit | int | `10` | Number of old ReplicaSets to retain. |
| service | object | `{"annotations":{},"clusterIP":"","externalTrafficPolicy":"","extraPorts":[{"name":"http-metrics","port":9464,"targetPort":9464}],"ipFamilies":[],"ipFamilyPolicy":"","loadBalancerIP":"","loadBalancerSourceRanges":[],"nodePort":"","port":7007,"sessionAffinity":"","type":"ClusterIP"}` | Service configuration. |
| service.extraPorts | list | `[{"name":"http-metrics","port":9464,"targetPort":9464}]` | Additional service ports. |
| service.ipFamilies | list | `[]` | IP families for dual-stack networking. |
| service.ipFamilyPolicy | string | `""` | IP family policy for dual-stack networking. |
| service.nodePort | string | `""` | Node port for NodePort/LoadBalancer service types (range 30000-32767). |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":false,"labels":{},"name":""}` | ServiceAccount configuration. |
| serviceAccount.labels | object | `{}` | Additional labels for the ServiceAccount. |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |
| startupProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/liveness","port":"backend","scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":20,"successThreshold":1,"timeoutSeconds":4}` | Startup probe configuration. Gives the application time to start before liveness/readiness probes kick in. |
| strategy | object | `{}` | Deployment update strategy. |
| test | object | `{"enabled":true,"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"quay.io","repository":"curl/curl","tag":"8.21.0"},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}}` | Test pod configuration for `helm test`. |
| tolerations | list | `[]` | Tolerations for pod assignment. |
| topologySpreadConstraints | list | `[]` | Topology spread constraints for pod scheduling. |

## Opinionated RHDH deployment

This chart defaults to an opinionated deployment of Red Hat Developer Hub that provides users with a usable instance out of the box.

Features enabled by the default chart configuration:

1. Uses [rhdh](https://github.com/redhat-developer/rhdh/) that pre-loads a lot of useful plugins and features
2. Exposes a `Route` for easy access to the instance
3. Enables OpenShift-compatible PostgreSQL database storage
4. Built-in Intelligent Assistant feature (enabled by default)
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
- `extraInitContainers` — appended after install-dynamic-plugins and Intelligent Assistant RAG init
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

### Intelligent Assistant

Use `intelligentAssistant.enabled` to enable or disable the built-in Intelligent Assistant feature.

When enabled, the chart adds the default Intelligent Assistant dynamic plugins (`ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant` and `ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend`), a RAG bootstrap init container, a Lightspeed Core sidecar listening on port `8080`, chart-generated ConfigMaps, and separate runtime and RAG data volumes. Override `intelligentAssistant.plugins` for disconnected environments. Plugin app-config uses the `intelligent-assistant:` namespace (not `lightspeed:`).

The bundled `lightspeed-stack.yaml` does not enable an LLM inference provider. Create a provider-enabled stack in a ConfigMap and reference it with `intelligentAssistant.config.stack.existingConfigMap`. Supply that provider's credentials and settings with `intelligentAssistant.existingSecret`; the chart does not create the Secret.

This is a breaking change from chart 1.x: rename `lightspeed:` to `intelligentAssistant:` in your values. Chart-generated ConfigMaps are named `{fullname}-ia-{stack,profile}` instead of `{fullname}-lightspeed-*`, so Helm replaces those objects on upgrade. The `ia` infix is used because Kubernetes names are limited to 63 characters.

Chart 2.1.0 removes `intelligentAssistant.config.server` and the separate Llama Stack `config.yaml`. Remove the `server` entry from existing values. Move custom Llama Stack settings into the `lightspeed-stack.yaml` supplied through `intelligentAssistant.config.stack.existingConfigMap`.

Use `intelligentAssistant.runtimeVolume` to change the writable `/tmp` runtime storage between `emptyDir` and an existing PVC reference. The chart mounts that volume at `/tmp` so both generated temp files and `/tmp/data` remain writable. The `/rag-content` volume stays chart-managed and `emptyDir`-backed because the RAG assets are repopulated by the init container on each Pod start.

When using the built-in Intelligent Assistant feature, do not also keep those plugin packages in `dynamicPlugins.plugins`. Existing installations that previously configured Lightspeed or Intelligent Assistant there should remove those entries if the built-in defaults are sufficient, or move their custom package definitions to `intelligentAssistant.plugins`; otherwise the rendered `dynamic-plugins.yaml` will contain duplicate plugin entries.

The Lightspeed Core sidecar loads `intelligentAssistant.existingSecret` as environment variables. If you update that Secret outside of Helm, Kubernetes does not guarantee that the Backstage Pod restarts automatically. Use a no-op `helm upgrade` or manually restart the Backstage deployment after changing the secret data.

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
