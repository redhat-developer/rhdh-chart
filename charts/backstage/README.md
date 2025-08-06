
# RHDH Backstage Helm Chart for OpenShift

![Version: 4.5.3](https://img.shields.io/badge/Version-4.5.3-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart for deploying Red Hat Developer Hub, which is a Red Hat supported version of Backstage.

The telemetry data collection feature is enabled by default. Red Hat Developer Hub sends telemetry data to Red Hat by using the `backstage-plugin-analytics-provider-segment` plugin. To disable this and to learn what data is being collected, see https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.6/html-single/telemetry_data_collection_and_analysis/index

**Homepage:** <https://red.ht/rhdh>

## Productized RHDH

This repository now provides the productized RHDH chart.
For the **GENERALLY AVAILABLE** version of this chart, see:

* https://github.com/openshift-helm-charts/charts - official releases to https://charts.openshift.io/

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat |  | <https://redhat.com> |

## TL;DR

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add backstage https://backstage.github.io/charts
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install my-backstage redhat-developer/backstage
```

## Introduction

This chart bootstraps a [Backstage](https://backstage.io/docs/deployment/docker) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.27+ ([OpenShift 4.14+](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/release_notes/index#ocp-4-14-about-this-release))
- Helm 3.10+ or [latest release](https://github.com/helm/helm/releases)
- PV provisioner support in the underlying infrastructure
- [Backstage container image](https://backstage.io/docs/deployment/docker)

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
helm repo add backstage https://backstage.github.io/charts
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart
```

Once the chart has been added, install this chart. However before doing so, please review the default `values.yaml` and adjust as needed.

- To get proper connection between frontend and backend of Backstage please update the `apps.example.com` to match your cluster host:

   ```yaml
   global:
     clusterRouterBase: apps.example.com
   ```

   > Tip: you can use `helm upgrade -i --set global.clusterRouterBase=apps.example.com ...` instead of a value file

- If your cluster doesn't provide PVCs, you should disable PostgreSQL persistence via:

   ```yaml
   upstream:
     postgresql:
       primary:
         persistence:
           enabled: false
   ```

```console
helm upgrade -i <release_name> redhat-developer/backstage
```

### Installing from an OCI Registry

Note: this repo replaces https://github.com/janus-idp/helm-backstage, which has been deprecated in Feb 2024.

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

You can control whether to disable this test pod or you can also customize the image it leverages.
See the `test.enabled` and `test.image` parameters in the [`values.yaml`](./values.yaml) file.

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

To uninstall/delete the `my-backstage-release` deployment:

```console
helm uninstall my-backstage-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Requirements

Kubernetes: `>= 1.27.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://backstage.github.io/charts | upstream(backstage) | 2.6.0 |
| https://charts.bitnami.com/bitnami | common | 2.31.3 |

## Values

| Key | Description | Type | Default |
|-----|-------------|------|---------|
| global.auth | Enable service authentication within Backstage instance | object | `{"backend":{"enabled":true,"existingSecret":"","value":""}}` |
| global.auth.backend | Backend service to service authentication <br /> Ref: https://backstage.io/docs/auth/service-to-service-auth/ | object | `{"enabled":true,"existingSecret":"","value":""}` |
| global.auth.backend.enabled | Enable backend service to service authentication, unless configured otherwise it generates a secret value | bool | `true` |
| global.auth.backend.existingSecret | Instead of generating a secret value, refer to existing secret | string | `""` |
| global.auth.backend.value | Instead of generating a secret value, use the following value | string | `""` |
| global.clusterRouterBase | Shorthand for users who do not want to specify a custom HOSTNAME. Used ONLY with the DEFAULT upstream.backstage.appConfig value and with OCP Route enabled. | string | `"apps.example.com"` |
| global.dynamic.includes | Array of YAML files listing dynamic plugins to include with those listed in the `plugins` field. Relative paths are resolved from the working directory of the initContainer that will install the plugins (`/opt/app-root/src`). | list | `["dynamic-plugins.default.yaml"]` |
| global.dynamic.includes[0] | List of dynamic plugins included inside the `janus-idp/backstage-showcase` container image, some of which are disabled by default. This file ONLY works with the `janus-idp/backstage-showcase` container image. | string | `"dynamic-plugins.default.yaml"` |
| global.dynamic.plugins | List of dynamic plugins, possibly overriding the plugins listed in `includes` files. Every item defines the plugin `package` as a [NPM package spec](https://docs.npmjs.com/cli/v10/using-npm/package-spec), an optional `pluginConfig` with plugin-specific backstage configuration, and an optional `disabled` flag to disable/enable a plugin listed in `includes` files. It also includes an `integrity` field that is used to verify the plugin package [integrity](https://w3c.github.io/webappsec-subresource-integrity/#integrity-metadata-description). | list | `[]` |
| global.host | Custom hostname shorthand, overrides `global.clusterRouterBase`, `upstream.ingress.host`, `route.host`, and url values in `upstream.backstage.appConfig`. | string | `""` |
| nameOverride |  | string | `"developer-hub"` |
| orchestrator.enabled |  | bool | `false` |
| orchestrator.plugins | Orchestrator plugins and their configuration | list | `[{"disabled":false,"integrity":"sha512-Kr55YbuVwEADwGef9o9wyimcgHmiwehPeAtVHa9g2RQYoSPEa6BeOlaPzB6W5Ke3M2bN/0j0XXtpLuvrlXQogA==","package":"https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator-backend-dynamic/-/backstage-plugin-orchestrator-backend-dynamic-1.6.0.tgz","pluginConfig":{"orchestrator":{"dataIndexService":{"url":"http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}"}}}},{"disabled":false,"integrity":"sha512-fOSJv2PgtD2urKwBM7p9W6gV/0UIHSf4pkZ9V/wQO0eg0Zi5Mys/CL1ba3nO9x9l84MX11UBZ2r7PPVJPrmOtw==","package":"https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator/-/backstage-plugin-orchestrator-1.6.0.tgz","pluginConfig":{"dynamicPlugins":{"frontend":{"red-hat-developer-hub.backstage-plugin-orchestrator":{"appIcons":[{"importName":"OrchestratorIcon","name":"orchestratorIcon"}],"dynamicRoutes":[{"importName":"OrchestratorPage","menuItem":{"icon":"orchestratorIcon","text":"Orchestrator"},"path":"/orchestrator"}]}}}}},{"disabled":false,"integrity":"sha512-Bueeix4661fXEnfJ9y31Yw91LXJgw6hJUG7lPVdESCi9VwBCjDB9Rm8u2yPqP8sriwr0OMtKtqD+Odn3LOPyVw==","package":"https://npm.registry.redhat.com/@redhat/backstage-plugin-scaffolder-backend-module-orchestrator-dynamic/-/backstage-plugin-scaffolder-backend-module-orchestrator-dynamic-1.6.0.tgz","pluginConfig":{"orchestrator":{"dataIndexService":{"url":"http://sonataflow-platform-data-index-service.{{ .Release.Namespace }}"}}}},{"disabled":false,"integrity":"sha512-Tqn6HO21Q1TQ7TFUoRhwBVCtSBzbQYz+OaanzzIB0R24O6YtVx3wR7Chtr5TzC05Vz5GkBO1+FZid8BKpqljgA==","package":"https://npm.registry.redhat.com/@redhat/backstage-plugin-orchestrator-form-widgets/-/backstage-plugin-orchestrator-form-widgets-1.6.0.tgz","pluginConfig":{"dynamicPlugins":{"frontend":{"red-hat-developer-hub.backstage-plugin-orchestrator-form-widgets":{}}}}}]` |
| orchestrator.serverlessLogicOperator.enabled |  | bool | `true` |
| orchestrator.serverlessOperator.enabled |  | bool | `true` |
| orchestrator.sonataflowPlatform.createDBJobImage | Image for the container used by the create-db job | string | `"{{ .Values.upstream.postgresql.image.registry }}/{{ .Values.upstream.postgresql.image.repository }}:{{ .Values.upstream.postgresql.image.tag }}"` |
| orchestrator.sonataflowPlatform.eventing.broker.name |  | string | `""` |
| orchestrator.sonataflowPlatform.eventing.broker.namespace |  | string | `""` |
| orchestrator.sonataflowPlatform.externalDBHost | Host for the user-configured external Database | string | `""` |
| orchestrator.sonataflowPlatform.externalDBName | Name for the user-configured external Database | string | `""` |
| orchestrator.sonataflowPlatform.externalDBPort | Port for the user-configured external Database | string | `""` |
| orchestrator.sonataflowPlatform.externalDBsecretRef | Secret name for the user-created secret to connect an external DB | string | `""` |
| orchestrator.sonataflowPlatform.initContainerImage | Image for the init container used by the create-db job | string | `"{{ .Values.upstream.postgresql.image.registry }}/{{ .Values.upstream.postgresql.image.repository }}:{{ .Values.upstream.postgresql.image.tag }}"` |
| orchestrator.sonataflowPlatform.monitoring.enabled |  | bool | `true` |
| orchestrator.sonataflowPlatform.resources.limits.cpu |  | string | `"500m"` |
| orchestrator.sonataflowPlatform.resources.limits.memory |  | string | `"1Gi"` |
| orchestrator.sonataflowPlatform.resources.requests.cpu |  | string | `"250m"` |
| orchestrator.sonataflowPlatform.resources.requests.memory |  | string | `"64Mi"` |
| route | OpenShift Route parameters | object | `{"annotations":{},"enabled":true,"host":"{{ .Values.global.host }}","path":"/","tls":{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"},"wildcardPolicy":"None"}` |
| route.annotations | Route specific annotations | object | `{}` |
| route.enabled | Enable the creation of the route resource | bool | `true` |
| route.host | Set the host attribute to a custom value. If not set, OpenShift will generate it, please make sure to match your baseUrl | string | `"{{ .Values.global.host }}"` |
| route.path | Path that the router watches for, to route traffic for to the service. | string | `"/"` |
| route.tls | Route TLS parameters <br /> Ref: https://docs.openshift.com/container-platform/4.9/networking/routes/secured-routes.html | object | `{"caCertificate":"","certificate":"","destinationCACertificate":"","enabled":true,"insecureEdgeTerminationPolicy":"Redirect","key":"","termination":"edge"}` |
| route.tls.caCertificate | Cert authority certificate contents. Optional | string | `""` |
| route.tls.certificate | Certificate contents | string | `""` |
| route.tls.destinationCACertificate | Contents of the ca certificate of the final destination. <br /> When using reencrypt termination this file should be provided in order to have routers use it for health checks on the secure connection. If this field is not specified, the router may provide its own destination CA and perform hostname validation using the short service name (service.namespace.svc), which allows infrastructure generated certificates to automatically verify. | string | `""` |
| route.tls.enabled | Enable TLS configuration for the host defined at `route.host` parameter | bool | `true` |
| route.tls.insecureEdgeTerminationPolicy | Indicates the desired behavior for insecure connections to a route. <br /> While each router may make its own decisions on which ports to expose, this is normally port 80. The only valid values are None, Redirect, or empty for disabled. | string | `"Redirect"` |
| route.tls.key | Key file contents | string | `""` |
| route.tls.termination | Specify TLS termination. | string | `"edge"` |
| route.wildcardPolicy | Wildcard policy if any for the route. Currently only 'Subdomain' or 'None' is allowed. | string | `"None"` |
| test | Test pod parameters | object | `{"enabled":true,"image":{"registry":"quay.io","repository":"curl/curl","tag":"latest"},"injectTestNpmrcSecret":false}` |
| test.enabled | Whether to enable the test-connection pod used for testing the Release using `helm test`. | bool | `true` |
| test.image.registry | Test connection pod image registry | string | `"quay.io"` |
| test.image.repository | Test connection pod image repository. Note that the image needs to have both the `sh` and `curl` binaries in it. | string | `"curl/curl"` |
| test.image.tag | Test connection pod image tag. Note that the image needs to have both the `sh` and `curl` binaries in it. | string | `"latest"` |
| test.injectTestNpmrcSecret | Whether to inject a fake dynamic plugins npmrc secret. <br />See RHDHBUGS-1893 and RHDHBUGS-1464 for the motivation behind this. <br />This is only used for testing purposes and should not be used in production. <br />Only relevant when `test.enabled` field is set to `true`. | bool | `false` |
| upstream | Upstream Backstage [chart configuration](https://github.com/backstage/charts/blob/main/charts/backstage/values.yaml) | object | Use Openshift compatible settings |
| upstream.backstage.extraVolumes[0] | Ephemeral volume that will contain the dynamic plugins installed by the initContainer below at start. | object | `{"ephemeral":{"volumeClaimTemplate":{"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}}}}},"name":"dynamic-plugins-root"}` |
| upstream.backstage.extraVolumes[0].ephemeral.volumeClaimTemplate.spec.resources.requests.storage | Size of the volume that will contain the dynamic plugins. It should be large enough to contain all the plugins. | string | `"5Gi"` |
| upstream.backstage.initContainers[0].image | Image used by the initContainer to install dynamic plugins into the `dynamic-plugins-root` volume mount. It could be replaced by a custom image based on this one. | string | `quay.io/janus-idp/backstage-showcase:latest` |

## Opinionated Backstage deployment

This chart defaults to an opinionated deployment of Backstage that provides user with a usable Backstage instance out of the box.

Features enabled by the default chart configuration:

1. Uses [janus-idp/backstage-showcase](https://github.com/janus-idp/backstage-showcase/) that pre-loads a lot of useful plugins and features
2. Exposes a `Route` for easy access to the instance
3. Enables OpenShift-compatible PostgreSQL database storage

For additional instance features please consult the [documentation for `janus-idp/backstage-showcase`](https://github.com/janus-idp/backstage-showcase/tree/main/showcase-docs).

Additional features can be enabled by extending the default configuration at:

```yaml
upstream:
  backstage:
    appConfig:
      # Inline app-config.yaml for the instance
    extraEnvVars:
      # Additional environment variables
```

## Features

This charts defaults to using the [latest Janus-IDP Backstage Showcase image](https://quay.io/janus-idp/backstage-showcase:latest) that is OpenShift compatible:

```console
quay.io/janus-idp/backstage-showcase:latest
```

Additionally this chart enhances the upstream Backstage chart with following OpenShift-specific features:

### OpenShift Routes

This chart offers a drop-in replacement for the `Ingress` resource already provided by the upstream chart via an OpenShift `Route`.

OpenShift routes are enabled by default. In order to use the chart without it, please set `route.enabled` to `false` and switch to the `Ingress` resource via `upstream.ingress` values.

Routes can be further configured via the `route` field.

To manually provide the Backstage pod with the right context, please add the following value:

```yaml
# values.yaml
global:
  clusterRouterBase: apps.example.com
```

> Tip: you can use `helm upgrade -i --set global.clusterRouterBase=apps.example.com ...` instead of a value file

Custom hosts are also supported via the following shorthand:

```yaml
# values.yaml
global:
  host: backstage.example.com
```

> Note: Setting either `global.host` or `global.clusterRouterBase` will disable the automatic hostname discovery.
        When both fields are set, `global.host` will take precedence.
        These are just templating shorthands. For full manual configuration please pay attention to values under the `route` key.

Any custom modifications to how backstage is being exposed may require additional changes to the `values.yaml`:

```yaml
# values.yaml
upstream:
  backstage:
    appConfig:
      app:
        baseUrl: 'https://{{- include "janus-idp.hostname" . }}'
      backend:
        baseUrl: 'https://{{- include "janus-idp.hostname" . }}'
        cors:
          origin: 'https://{{- include "janus-idp.hostname" . }}'
```

### Vanilla Kubernetes compatibility mode

In order to deploy this chart on vanilla Kubernetes or any other non-OCP platform, please make sure to apply the following changes. Note that further customizations may be required, depending on your exact Kubernetes setup:

```yaml
# values.yaml
global:
  host: # Specify your own Ingress host
route:
  enabled: false  # OpenShift Routes do not exist on vanilla Kubernetes
upstream:
  ingress:
    enabled: true  # Use Kubernetes Ingress instead of OpenShift Route
  backstage:
    podSecurityContext:  # Vanilla Kubernetes doesn't feature OpenShift default SCCs with dynamic UIDs, adjust accordingly to the deployed image
      runAsUser: 1001
      runAsGroup: 1001
      fsGroup: 1001
  postgresql:
    primary:
      podSecurityContext:
        enabled: true
        fsGroup: 26
        runAsUser: 26
    volumePermissions:
      enabled: true
```

## Installing RHDH with Orchestrator on OpenShift

Orchestrator brings serverless workflows into Backstage, focusing on the journey for application migration to the cloud, onboarding developers, and user-made workflows of Backstage actions or external systems.
Orchestrator is a flavor of RHDH, and can be installed alongside RHDH in the same namespace and in the following way:

1. Have an admin install the [orchestrator-infra Helm Chart](https://github.com/redhat-developer/rhdh-chart/tree/main/charts/orchestrator-infra#readme), which will install the prerequisites required to deploy the Orchestrator-flavored RHDH. This process will include installing cluster-wide resources, so should be done with admin privileges:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add backstage https://backstage.github.io/charts
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart

helm install <release_name> redhat-developer/redhat-developer-hub-orchestrator-infra
```
2. Manually approve the Install Plans created by the chart, and wait for the Openshift Serverless and Openshift Serverless Logic Operators to be deployed. To do so, follow the post-install notes given by the chart, or see them [here](https://github.com/redhat-developer/rhdh-chart/blob/main/charts/orchestrator-infra/templates/NOTES.txt)
3. Install the `backstage` chart with Helm, enabling orchestrator, like so:

```
helm install <release_name> redhat-developer/backstage --set orchestrator.enabled=true
```
Note that serverlessLogicOperator, and serverlessOperator are enabled by default. They can be disabled together or seperately by passing the following flags:
`--set orchestrator.serverlessLogicOperator.enabled=false --set orchestrator.serverlessOperator.enabled=false`

### Enablement of Notifications Plugin

Workflows running with Orchestrator may use the Notifications plugin.
For this, you must enable the Notifications and Signals plugins.
To do so, you would need to edit the [default Helm values.yaml](https://github.com/redhat-developer/rhdh-chart/blob/main/charts/backstage/values.yaml) file, and add the plugins listed below to the global.dynamic.plugins list.
Do this before installing the Helm Chart, or upgrade the Helm release with the new values file.

```yaml
- disabled: false
  package: "./dynamic-plugins/dist/backstage-plugin-notifications"
- disabled: false
  package: "./dynamic-plugins/dist/backstage-plugin-signals"
- disabled: false
  package: "./dynamic-plugins/dist/backstage-plugin-notifications-backend-dynamic"
- disabled: false
  package: "./dynamic-plugins/dist/backstage-plugin-signals-backend-dynamic"
```
Enabling these plugins will allow you to recieve notifications from workflows running with Orchestrator.

### Using Orchestrator while configuring an ExternalDB

To use orchestrator with an external DB, please follow the instructions in [our documentation](https://github.com/redhat-developer/rhdh-chart/blob/main/docs/external-db.md)
and populate the following values in the values.yaml:
```bash
    externalDBsecretRef: <cred-secret>
    externalDBName: ""
    externalDBHost: ""
    externalDBPort: ""
```
The values for externalDBHost and externalDBPort should match the ones configured in the cred-secret.

Please note that `externalDBName` is the name of the user-configured existing database, not the database that the orchestrator and sonataflow resources will use.
A Job will run to create the 'sonataflow' database in the external database for the workflows to use.

Finally, install the Helm Chart (including [setting up the external DB](https://github.com/redhat-developer/rhdh-chart/blob/main/docs/external-db.md)):
```
helm install <release_name> redhat-developer/backstage \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.externalDBsecretRef=<cred-secret> \
  --set orchestrator.sonataflowPlatform.externalDBName=example \
  --set orchestrator.sonataflowPlatform.externalDBHost=example \
  --set orchestrator.sonataflowPlatform.externalDBPort=example
```