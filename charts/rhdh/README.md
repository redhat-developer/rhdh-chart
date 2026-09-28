# RHDH Helm Chart for OpenShift and Kubernetes

![Version: 3.4.1](https://img.shields.io/badge/Version-3.4.1-informational?style=flat-square)
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

helm install my-rhdh redhat-developer/redhat-developer-hub --version 3.4.1
```

## Introduction

This chart bootstraps a [Red Hat Developer Hub](https://developers.redhat.com/rhdh) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Unlike the legacy `backstage` chart, this chart owns all Kubernetes templates directly (Deployment or StatefulSet, Service, ConfigMap, etc.) without depending on an upstream Backstage subchart. The Backstage pod specification is shared across workload kinds via a common template. It uses an **"add, don't replace"** pattern: system-required volumes, volume mounts, environment variables, and init containers are hardcoded in the pod template, while user-provided values (`extraVolumes`, `extraVolumeMounts`, `extraEnv`, `extraInitContainers`, `extraContainers`) are always appended — never replacing the defaults.

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

If you are upgrading from the legacy `backstage` chart (used in RHDH 1.y), the new `redhat-developer-hub` chart is a clean break. The values structure has changed significantly — all `global.*` and `upstream.backstage.*` nesting has been flattened to root-level keys. You cannot pass your old values file directly to the new chart; you must migrate your values first, then `helm upgrade` the release in place.

See the [Migration guide](docs/migration-from-backstage-chart.md) for step-by-step instructions and a complete values mapping reference.

## Requirements

Kubernetes: `>= 1.31.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | common | 2.41.0 |
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
| dynamicPlugins | object | `{"includes":["dynamic-plugins.default.yaml"],"initContainer":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"resources":{"limits":{"cpu":"1000m","ephemeral-storage":"5Gi","memory":"2.5Gi"},"requests":{"cpu":"250m","memory":"256Mi"}},"securityContext":{}},"maxEntrySize":40000000,"plugins":[],"volume":{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"statefulSetPVC":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"type":"ephemeral"}}` | Dynamic plugin system configuration. |
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
| dynamicPlugins.volume | object | `{"emptyDir":{},"ephemeral":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"pvc":{"claimName":""},"statefulSetPVC":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""},"type":"ephemeral"}` | Volume configuration for the dynamic plugins root directory. |
| dynamicPlugins.volume.emptyDir | object | `{}` | Raw Kubernetes emptyDir volume spec. Used when type is "emptyDir". |
| dynamicPlugins.volume.ephemeral | object | `{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""}` | Ephemeral volume configuration. Used when type is "ephemeral". The chart builds the full ephemeral.volumeClaimTemplate.spec from these fields. |
| dynamicPlugins.volume.ephemeral.accessModes | list | `["ReadWriteOnce"]` | Access modes for the ephemeral PVC. |
| dynamicPlugins.volume.ephemeral.resources | object | `{"requests":{"storage":"5Gi"}}` | Resource requests for the ephemeral PVC. |
| dynamicPlugins.volume.ephemeral.storageClassName | string | `""` | StorageClass for the ephemeral volume. When empty, uses global.defaultStorageClass or the cluster default. |
| dynamicPlugins.volume.pvc | object | `{"claimName":""}` | Raw Kubernetes persistentVolumeClaim volume spec. Used when type is "pvc". |
| dynamicPlugins.volume.statefulSetPVC | object | `{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}},"storageClassName":""}` | StatefulSet-owned PVC volume spec. Used when type is "statefulSetPVC". |
| dynamicPlugins.volume.statefulSetPVC.accessModes | list | `["ReadWriteOnce"]` | Access modes for the StatefulSet-owned PVC. |
| dynamicPlugins.volume.statefulSetPVC.resources | object | `{"requests":{"storage":"5Gi"}}` | Resource requests for the StatefulSet-owned PVC. |
| dynamicPlugins.volume.statefulSetPVC.storageClassName | string | `""` | StorageClass. When empty, uses global.defaultStorageClass or the cluster default. |
| dynamicPlugins.volume.type | string | `"ephemeral"` | Volume type: "ephemeral" (auto-provisioned PVC per pod), "emptyDir" (scratch space, lost on pod restart), "pvc" (pre-existing PersistentVolumeClaim), or "statefulSetPVC" (StatefulSet volumeClaimTemplate; requires workload.kind=StatefulSet). |
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
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release (rendered through `tpl`). Each element is a complete Kubernetes manifest; Helm template expressions are supported. |
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
| intelligentAssistant | object | `{"config":{"profile":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}},"core":{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"0.7.0rc3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}},"enabled":true,"existingSecret":"","okp":{"affinity":{},"enabled":false,"httpd":{"compressed":"true","encrypt":"false","serverName":"localhost"},"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"registry.redhat.io","repository":"offline-knowledge-portal/rhokp-rhel9","tag":"1.2.12-1788274041"},"imagePullSecrets":[],"ingress":{"annotations":{},"className":"","enabled":true,"host":"","tls":{"enabled":false,"secretName":""}},"livenessProbe":{"initialDelaySeconds":30,"periodSeconds":30},"nodeSelector":{},"readinessProbe":{"initialDelaySeconds":10,"periodSeconds":10},"replicaCount":1,"resources":{"limits":{"cpu":"2","memory":"4Gi"},"requests":{"cpu":"200m","memory":"2Gi"}},"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Redirect","termination":"edge"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"type":"ClusterIP"},"solr":{"hostBind":"0.0.0.0","memory":"1g"},"tolerations":[],"topologySpreadConstraints":[]},"plugins":[{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend"}],"runtimeVolume":{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}}` | Built-in Intelligent Assistant feature configuration. |
| intelligentAssistant.config | object | `{"profile":{"existingConfigMap":{"key":"","name":""}},"stack":{"existingConfigMap":{"key":"","name":""}}}` | Configuration files mounted into the sidecar. By default, the chart creates ConfigMaps from bundled source files. Set existingConfigMap to use a pre-existing ConfigMap instead. |
| intelligentAssistant.config.profile | object | `{"existingConfigMap":{"key":"","name":""}}` | Python profile with prompt templates (rhdh-profile.py). |
| intelligentAssistant.config.profile.existingConfigMap | object | Created from bundled rhdh-profile.py | Use an existing ConfigMap instead of the bundled default. |
| intelligentAssistant.config.profile.existingConfigMap.key | string | `""` | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (rhdh-profile.py) if not set. |
| intelligentAssistant.config.profile.existingConfigMap.name | string | `""` | Name of the existing ConfigMap. |
| intelligentAssistant.config.stack | object | `{"existingConfigMap":{"key":"","name":""}}` | Lightspeed Core service configuration (lightspeed-stack.yaml). |
| intelligentAssistant.config.stack.existingConfigMap | object | Created from bundled lightspeed-stack.yaml | Use an existing ConfigMap instead of the bundled default. |
| intelligentAssistant.config.stack.existingConfigMap.key | string | `""` | Key within the ConfigMap that holds the file content. Defaults to the bundled filename (lightspeed-stack.yaml) if not set. |
| intelligentAssistant.config.stack.existingConfigMap.name | string | `""` | Name of the existing ConfigMap. |
| intelligentAssistant.core | object | `{"argsOverride":[],"commandOverride":[],"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"image":{"digest":"","registry":"quay.io","repository":"lightspeed-core/lightspeed-stack","tag":"0.7.0rc3"},"imagePullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}}` | Lightspeed Core sidecar container. |
| intelligentAssistant.core.argsOverride | list | `[]` | Override the container's default args. Leave empty to use the chart defaults. |
| intelligentAssistant.core.commandOverride | list | `[]` | Override the container's default command. Leave empty to use the image entrypoint. |
| intelligentAssistant.core.extraArgs | list | `[]` | Extra arguments appended after the default arguments. Ignored when argsOverride is set. |
| intelligentAssistant.existingSecret | string | `""` | Name of an existing Secret that supplies credentials and settings to the lightspeed-core container. Configure the provider itself in lightspeed-stack.yaml. If empty, no Secret is loaded. Expected keys (all optional; include only keys used by the configured provider):   VLLM_URL, VLLM_API_KEY, VLLM_MAX_TOKENS, VLLM_TLS_VERIFY,   OPENAI_API_KEY,   VERTEX_AI_PROJECT, VERTEX_AI_LOCATION, GOOGLE_APPLICATION_CREDENTIALS,   ENABLE_VALIDATION, VALIDATION_PROVIDER, VALIDATION_MODEL_NAME Set ENABLE_VALIDATION to question_validity to enable validation. GOOGLE_APPLICATION_CREDENTIALS must be a path to a credentials file mounted in the sidecar. See files/intelligent-assistant/secret.example.yaml for a reference template. |
| intelligentAssistant.okp | object | `{"affinity":{},"enabled":false,"httpd":{"compressed":"true","encrypt":"false","serverName":"localhost"},"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"registry.redhat.io","repository":"offline-knowledge-portal/rhokp-rhel9","tag":"1.2.12-1788274041"},"imagePullSecrets":[],"ingress":{"annotations":{},"className":"","enabled":true,"host":"","tls":{"enabled":false,"secretName":""}},"livenessProbe":{"initialDelaySeconds":30,"periodSeconds":30},"nodeSelector":{},"readinessProbe":{"initialDelaySeconds":10,"periodSeconds":10},"replicaCount":1,"resources":{"limits":{"cpu":"2","memory":"4Gi"},"requests":{"cpu":"200m","memory":"2Gi"}},"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Redirect","termination":"edge"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"type":"ClusterIP"},"solr":{"hostBind":"0.0.0.0","memory":"1g"},"tolerations":[],"topologySpreadConstraints":[]}` | OKP (Offline Knowledge Portal) configuration. Deploys an OKP instance for RHDH documentation retrieval when explicitly enabled. The image is large and can significantly increase initial installation time. |
| intelligentAssistant.okp.affinity | object | `{}` | Pod scheduling: affinity rules for the OKP pod. |
| intelligentAssistant.okp.enabled | bool | `false` | Enable OKP-backed RHDH documentation retrieval. Disabled by default on all platforms. |
| intelligentAssistant.okp.imagePullSecrets | list | `[]` | Image pull secrets for the OKP container image. Required on vanilla Kubernetes to authenticate with registry.redhat.io. Not needed on OpenShift where the cluster-wide pull secret covers Red Hat registries. |
| intelligentAssistant.okp.livenessProbe | object | `{"initialDelaySeconds":30,"periodSeconds":30}` | Liveness probe configuration for the OKP container. |
| intelligentAssistant.okp.nodeSelector | object | `{}` | Pod scheduling: node selector for the OKP pod. |
| intelligentAssistant.okp.readinessProbe | object | `{"initialDelaySeconds":10,"periodSeconds":10}` | Readiness probe configuration for the OKP container. |
| intelligentAssistant.okp.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | OKP container security context. readOnlyRootFilesystem is not set because Solr (Lucene) writes a lock file into its pre-built index directory at runtime. |
| intelligentAssistant.okp.tolerations | list | `[]` | Pod scheduling: tolerations for the OKP pod. |
| intelligentAssistant.okp.topologySpreadConstraints | list | `[]` | Pod scheduling: topology spread constraints for the OKP pod. |
| intelligentAssistant.plugins | list | `[{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend"}]` | Intelligent Assistant dynamic plugin packages. |
| intelligentAssistant.runtimeVolume | object | `{"emptyDir":{},"persistentVolumeClaim":{},"type":"emptyDir"}` | Writable scratch volume for the sidecar (/tmp). |
| intelligentAssistant.runtimeVolume.type | string | `"emptyDir"` | Volume type: "emptyDir" or "persistentVolumeClaim". |
| lifecycleHooks | object | `{}` | Lifecycle hooks for the main RHDH container. Ref: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/ |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/.backstage/health/v1/liveness","port":"backend","scheme":"HTTP"},"periodSeconds":10,"successThreshold":1,"timeoutSeconds":4}` | Liveness probe configuration. |
| metrics | object | `{"serviceMonitor":{"annotations":{},"enabled":false,"interval":"","labels":{},"path":"/metrics","port":"http-metrics"}}` | Prometheus metrics configuration. |
| nameOverride | string | `"developer-hub"` | Override the chart name used in resource naming. |
| nodeSelector | object | `{}` | Node labels for pod assignment. |
| openshift | object | `{"clusterRouterBase":"apps.example.com","route":{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","targetPort":"http-backend","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}}` | OpenShift-specific configuration. |
| openshift.clusterRouterBase | string | `"apps.example.com"` | Cluster router base domain used to auto-generate the hostname. |
| openshift.route | object | `{"annotations":{},"enabled":true,"host":"{{ .Values.host }}","path":"/","targetPort":"http-backend","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}` | OpenShift Route configuration. |
| orchestrator | object | `{"enabled":false,"plugins":[{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-orchestrator-backend"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-orchestrator-form-widgets"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-orchestrator"},{"enabled":true,"package":"ref://red-hat-developer-hub-backstage-plugin-scaffolder-backend-module-orchestrator"}],"serverlessLogicOperator":{"enabled":true},"serverlessOperator":{"enabled":true},"sonataflowPlatform":{"dataIndex":{"image":{"digest":"","registry":"","repository":"","tag":""}},"dbCreationJob":{"activeDeadlineSeconds":120,"backoffLimit":2,"image":{"digest":"{{ .Values.postgresql.image.digest }}","registry":"{{ .Values.postgresql.image.registry }}","repository":"{{ .Values.postgresql.image.repository }}","tag":"{{ .Values.postgresql.image.tag }}"},"ttlSecondsAfterFinished":null},"eventing":{"broker":{"name":"","namespace":""}},"externalDB":{"existingSecret":"","host":"","name":"","port":""},"jobService":{"image":{"digest":"","registry":"","repository":"","tag":""}},"monitoring":{"enabled":true},"resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"64Mi"}}}}` | Orchestrator (Serverless workflows) configuration. |
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
| postgresql | object | `{"auth":{"secretKeys":{"adminPasswordKey":"postgres-password","userPasswordKey":"password"}},"enabled":true,"image":{"digest":"","registry":"quay.io","repository":"fedora/postgresql-18","tag":"latest"},"postgresqlDataDir":"/var/lib/pgsql/data/userdata","primary":{"containerSecurityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":false},"extraEnvVars":[{"name":"POSTGRESQL_ADMIN_PASSWORD","valueFrom":{"secretKeyRef":{"key":"{{- include \"rhdh.postgresql.adminPasswordKey\" . }}","name":"{{- include \"rhdh.postgresql.secretName\" . }}"}}}],"networkPolicy":{"enabled":false},"persistence":{"enabled":true,"mountPath":"/var/lib/pgsql/data","size":"1Gi"},"podSecurityContext":{"enabled":false},"resources":{"limits":{"cpu":"250m","ephemeral-storage":"20Mi","memory":"1024Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}},"readReplicas":{"networkPolicy":{"enabled":false}},"serviceBindings":{"enabled":true}}` | Built-in PostgreSQL database (bitnami subchart). |
| preInitContainers | list | `[]` | Init containers to run BEFORE the system init containers (e.g. inject auth credentials before install-dynamic-plugins runs). |
| priorityClassName | string | `""` | Priority class name for pod scheduling. Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/ |
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
| terminationGracePeriodSeconds | string | `nil` | Duration in seconds the pod needs to terminate gracefully before being force killed. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination |
| test | object | `{"enabled":true,"image":{"digest":"","pullPolicy":"IfNotPresent","registry":"quay.io","repository":"curl/curl","tag":"8.22.0"},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}}` | Test pod configuration for `helm test`. |
| tolerations | list | `[]` | Tolerations for pod assignment. |
| topologySpreadConstraints | list | `[]` | Topology spread constraints for pod scheduling. |
| workload | object | `{"kind":"Deployment","statefulSet":{"annotations":{},"extraVolumeClaimTemplates":[],"persistentVolumeClaimRetentionPolicy":{},"podManagementPolicy":"","serviceName":"","updateStrategy":{}}}` | Kubernetes workload controller for Backstage pod. |
| workload.kind | string | `"Deployment"` | Workload kind: Deployment (default) or StatefulSet. |
| workload.statefulSet.annotations | object | `{}` | Annotations on the StatefulSet resource. |
| workload.statefulSet.extraVolumeClaimTemplates | list | `[]` | Extra volumeClaimTemplates appended after the chart-managed dynamic-plugins-root claim (when type=statefulSetPVC). |
| workload.statefulSet.persistentVolumeClaimRetentionPolicy | object | `{}` | Optional PVC retention policy for the StatefulSet. |
| workload.statefulSet.podManagementPolicy | string | `""` | Pod management policy for the StatefulSet. |
| workload.statefulSet.serviceName | string | `""` | service name for the StatefulSet. Defaults to headless when empty. Service ({fullname}-headless) must match an existing service. |
| workload.statefulSet.updateStrategy | object | `{}` | StatefulSet update strategy. |

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
extraDeploy:
  # Additional Kubernetes resources deployed with the release
```

## Features

This charts defaults to using the [RHDH image](https://quay.io/rhdh-community/rhdh:next) that is OpenShift compatible:

```console
quay.io/rhdh-community/rhdh:next
```

### "Add, don't replace" pattern

System-required volumes, volume mounts, environment variables, init containers, and sidecar containers are hardcoded in the Backstage pod template (used by both Deployment and StatefulSet). User-provided `extra*` values are always **appended** after the system defaults:

- `extraVolumes` — appended after dynamic-plugins-root, temp, npmcacache, extensions-catalog, etc.
- `extraVolumeMounts` — appended after dynamic-plugins-root, extensions, temp mounts
- `extraEnv` — appended after APP_CONFIG_backend_listen_port, BACKEND_SECRET, POSTGRES_* vars
- `extraInitContainers` — appended after install-dynamic-plugins and Intelligent Assistant RAG init
- `extraContainers` — appended after the Lightspeed Core sidecar

This means you never need to copy system defaults to add your own entries.

If you need full control, the corresponding `*Override` fields (`envOverride`, `envFromOverride`, `commandOverride`, `argsOverride`) **replace** the system defaults entirely — nothing is auto-injected when an override is set.

### Workload kind (Deployment or StatefulSet)

By default, the chart creates a Kubernetes **Deployment** (`workload.kind: Deployment`). To use a **StatefulSet** instead:

```yaml
# values.yaml
workload:
  kind: StatefulSet
```

Both kinds render the **same** Backstage pod (containers, volumes, probes, dynamic plugins, Intelligent Assistant, init containers). Only the workload controller changes; the pod definition is shared.

**When to use StatefulSet**

- You need StatefulSet-specific settings (`workload.statefulSet.updateStrategy`, `podManagementPolicy`, `extraVolumeClaimTemplates`, or optional PVC retention policy).
- You want parity with the [RHDH Operator](https://github.com/redhat-developer/rhdh-operator), which supports `spec.deployment.kind: StatefulSet` ([operator documentation](https://github.com/redhat-developer/rhdh-operator/blob/main/docs/configuration.md#deployment-kind)).

Most installs should keep the default **Deployment** (no app StatefulSet and no headless Service).

**Values that behave the same for both kinds**

`replicaCount`, `autoscaling`, probes, `resources`, `dynamicPlugins`, `extraVolumes`, `podLabels`, `podAnnotations`, and other pod-level settings apply regardless of `workload.kind`. When `autoscaling.enabled` is `true`, the HorizontalPodAutoscaler scales the selected kind (`Deployment` or `StatefulSet`).

**Values that depend on the workload kind**

| Helm value | Deployment | StatefulSet |
| ---------- | ---------- | ----------- |
| Update strategy | `strategy` | `workload.statefulSet.updateStrategy` |
| ReplicaSet revision history | `revisionHistoryLimit` | Not used |
| Controller annotations (not the pod) | `deploymentAnnotations` | `workload.statefulSet.annotations` |
| Shared controller annotations | `commonAnnotations` | `commonAnnotations` |
| PVC claim templates | Not used | `workload.statefulSet.extraVolumeClaimTemplates` |
| PVC retention policy | Not used | `workload.statefulSet.persistentVolumeClaimRetentionPolicy` |

**StatefulSet-only settings**

When `workload.kind` is `StatefulSet`, the chart also renders a **headless Service** (`{fullname}-headless`, `clusterIP: None`). The StatefulSet `serviceName` points at that Service (stable pod network identity).

The existing **ClusterIP Service** (`templates/service.yaml`) is unchanged — OpenShift Routes, Ingress, and `helm test` still use it for application traffic.

Override `workload.statefulSet.serviceName` only if you create your own governing Service.
```yaml
# values.yaml
workload:
  kind: StatefulSet
  statefulSet:
    serviceName: ""   # default: {fullname}-headless
    podManagementPolicy: OrderedReady   # or Parallel; omit when empty
    updateStrategy:
      type: RollingUpdate
    extraVolumeClaimTemplates: []
    persistentVolumeClaimRetentionPolicy: {}
    annotations: {}
```

**Stable dynamic-plugins storage**

To give each pod a StatefulSet-owned PVC for `dynamic-plugins-root`:

```yaml
workload:
  kind: StatefulSet
dynamicPlugins:
  volume:
    type: statefulSetPVC
    statefulSetPVC:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
```

The chart injects a `volumeClaimTemplate` named `dynamic-plugins-root` and mounts it on the pod. Kubernetes creates one PVC per pod named `dynamic-plugins-root-{fullname}-{ordinal}` (for example `dynamic-plugins-root-my-rhdh-developer-hub-0`). This requires `workload.kind=StatefulSet`.

To add additional StatefulSet-owned PVCs, use `workload.statefulSet.extraVolumeClaimTemplates`.

**Changing `workload.kind` on an existing release**

For a normal Helm-managed release, changing `workload.kind` and running `helm upgrade` replaces the rendered manifest: Helm removes the old workload kind (Deployment or StatefulSet) and creates the new one. Expect a brief cutover while pods are recreated. If you applied manifests outside Helm (for example GitOps that keeps both objects) or an old controller was left behind, delete the obsolete Deployment or StatefulSet so two controllers do not target the same selector.

**Example install**

```console
helm upgrade -i my-rhdh redhat-developer/redhat-developer-hub \
  --set workload.kind=StatefulSet
```

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

### Extra Deployed Resources (`extraDeploy`)

Use `extraDeploy` to ship arbitrary Kubernetes resources alongside the chart release — NetworkPolicies, ConfigMaps, Secrets, Jobs, or any other kind. Each entry is rendered through `tpl`, so Helm template expressions are supported.

These resources are fully managed by Helm: they are created on install, updated on upgrade, and deleted on uninstall. Removing an entry from `extraDeploy` and running `helm upgrade` will delete the corresponding resource. This is in contrast to resources applied externally (e.g., via `kubectl apply`), which Helm does not track.

Entries can be **objects** (plain YAML) or **strings** (block scalars for multi-line template helpers like `include`).

**Object form** — template expressions work in individual string values:

```yaml
extraDeploy:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: '{{ include "rhdh.fullname" . }}-my-config'
    data:
      key: value
```

**String form** — required when using helpers that expand into multiple YAML keys (e.g., `rhdh.selectorLabels`, `rhdh.labels`):

```yaml
extraDeploy:
  - |
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: {{ include "rhdh.fullname" . }}-allow-http-egress
      labels:
        {{- include "rhdh.labels" . | nindent 8 }}
    spec:
      podSelector:
        matchLabels:
          {{- include "rhdh.selectorLabels" . | nindent 10 }}
      policyTypes:
        - Egress
      egress:
        - ports:
            - port: 80
              protocol: TCP
```

### NetworkPolicies

This chart deploys a **default-deny** NetworkPolicy for the RHDH backend pod, blocking all ingress and egress traffic that is not explicitly allowed. When the built-in PostgreSQL is enabled (`postgresql.enabled=true`), the database pods also get their own default-deny policy with selective allow rules. When OKP is active, its pods receive a separate default-deny ingress and egress policy with rules allowing only the required HTTP ingress.

The following traffic is allowed out of the box:

| Direction | Port | Destination / Source | Purpose |
|-----------|------|----------------------|---------|
| Egress | 53, 5353 (UDP/TCP) | Any | DNS resolution |
| Egress | 443 (TCP) | Any | HTTPS (Git forges, auth providers, external APIs) |
| Egress | 5432 (TCP) | Built-in PostgreSQL pods (scoped) or any (external DB) | Database access |
| Egress | 6379 (TCP) | Any | Redis (BYO — no pod/namespace selector) |
| Egress | 80 (TCP) | Any destination | LCORE access to an HTTP OKP Ingress (NP created only when OKP is enabled; disabled by default) |
| Egress | 8080 (TCP) | OKP pods | LCORE access to the internal OKP Service fallback (NP created only when OKP is enabled; disabled by default) |
| Ingress | 7007 (TCP) | OpenShift router namespace or any namespace (non-OCP) | User traffic via Route / Ingress |
| Ingress | 8080 (TCP) | RHDH pods and the OpenShift router namespace or any namespace (non-OCP) | OKP queries and product-document citations via Route / Ingress |
| Ingress | 9464 (TCP) | `openshift-monitoring`, `openshift-user-workload-monitoring`, `gmp-system`, `gke-gmp-system`, `monitoring` | Prometheus metrics scraping |

OKP initiates no outbound connections: its HTTP server and Solr process run in the same pod and serve the documentation embedded in the image. Its default-deny policy therefore blocks all new egress connections. NetworkPolicy is stateful, so response traffic for allowed ingress connections remains permitted.

RHDH already permits HTTPS egress on port 443. When OKP uses HTTP instead, the chart permits RHDH egress on port 80 for a Kubernetes Ingress or restricts port 8080 egress to OKP pods for the internal Service fallback. No additional RHDH egress policy is created when `OKP_SERVICE_URL` uses HTTPS.

**Redis egress is intentionally unscoped.** RHDH does not deploy Redis; users bring their own instance, which may live in the same namespace, a different namespace, or an external managed service. The rule therefore allows egress on port 6379 to any destination.

**Bitnami subchart NetworkPolicies are disabled** (`postgresql.primary.networkPolicy.enabled=false`, `postgresql.readReplicas.networkPolicy.enabled=false`) because this chart provides its own tighter policies for the built-in database pods.

**Helm test NetworkPolicies** (`allow-test-connection` and `allow-test-connection-ingress`) are Helm test hooks: they are created just before `helm test` runs and cleaned up automatically on success.

**Adding your own NetworkPolicies.** Kubernetes evaluates NetworkPolicies additively — if any policy allows a connection, the connection is permitted. You **cannot** tighten an existing allow rule by adding another NetworkPolicy; you can only broaden access. To add extra allow rules (for example, allowing HTTP egress to an internal auth provider), use [`extraDeploy`](#extra-deployed-resources-extradeploy) or apply your own NetworkPolicy resources externally:

```yaml
extraDeploy:
  - |
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: {{ include "rhdh.fullname" . }}-allow-http-egress
    spec:
      podSelector:
        matchLabels:
          {{- include "rhdh.selectorLabels" . | nindent 10 }}
      policyTypes:
        - Egress
      egress:
        - ports:
            - port: 80
              protocol: TCP
```

For more information on user workload monitoring on OpenShift, see [Configuring user workload monitoring](https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html/configuring_user_workload_monitoring/preparing-to-configure-the-monitoring-stack-uwm).

### Intelligent Assistant

Use `intelligentAssistant.enabled` to enable or disable the built-in Intelligent Assistant feature.

When enabled, the chart adds the default Intelligent Assistant dynamic plugins (`ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant` and `ref://red-hat-developer-hub-backstage-plugin-intelligent-assistant-backend`), a Lightspeed Core sidecar listening on port `8080`, chart-generated ConfigMaps, and a writable runtime volume. Override `intelligentAssistant.plugins` for disconnected environments. Plugin app-config uses the `intelligent-assistant:` namespace (not `lightspeed:`).

The bundled `lightspeed-stack.yaml` does not enable an LLM inference provider. Create a provider-enabled stack in a ConfigMap and reference it with `intelligentAssistant.config.stack.existingConfigMap`. Supply that provider's credentials and settings with `intelligentAssistant.existingSecret`; the chart does not create the Secret.

This is a breaking change from chart 1.x: rename `lightspeed:` to `intelligentAssistant:` in your values. Chart-generated ConfigMaps are named `{fullname}-ia-{stack,profile}` instead of `{fullname}-lightspeed-*`, so Helm replaces those objects on upgrade. The `ia` infix is used because Kubernetes names are limited to 63 characters.

Chart 2.1.0 removes `intelligentAssistant.config.server` and the separate Llama Stack `config.yaml`. Remove the `server` entry from existing values. Move custom Llama Stack settings into the `lightspeed-stack.yaml` supplied through `intelligentAssistant.config.stack.existingConfigMap`.

Use `intelligentAssistant.runtimeVolume` to change the writable `/tmp` runtime storage between `emptyDir` and an existing PVC reference. The chart mounts that volume at `/tmp` so both generated temporary files and `/tmp/data` remain writable.

When using the built-in Intelligent Assistant feature, do not also keep those plugin packages in `dynamicPlugins.plugins`. Existing installations that previously configured Lightspeed or Intelligent Assistant there should remove those entries if the built-in defaults are sufficient, or move their custom package definitions to `intelligentAssistant.plugins`; otherwise the rendered `dynamic-plugins.yaml` will contain duplicate plugin entries.

The Lightspeed Core sidecar loads `intelligentAssistant.existingSecret` as environment variables. If you update that Secret outside of Helm, Kubernetes does not guarantee that the Backstage Pod restarts automatically. Use a no-op `helm upgrade` or manually restart the Backstage workload (Deployment or StatefulSet) after changing the secret data.

RHDH documentation retrieval is disabled by default in Intelligent Assistant. To enable it, set `intelligentAssistant.okp.enabled=true`. This deploys the OKP workload and uses the OKP-enabled Lightspeed Stack configuration. The OKP container image is large, so enabling it can significantly increase the initial installation time while the image is downloaded. On vanilla Kubernetes, you must also configure the OKP Ingress and Red Hat registry credentials. See [Intelligent Assistant and OKP integration](../../docs/intelligent-assistant.md) for platform-specific configuration.

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
