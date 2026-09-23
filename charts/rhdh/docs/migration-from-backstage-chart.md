# Migration guide: `backstage` chart (RHDH 1.y) to `redhat-developer-hub` chart (RHDH 2.y)

This `redhat-developer-hub` chart is a clean break from the 1.y `backstage` chart.
The old chart delegated most Kubernetes resource creation to an embedded upstream
[Backstage subchart](https://github.com/backstage/charts), so values lived under
`upstream.backstage.*` and `global.*`. The new chart owns all templates directly and
flattens configuration to root-level keys.

> [!IMPORTANT]
> Because the values structure has changed, you cannot pass your old values file
> directly to the new chart. You must migrate your values first, then
> `helm upgrade` the release in place. Tooling (a migration script or AI skill)
> to automate the values conversion is planned in the near future.

> [!NOTE]
> This guide focuses on values that **changed path, were removed, or changed
> semantics**. Fields not explicitly listed here (e.g., `orchestrator.*`,
> `test.*`) retain the same path and semantics — carry them over as-is.

## Migration steps

1. Locate your existing values file (typically stored in your Git repo or
   locally). If you don't have it, you can export the user-supplied overrides
   from a running release:

   ```bash
   helm get values <release> -o yaml > old-values.yaml
   ```

2. Create a new values file using the mapping tables below to translate each
   setting to its new path.

3. Upgrade the existing release in place with the new chart and migrated values:

   ```bash
   helm upgrade --install <release> redhat-developer/redhat-developer-hub -f new-values.yaml
   ```

4. Verify the deployment is healthy.

## Prerequisites

The new chart requires **Kubernetes 1.31+** (OpenShift 4.18+). If you are
running an older cluster, upgrade it before migrating.

## Key structural changes

| Aspect | Old chart (`backstage`) | New chart (`redhat-developer-hub`) |
|--------|------------------------|------------------------------------|
| Chart name | `backstage` | `redhat-developer-hub` (but `nameOverride` defaults to `developer-hub`, so resource names and Route URLs are preserved) |
| Template ownership | Delegates to upstream Backstage subchart | Owns all templates directly |
| System volumes/mounts/env | User had to list them in full under `upstream.backstage.extraVolumes`, `extraVolumeMounts`, `extraEnvVars` | Hardcoded in templates; `extra*` keys only add user values |
| Init containers | User had to specify the full init container array | System init containers are managed; use `preInitContainers` / `extraInitContainers` to add custom ones |
| Database env vars | `POSTGRESQL_ADMIN_PASSWORD` injected manually via `upstream.backstage.extraEnvVars` | `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` auto-injected |
| Image digests | `upstream.backstage.image.digest` only | Every image (`image`, `catalogIndex.image`, `intelligentAssistant.core.image`, etc.) has a `digest` field for pinning by digest |
| Global image registry | Not available | `global.imageRegistry` overrides the registry for all container images consistently — useful for disconnected / air-gapped environments |
| Lightspeed | `global.lightspeed.*` | Rebranded to `intelligentAssistant.*` |
| OpenShift Route | `route.*` | `openshift.route.*` |

## Important behavioral changes

### Network policies

The new chart deploys **default-deny** NetworkPolicies for the RHDH pod and
allows only the traffic it knows about (DNS, PostgreSQL, OpenShift
ingress/monitoring). If your deployment relies on additional network
connectivity (e.g., external APIs, custom sidecars, or cross-namespace
services), you must add the corresponding NetworkPolicy rules or the
connections will be silently blocked.

### Schema validation

The new chart ships a JSON Schema (`values.schema.json`) that validates your
values at install/upgrade time. Any unrecognized keys — including leftover
`upstream.*` or `global.*` paths that were not migrated — will cause Helm to
fail with a validation error. This makes it easy to catch stale values early,
but it also means a partial migration will not install. Run
`helm template -f new-values.yaml` to validate your file before upgrading.

### New features (no old-chart equivalent)

These capabilities are new in the `redhat-developer-hub` chart and have no
mapping from the old chart, but are worth knowing about during migration:

- **StatefulSet workload** — set `workload.kind: StatefulSet` for stable pod
  identity and persistent volumes via `volumeClaimTemplates`.
- **External database** — `externalDatabase.*` for connecting to a database
  outside the cluster when `postgresql.enabled: false`.
- **OKP (Offline Knowledge Portal)** — `intelligentAssistant.okp.*` for
  offline RHDH documentation retrieval.

## Values mapping reference

### Container image

| Old path | New path |
|----------|----------|
| `upstream.backstage.image.registry` | `image.registry` |
| `upstream.backstage.image.repository` | `image.repository` |
| `upstream.backstage.image.tag` | `image.tag` |
| `upstream.backstage.image.digest` | `image.digest` |
| `upstream.backstage.image.pullPolicy` | `image.pullPolicy` |
| `upstream.backstage.image.pullSecrets` | `imagePullSecrets` | Promoted to root |

### Chart-level overrides

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.nameOverride` | `nameOverride` | Defaults to `developer-hub` to preserve resource names |
| `upstream.fullnameOverride` | `fullnameOverride` | |
| `upstream.commonLabels` | `commonLabels` | |
| `upstream.commonAnnotations` | `commonAnnotations` | |

### Global parameters

| Old path | New path | Notes |
|----------|----------|-------|
| `global.clusterRouterBase` | `openshift.clusterRouterBase` | |
| `global.host` | `host` | Promoted to root |
| `global.imagePullSecrets` | `global.imagePullSecrets` | Unchanged (used by bitnami subcharts) |

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
| `upstream.backstage.replicaCount` | `replicaCount` | |
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

### Service account

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.serviceAccount.create` | `serviceAccount.create` | Defaults to `false` |
| `upstream.serviceAccount.name` | `serviceAccount.name` | |
| `upstream.serviceAccount.annotations` | `serviceAccount.annotations` | |
| `upstream.serviceAccount.automount` | `serviceAccount.automount` | |

### Container command, args, and env

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.command` | `commandOverride` | |
| `upstream.backstage.args` | `argsOverride` | System `--config` flags now auto-injected |
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
| `upstream.backstage.initContainers` | _(managed by chart)_ | System init containers no longer user-configurable |
| _(none)_ | `preInitContainers` | Runs **before** system init containers |
| _(none)_ | `extraInitContainers` | Runs **after** system init containers |
| _(none)_ | `extraContainers` | Additional sidecars |

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
| `upstream.ingress.extraHosts` | `ingress.hosts[]` | Merged into main hosts array |
| `upstream.ingress.tls.enabled` / `tls.secretName` | `ingress.tls[]` | Now a list of TLS entries |
| `upstream.ingress.extraTls` | `ingress.tls[]` | Merged into main tls array |

### Catalog index

| Old path | New path |
|----------|----------|
| `global.catalogIndex.image.registry` | `catalogIndex.image.registry` |
| `global.catalogIndex.image.repository` | `catalogIndex.image.repository` |
| `global.catalogIndex.image.tag` | `catalogIndex.image.tag` |
| `global.catalogIndex.extraImages` | `catalogIndex.extraImages` |

### PostgreSQL (bitnami subchart)

| Old path | New path |
|----------|----------|
| `upstream.postgresql.enabled` | `postgresql.enabled` |
| `upstream.postgresql.postgresqlDataDir` | `postgresql.postgresqlDataDir` |
| `upstream.postgresql.serviceBindings.enabled` | `postgresql.serviceBindings.enabled` |
| `upstream.postgresql.image.*` | `postgresql.image.*` |
| `upstream.postgresql.auth.*` | `postgresql.auth.*` |
| `upstream.postgresql.primary.*` | `postgresql.primary.*` |

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
| `global.lightspeed.enabled` | `intelligentAssistant.enabled` | Default changed from `false` to `true` |
| `global.lightspeed.plugins` | `intelligentAssistant.plugins` | Plugin format changed from OCI to `ref://` |
| `global.lightspeed.sidecar.image` | `intelligentAssistant.core.image.*` | Single string split into `registry`/`repository`/`tag` |
| `global.lightspeed.sidecar.resources` | `intelligentAssistant.core.resources` | |
| `global.lightspeed.sidecar.securityContext` | `intelligentAssistant.core.securityContext` | |
| `global.lightspeed.sidecar.command` | `intelligentAssistant.core.commandOverride` | |
| `global.lightspeed.sidecar.args` | `intelligentAssistant.core.argsOverride` | |
| `global.lightspeed.sidecar.env` | `intelligentAssistant.core.extraEnv` | |
| `global.lightspeed.initContainer.*` | _(removed)_ | The RAG init container no longer exists in the new chart |
| `global.lightspeed.runtimeVolume.type` | `intelligentAssistant.runtimeVolume.type` | |
| `global.lightspeed.runtimeVolume.emptyDir` | `intelligentAssistant.runtimeVolume.emptyDir` | |
| `global.lightspeed.runtimeVolume.persistentVolumeClaim` | `intelligentAssistant.runtimeVolume.persistentVolumeClaim` | |
| `global.lightspeed.configMaps` | `intelligentAssistant.config.{stack,profile}.existingConfigMap` | Array replaced with structured per-file config |
| `global.lightspeed.secret.create` / `.name` | `intelligentAssistant.existingSecret` | Simplified to a secret name string |

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

### Test pod

| Old path | New path | Notes |
|----------|----------|-------|
| `test.image.tag` | `test.image.tag` | Default changed from `latest` to a pinned version |
| `test.injectTestNpmrcSecret` | _(removed)_ | No longer needed |

### Removed values (no equivalent)

The following old-chart values have no equivalent in the new chart because the
functionality is either hardcoded or no longer applicable:

| Old path | Notes |
|----------|-------|
| `upstream.backstage.installDir` | Hardcoded in the new chart |
| `upstream.backstage.containerPorts.backend` | Hardcoded to `7007` |
| `upstream.backstage.extraPorts` | Use `service.extraPorts` instead |
| `upstream.backstage.lifecycleHooks` | Not supported |
| `upstream.backstage.priorityClassName` | Not supported |
| `upstream.backstage.terminationGracePeriodSeconds` | Not supported |
| `upstream.diagnosticMode.*` | Not supported |
