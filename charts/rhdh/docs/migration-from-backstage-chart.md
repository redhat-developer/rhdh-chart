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

## Key structural changes

| Aspect | Old chart (`backstage`) | New chart (`redhat-developer-hub`) |
|--------|------------------------|------------------------------------|
| Chart name | `backstage` | `redhat-developer-hub` (but `nameOverride` defaults to `developer-hub`, so resource names and Route URLs are preserved) |
| Template ownership | Delegates to upstream Backstage subchart | Owns all templates directly |
| System volumes/mounts/env | User had to list them in full under `upstream.backstage.extraVolumes`, `extraVolumeMounts`, `extraEnvVars` | Hardcoded in templates; `extra*` keys only add user values |
| Init containers | User had to specify the full init container array | System init containers are managed; use `preInitContainers` / `extraInitContainers` to add custom ones |
| Database env vars | `POSTGRESQL_ADMIN_PASSWORD` injected manually via `upstream.backstage.extraEnvVars` | `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` auto-injected |
| Image digests | No dedicated field | Every image (`image`, `catalogIndex.image`, `intelligentAssistant.core.image`, etc.) has a `digest` field for pinning by digest |
| Global image registry | Not available | `global.imageRegistry` overrides the registry for all container images consistently — useful for disconnected / air-gapped environments |
| Lightspeed | `global.lightspeed.*` | Rebranded to `intelligentAssistant.*` |
| OpenShift Route | `route.*` | `openshift.route.*` |

## Values mapping reference

### Container image

| Old path | New path |
|----------|----------|
| `upstream.backstage.image.registry` | `image.registry` |
| `upstream.backstage.image.repository` | `image.repository` |
| `upstream.backstage.image.tag` | `image.tag` |
| `upstream.backstage.image.pullPolicy` | `image.pullPolicy` |

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

### Container command, args, and env

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.backstage.command` | `commandOverride` | |
| `upstream.backstage.args` | `argsOverride` | System `--config` flags now auto-injected |
| `upstream.backstage.extraEnvVars` | `extraEnv` | System env vars auto-injected; only add custom ones |

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
| `upstream.backstage.containerSecurityContext` | `containerSecurityContext` |
| `upstream.backstage.resources` | `resources` |

### Probes

| Old path | New path |
|----------|----------|
| `upstream.backstage.startupProbe` | `startupProbe` |
| `upstream.backstage.readinessProbe` | `readinessProbe` |
| `upstream.backstage.livenessProbe` | `livenessProbe` |

### Service

| Old path | New path |
|----------|----------|
| `upstream.service.extraPorts` | `service.extraPorts` |

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

### Ingress

| Old path | New path | Notes |
|----------|----------|-------|
| `upstream.ingress.enabled` | `ingress.enabled` | |
| `upstream.ingress.host` | `ingress.hosts[].host` | Now an array of host objects |

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
| `global.lightspeed.initContainer.image` | `intelligentAssistant.ragInit.image.*` | Single string split into `registry`/`repository`/`tag` |
| `global.lightspeed.initContainer.resources` | `intelligentAssistant.ragInit.resources` | |
| `global.lightspeed.initContainer.securityContext` | `intelligentAssistant.ragInit.securityContext` | |
| `global.lightspeed.initContainer.command` | `intelligentAssistant.ragInit.commandOverride` | |
| `global.lightspeed.initContainer.args` | `intelligentAssistant.ragInit.argsOverride` | |
| `global.lightspeed.initContainer.env` | `intelligentAssistant.ragInit.extraEnv` | |
| `global.lightspeed.runtimeVolume.type` | `intelligentAssistant.runtimeVolume.type` | |
| `global.lightspeed.runtimeVolume.emptyDir` | `intelligentAssistant.runtimeVolume.emptyDir` | |
| `global.lightspeed.runtimeVolume.persistentVolumeClaim` | `intelligentAssistant.runtimeVolume.persistentVolumeClaim` | |
| `global.lightspeed.configMaps` | `intelligentAssistant.config.{stack,server,profile}.existingConfigMap` | Array replaced with structured per-file config |
| `global.lightspeed.secret.create` / `.name` | `intelligentAssistant.existingSecret` | Simplified to a secret name string |

### Orchestrator

| Old path | New path | Notes |
|----------|----------|-------|
| `orchestrator.enabled` | `orchestrator.enabled` | |
| `orchestrator.plugins` | `orchestrator.plugins` | |
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
| `test.enabled` | `test.enabled` | |
| `test.image.registry` | `test.image.registry` | |
| `test.image.repository` | `test.image.repository` | |
| `test.image.tag` | `test.image.tag` | Default changed from `latest` to a pinned version |
| `test.injectTestNpmrcSecret` | _(removed)_ | No longer needed |
