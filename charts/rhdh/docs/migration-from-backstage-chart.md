# Migration guide: `backstage` chart (RHDH 1.y) to `redhat-developer-hub` chart (RHDH 2.y)

This `redhat-developer-hub` chart is a clean break from the 1.y `backstage` chart. The old chart delegated most Kubernetes resource creation to an embedded upstream [Backstage subchart](https://github.com/backstage/charts), so values lived under `upstream.backstage.*` and `global.*`. The new chart owns all templates directly and flattens configuration to root-level keys.

> [!IMPORTANT]
> Because the values structure has changed, you cannot pass your old values file directly to the new chart. You must migrate your values first, then `helm upgrade` the release in place. Tooling (a migration script or AI skill) to automate the values conversion is planned in the near future.

> [!NOTE]
> Fields not listed in the tables below keep the same path. Where a table shows a new path, use that. If a field you use is not mentioned at all, carry it over as-is.

## Migration steps

1. Locate your existing values file (typically stored in your Git repo or locally). If you don't have it, you can export the user-supplied overrides from a running release:

   ```bash
   helm get values <release> -n <namespace> -o yaml > old-values.yaml
   ```

2. Create a new values file using the mapping tables below to translate each setting to its new path.

3. Before upgrading, watch for these default changes:
   - **Intelligent Assistant** (formerly Lightspeed) remains enabled by default. If you had explicitly disabled it in your old chart, set `intelligentAssistant.enabled: false`.
   - **PostgreSQL image** defaults to version 18. If you have an existing data directory, keep the old image (`postgresql.image.tag`) until you plan a PostgreSQL major upgrade.

4. Upgrade the existing release in place with the new chart and migrated values:

   ```bash
   helm upgrade --install <release> redhat-developer/redhat-developer-hub -n <namespace> -f new-values.yaml
   ```

5. Verify the deployment is healthy.

## Prerequisites

The new chart requires **Kubernetes 1.31+** (OpenShift 4.18+). If you are running an older cluster, upgrade it before migrating.

## Key structural changes

| Aspect | Old chart (`backstage`) | New chart (`redhat-developer-hub`) |
|--------|------------------------|------------------------------------|
| Chart name | `backstage` | `redhat-developer-hub` (but `nameOverride` defaults to `developer-hub`, so resource names and Route URLs are preserved) |
| Template ownership | Delegates to upstream Backstage subchart | Owns all templates directly |
| System volumes/mounts/env | User had to list them in full under `upstream.backstage.extraVolumes`, `extraVolumeMounts`, `extraEnvVars` | Hardcoded in templates; `extra*` keys only add user values |
| Init containers | User had to specify the full init container array | System init containers are managed by the chart (e.g., `install-dynamic-plugins` is configurable via `dynamicPlugins.initContainer.*`); use `preInitContainers` / `extraInitContainers` to add custom ones |
| Database env vars | `POSTGRESQL_ADMIN_PASSWORD` injected manually via `upstream.backstage.extraEnvVars` | `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` auto-injected |
| Image digests | `upstream.backstage.image.digest` only | Every image (`image`, `catalogIndex.image`, `intelligentAssistant.core.image`, etc.) has a `digest` field for pinning by digest |
| Global image registry | Supported via embedded Bitnami common chart but undocumented and not applied consistently | `global.imageRegistry` is now documented and applied consistently to all container images — useful for disconnected / air-gapped environments |
| Lightspeed | `global.lightspeed.*` | Rebranded to `intelligentAssistant.*` |
| OpenShift Route | `route.*` | `openshift.route.*` |

## Important behavioral changes

### Network policies

The new chart deploys **default-deny** NetworkPolicies for the RHDH pod and allows only the traffic it knows about (DNS, PostgreSQL, OpenShift ingress/monitoring). If your deployment relies on additional network connectivity (e.g., external APIs, custom sidecars, or cross-namespace services), you must add the corresponding NetworkPolicy rules or the connections will be silently blocked. See the [NetworkPolicies](../README.md#networkpolicies) section in the README for details.

### Schema validation

The new chart ships a JSON Schema (`values.schema.json`) that validates your values at install/upgrade time. The schema catches type errors and invalid values for known keys, but leftover top-level keys (e.g., `upstream.*`) may pass silently. Make sure you remove or migrate **all** old paths — do not rely on schema validation alone to catch stale values. Run `helm template <release> redhat-developer/redhat-developer-hub -f new-values.yaml` to check for template rendering errors before upgrading.

### New features (no old-chart equivalent)

These capabilities are new in the `redhat-developer-hub` chart and have no mapping from the old chart, but are worth knowing about during migration:

- **StatefulSet workload** — set `workload.kind: StatefulSet` for stable pod identity and persistent volumes via `volumeClaimTemplates`. Pair with `dynamicPlugins.volume.type: statefulSetPVC` and `dynamicPlugins.volume.statefulSetPVC` to get per-pod stable caching for dynamic plugins.
- **External database** — the concept of using an external database is not new, but the new chart provides a dedicated `externalDatabase.*` block for configuring the connection when `postgresql.enabled: false`. See the [external database documentation](../../docs/external-db.md).
- **OKP (Offline Knowledge Portal)** — `intelligentAssistant.okp.*` for offline RHDH documentation retrieval.

## Values mapping reference

### Container image

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.image.registry` | `image.registry` | |
| `upstream.backstage.image.repository` | `image.repository` | |
| `upstream.backstage.image.tag` | `image.tag` | |
| `upstream.backstage.image.digest` | `image.digest` | |
| `upstream.backstage.image.pullPolicy` | `image.pullPolicy` | |
| `upstream.backstage.image.pullSecrets` | `imagePullSecrets` | Promoted to root |

### Chart-level overrides

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.nameOverride` | `nameOverride` | Defaults to `developer-hub` to preserve resource names |
| `upstream.fullnameOverride` | `fullnameOverride` | |
| `upstream.commonLabels` | `commonLabels` | |
| `upstream.commonAnnotations` | `commonAnnotations` | |
| `upstream.extraDeploy` | `extraDeploy` | |

### Global parameters

| Old path | New path | Notes |
|----------|----------|-------|
| `global.clusterRouterBase` | `openshift.clusterRouterBase` | |
| `global.host` | `host` | Promoted to root |
| `global.imagePullSecrets` | `global.imagePullSecrets` | Unchanged (used by bitnami subcharts) |
| `global.imageRegistry` | `global.imageRegistry` | Now documented and applied consistently to all container images — useful for disconnected / air-gapped environments |

### App config

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.appConfig` | `appConfig` | Entire tree flattened to root |
| `upstream.backstage.extraAppConfig` | `extraAppConfig` | Same format (list of `filename` + `configMapRef`) |
| `upstream.backstage.appConfig.backend.database.connection.password` | `appConfig.backend.database.connection.password` | Env var changed from `POSTGRESQL_ADMIN_PASSWORD` to `POSTGRES_PASSWORD` |
| `upstream.backstage.appConfig.backend.database.connection.user` | `appConfig.backend.database.connection.user` | Env var changed from hardcoded `postgres` to `POSTGRES_USER` |

### Authentication

| Old path | New path | Notes |
|----------|----------|-------|
| `global.auth.backend.enabled` | `auth.backend.enabled` | |
| `global.auth.backend.existingSecret` | `auth.backend.existingSecretRef.name` | Now an object with `name` and `key` |
| _(none)_ | `auth.backend.existingSecretRef.key` | Defaults to `backend-secret` |
| `global.auth.backend.value` | `auth.backend.value` | |

### Dynamic plugins

| Old path | New path | Notes |
|----------|----------|-------|
| `global.dynamic.includes` | `dynamicPlugins.includes` | |
| `global.dynamic.plugins` | `dynamicPlugins.plugins` | |
| `upstream.backstage.extraVolumes` _(dynamic-plugins-root)_ | `dynamicPlugins.volume.*` | Declarative config replaces raw volume spec |
| `upstream.backstage.initContainers[0].resources` | `dynamicPlugins.initContainer.resources` | |
| `upstream.backstage.initContainers[0].securityContext` | `dynamicPlugins.initContainer.securityContext` | |
| `upstream.backstage.initContainers[0].env` | `dynamicPlugins.initContainer.extraEnv` | System env vars auto-injected |

### Pod scheduling, replicas, and metadata

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.replicas` | `replicaCount` | Renamed |
| `upstream.backstage.revisionHistoryLimit` | `revisionHistoryLimit` | |
| `upstream.backstage.strategy` | `strategy` | |
| `upstream.backstage.annotations` | `deploymentAnnotations` | Renamed to clarify these are on the Deployment, not the pod |
| `upstream.backstage.podAnnotations` | `podAnnotations` | |
| `upstream.backstage.podLabels` | `podLabels` | |
| `upstream.backstage.nodeSelector` | `nodeSelector` | |
| `upstream.backstage.tolerations` | `tolerations` | |
| `upstream.backstage.affinity` | `affinity` | |
| `upstream.backstage.topologySpreadConstraints` | `topologySpreadConstraints` | |
| `upstream.backstage.hostAliases` | `hostAliases` | |
| `upstream.backstage.priorityClassName` | `priorityClassName` | |
| `upstream.backstage.terminationGracePeriodSeconds` | `terminationGracePeriodSeconds` | |
| `upstream.backstage.lifecycleHooks` | `lifecycleHooks` | |

### Service account

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.serviceAccount.create` | `serviceAccount.create` | Defaults to `false` |
| `upstream.serviceAccount.name` | `serviceAccount.name` | |
| `upstream.serviceAccount.annotations` | `serviceAccount.annotations` | |
| `upstream.serviceAccount.automountServiceAccountToken` | `serviceAccount.automount` | Renamed |
| `upstream.serviceAccount.labels` | `serviceAccount.labels` | |

### Container command, args, and env

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.command` | `commandOverride` | |
| `upstream.backstage.args` | `extraArgs` or `argsOverride` | Prefer `extraArgs` — it appends after the system `--config` flags. `argsOverride` replaces **all** arguments, including system ones; only use it if you need full control |
| `upstream.backstage.extraEnvVars` | `extraEnv` | System env vars auto-injected; only add custom ones |
| `upstream.backstage.extraEnvVarsSecrets` | `extraEnvFrom` | Use `secretRef` entries instead of secret name strings |
| `upstream.backstage.extraEnvVarsCM` | `extraEnvFrom` | Use `configMapRef` entries instead of ConfigMap name strings |

### Volumes and mounts

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.extraVolumes` | `extraVolumes` | Only user additions; system volumes are hardcoded |
| `upstream.backstage.extraVolumeMounts` | `extraVolumeMounts` | Only user additions; system mounts are hardcoded |

### Init containers and sidecars

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.initContainers` | _(see below)_ | System init containers are no longer specified as raw arrays; configure the `install-dynamic-plugins` init container via `dynamicPlugins.initContainer.*` (resources, securityContext, command/args overrides, extra env, extra volume mounts) |
| _(none)_ | `preInitContainers` | Runs **before** system init containers |
| _(none)_ | `extraInitContainers` | Runs **after** system init containers |
| `upstream.backstage.extraContainers` | `extraContainers` | |

### Security contexts and resources

| Old path | New path |
|----------|----------|
| `upstream.backstage.podSecurityContext` | `podSecurityContext` |
| `upstream.backstage.containerSecurityContext` | `containerSecurityContext` |
| `upstream.backstage.resources` | `resources` |

### Probes

| Old path | New path |
|----------|----------|
| `upstream.backstage.startupProbe` | `startupProbe` |
| `upstream.backstage.readinessProbe` | `readinessProbe` |
| `upstream.backstage.livenessProbe` | `livenessProbe` |

### Service

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.service.type` | `service.type` | |
| `upstream.service.ports.backend` | `service.port` | Flattened from `ports.backend` to `port` |
| `upstream.service.nodePorts.backend` | `service.nodePort` | Flattened from `nodePorts.backend` to `nodePort` |
| `upstream.service.extraPorts` | `service.extraPorts` | |
| `upstream.service.clusterIP` | `service.clusterIP` | |
| `upstream.service.loadBalancerIP` | `service.loadBalancerIP` | |
| `upstream.service.loadBalancerSourceRanges` | `service.loadBalancerSourceRanges` | |
| `upstream.service.externalTrafficPolicy` | `service.externalTrafficPolicy` | |
| `upstream.service.sessionAffinity` | `service.sessionAffinity` | |
| `upstream.service.annotations` | `service.annotations` | |
| `upstream.service.ipFamilyPolicy` | `service.ipFamilyPolicy` | |
| `upstream.service.ipFamilies` | `service.ipFamilies` | |

### OpenShift Route

| Old path | New path |
|----------|----------|
| `route.enabled` | `openshift.route.enabled` |
| `route.annotations` | `openshift.route.annotations` |
| `route.host` | `openshift.route.host` |
| `route.path` | `openshift.route.path` |
| `route.wildcardPolicy` | `openshift.route.wildcardPolicy` |
| `route.tls.enabled` | `openshift.route.tls.enabled` |
| `route.tls.termination` | `openshift.route.tls.termination` |
| `route.tls.certificate` | `openshift.route.tls.certificate` |
| `route.tls.key` | `openshift.route.tls.key` |
| `route.tls.caCertificate` | `openshift.route.tls.caCertificate` |
| `route.tls.destinationCACertificate` | `openshift.route.tls.destinationCACertificate` |
| `route.tls.insecureEdgeTerminationPolicy` | `openshift.route.tls.insecureEdgeTerminationPolicy` |

### Autoscaling (HPA)

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.autoscaling.enabled` | `autoscaling.enabled` | |
| `upstream.backstage.autoscaling.minReplicas` | `autoscaling.minReplicas` | |
| `upstream.backstage.autoscaling.maxReplicas` | `autoscaling.maxReplicas` | Old default was `100`, new default is `3` |
| `upstream.backstage.autoscaling.targetCPUUtilizationPercentage` | `autoscaling.targetCPUUtilizationPercentage` | |
| `upstream.backstage.autoscaling.targetMemoryUtilizationPercentage` | `autoscaling.targetMemoryUtilizationPercentage` | |

### Pod Disruption Budget

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.pdb.create` | `podDisruptionBudget.create` | |
| `upstream.backstage.pdb.minAvailable` | `podDisruptionBudget.minAvailable` | |
| `upstream.backstage.pdb.maxUnavailable` | `podDisruptionBudget.maxUnavailable` | |

### Gateway API HTTPRoute

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.httpRoute.enabled` | `httpRoute.enabled` | |
| `upstream.httpRoute.labels` | `httpRoute.labels` | |
| `upstream.httpRoute.annotations` | `httpRoute.annotations` | |
| `upstream.httpRoute.parentRefs` | `httpRoute.parentRefs` | |
| `upstream.httpRoute.hostnames` | `httpRoute.hostnames` | |
| `upstream.httpRoute.rules` | `httpRoute.rules` | |

### Ingress

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.ingress.enabled` | `ingress.enabled` | |
| `upstream.ingress.className` | `ingress.className` | |
| `upstream.ingress.annotations` | `ingress.annotations` | |
| `upstream.ingress.host` | `ingress.hosts[].host` | Now an array of host objects |
| `upstream.ingress.path` | `ingress.hosts[].paths[].path` | Nested under hosts array |
| `upstream.ingress.extraHosts` | `ingress.hosts[]` | Merged into main hosts array; old `name` field becomes `host`, old `path` becomes an item in `paths[]` |
| `upstream.ingress.tls.enabled` / `tls.secretName` | `ingress.tls[]` | Now a list of `{hosts: [...], secretName: "..."}` entries |
| `upstream.ingress.extraTls` | `ingress.tls[]` | Merged into main tls array |

### Catalog index

| Old path | New path |
|----------|----------|
| `global.catalogIndex.image.registry` | `catalogIndex.image.registry` |
| `global.catalogIndex.image.repository` | `catalogIndex.image.repository` |
| `global.catalogIndex.image.tag` | `catalogIndex.image.tag` |
| `global.catalogIndex.extraImages` | `catalogIndex.extraImages` |

### PostgreSQL (bitnami subchart)

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.postgresql.enabled` | `postgresql.enabled` | |
| `upstream.postgresql.postgresqlDataDir` | `postgresql.postgresqlDataDir` | |
| `upstream.postgresql.serviceBindings.enabled` | `postgresql.serviceBindings.enabled` | |
| `upstream.postgresql.image.*` | `postgresql.image.*` | **Warning:** default image changed from PostgreSQL 15 to 18. If you have an existing data directory created by PostgreSQL 15, explicitly set `postgresql.image.tag` to your current version until you plan a PostgreSQL major upgrade |
| `upstream.postgresql.auth.*` | `postgresql.auth.*` | |
| `upstream.postgresql.primary.*` | `postgresql.primary.*` | |

### Metrics / monitoring

| Old path | New path |
|----------|----------|
| `upstream.metrics.serviceMonitor.enabled` | `metrics.serviceMonitor.enabled` |
| `upstream.metrics.serviceMonitor.path` | `metrics.serviceMonitor.path` |
| `upstream.metrics.serviceMonitor.port` | `metrics.serviceMonitor.port` |
| `upstream.metrics.serviceMonitor.interval` | `metrics.serviceMonitor.interval` |
| `upstream.metrics.serviceMonitor.labels` | `metrics.serviceMonitor.labels` |
| `upstream.metrics.serviceMonitor.annotations` | `metrics.serviceMonitor.annotations` |

### Network policies

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.networkPolicy.enabled` | _(removed)_ | New chart always deploys default-deny NetworkPolicies; see [Important behavioral changes](#important-behavioral-changes) |
| `upstream.networkPolicy.ingressRules.*` | _(removed)_ | |
| `upstream.networkPolicy.egressRules.*` | _(removed)_ | |

### Intelligent Assistant (formerly Lightspeed)

| Old path | New path | Notes |
|----------|----------|-------|
| `global.lightspeed.enabled` | `intelligentAssistant.enabled` | Renamed |
| `global.lightspeed.plugins` | `intelligentAssistant.plugins` | Plugin format changed from OCI to `ref://` |
| `global.lightspeed.sidecar.image` | `intelligentAssistant.core.image.*` | Single string split into `registry`/`repository`/`tag` |
| `global.lightspeed.sidecar.resources` | `intelligentAssistant.core.resources` | |
| `global.lightspeed.sidecar.securityContext` | `intelligentAssistant.core.securityContext` | |
| `global.lightspeed.sidecar.command` | `intelligentAssistant.core.commandOverride` | |
| `global.lightspeed.sidecar.args` | `intelligentAssistant.core.argsOverride` | |
| `global.lightspeed.sidecar.env` | `intelligentAssistant.core.extraEnv` | |
| `global.lightspeed.sidecar.imagePullPolicy` | `intelligentAssistant.core.imagePullPolicy` | |
| `global.lightspeed.initContainer.*` | _(removed)_ | The RAG init container no longer exists in the new chart |
| `global.lightspeed.ragVolume.*` | _(removed)_ | No longer needed without the RAG init container |
| `global.lightspeed.sidecar.name` | _(hardcoded)_ | Chart manages the container name internally |
| `global.lightspeed.sidecar.portName` | _(hardcoded)_ | Chart manages the port name internally |
| `global.lightspeed.sidecar.containerPort` | _(hardcoded)_ | Chart manages the container port internally |
| `global.lightspeed.runtimeVolume.type` | `intelligentAssistant.runtimeVolume.type` | |
| `global.lightspeed.runtimeVolume.emptyDir` | `intelligentAssistant.runtimeVolume.emptyDir` | |
| `global.lightspeed.runtimeVolume.persistentVolumeClaim` | `intelligentAssistant.runtimeVolume.persistentVolumeClaim` | |
| `global.lightspeed.runtimeVolume.name` | _(hardcoded)_ | Chart manages volume names internally |
| `global.lightspeed.runtimeVolume.mountPath` | _(hardcoded)_ | Chart manages mount paths internally |
| `global.lightspeed.configMaps` | `intelligentAssistant.config.{stack,profile}.existingConfigMap` | Array of 3 configMaps replaced with 2 structured entries; the separate `config.yaml` is no longer needed because the llama-stack configuration is now inlined in `lightspeed-stack.yaml` |
| `global.lightspeed.secret.create` / `.name` | `intelligentAssistant.existingSecret` | The new chart does not create a placeholder secret — you must create it independently before upgrading, then set `intelligentAssistant.existingSecret` to its name. See [`files/intelligent-assistant/secret.example.yaml`](../files/intelligent-assistant/secret.example.yaml) for a reference template |
| `global.lightspeed.secret.optional` | _(removed)_ | No longer needed; the secret is only mounted when `intelligentAssistant.existingSecret` is set |

### Orchestrator

| Old path | New path | Notes |
|----------|----------|-------|
| `orchestrator.sonataflowPlatform.externalDBsecretRef` | `orchestrator.sonataflowPlatform.externalDB.existingSecret` | Restructured |
| `orchestrator.sonataflowPlatform.externalDBName` | `orchestrator.sonataflowPlatform.externalDB.name` | |
| `orchestrator.sonataflowPlatform.externalDBHost` | `orchestrator.sonataflowPlatform.externalDB.host` | |
| `orchestrator.sonataflowPlatform.externalDBPort` | `orchestrator.sonataflowPlatform.externalDB.port` | |
| `orchestrator.sonataflowPlatform.initContainerImage` | `orchestrator.sonataflowPlatform.dbCreationJob.image.*` | Single string split into structured image fields |
| `orchestrator.sonataflowPlatform.createDBJobImage` | `orchestrator.sonataflowPlatform.dbCreationJob.image.*` | Merged with `initContainerImage` |
| `orchestrator.sonataflowPlatform.dataIndexImage` | `orchestrator.sonataflowPlatform.dataIndex.image.*` | Single string split into structured image fields |
| `orchestrator.sonataflowPlatform.jobServiceImage` | `orchestrator.sonataflowPlatform.jobService.image.*` | Single string split into structured image fields |
| `orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit` | `orchestrator.sonataflowPlatform.dbCreationJob.backoffLimit` | Nested under `dbCreationJob` |
| `orchestrator.sonataflowPlatform.dbCreationJobTTLSecondsAfterFinished` | `orchestrator.sonataflowPlatform.dbCreationJob.ttlSecondsAfterFinished` | Nested under `dbCreationJob` |
| `orchestrator.sonataflowPlatform.dbCreationJobActiveDeadlineSeconds` | `orchestrator.sonataflowPlatform.dbCreationJob.activeDeadlineSeconds` | Nested under `dbCreationJob` |

### Test pod

| Old path | New path | Notes |
|----------|----------|-------|
| `test.image.tag` | `test.image.tag` | Default changed from `latest` to a pinned version |
| `test.injectTestNpmrcSecret` | _(removed)_ | No longer needed |

### Removed values (no equivalent)

The following old-chart values have no equivalent in the new chart because the functionality is either hardcoded or no longer applicable:

| Old path | Notes |
|----------|-------|
| `upstream.backstage.installDir` | Hardcoded in the new chart |
| `upstream.backstage.containerPorts.backend` | Hardcoded to `7007` |
| `upstream.diagnosticMode.*` | Not supported |
