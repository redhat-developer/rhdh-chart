# RHDH Backstage Helm Chart for OpenShift

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/janus-idp&style=flat-square)](https://artifacthub.io/packages/search?repo=janus-idp)
![Version: 2.15.0](https://img.shields.io/badge/Version-2.15.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart for deploying RHDH (a Backstage application)

**Homepage:** <https://redhat-developer.github.io/rhdh-chart/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Red Hat Developer Hub Team |  | <https://github.com/redhat-developer/rhdh-chart> |

## Source Code

* <https://github.com/redhat-developer/rhdh-chart>
* <https://github.com/janus-idp/backstage-showcase>

---

RHDH Backstage chart is an opinionated flavor of the upstream chart located at [backstage/charts](https://github.com/backstage/charts). It extends the upstream chart with additional OpenShift specific functionality and provides opinionated values.

[Backstage](https://backstage.io) is an open platform for building developer portals. Powered by a centralized software catalog, Backstage restores order to your microservices and infrastructure and enables your product teams to ship high-quality code quickly — without compromising autonomy.

Backstage unifies all your infrastructure tooling, services, and documentation to create a streamlined development environment from end to end.

**This chart offers an opinionated OpenShift-specific experience.** It is based on and directly depends on an upstream canonical [Backstage Helm chart](https://github.com/backstage/charts/tree/main/charts/backstage). For less opinionated experience, please consider using the upstream chart directly.

This chart extends all the features in the upstream chart in addition to including OpenShift only features. It is not recommended to use this chart on other platforms.

## Usage

Charts are available in the following formats:

- [Chart Repository](https://helm.sh/docs/topics/chart_repository/)
- [OCI Artifacts](https://helm.sh/docs/topics/registries/)

### Installing from the Chart Repository

The following command can be used to add the chart repository:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add backstage https://backstage.github.io/charts
helm repo add redhat-developer https://redhat-developer.github.io/rhdh-chart
```

Once the chart has been added, install this chart. However before doing so, please review the default `values.yaml` and adjust as needed.

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

Charts are also available in OCI format. The list of available releases can be found [here](https://github.com/orgs/redhat-developer/packages/container/package/rhdh-chart%2Fbackstage).

Install one of the available versions:

```shell
helm upgrade -i <release_name> oci://ghcr.io/redhat-developer/rhdh-chart/backstage --version=<version>
```

## Backstage Chart

More information can be found by inspecting the [backstage chart](charts/backstage).

## Telemetry data collection

The telemetry data collection feature is enabled by default. Red Hat Developer Hub sends telemetry data to Red Hat by using the `backstage-plugin-analytics-provider-segment` plugin. To disable this and to learn what data is being collected, see https://access.redhat.com/documentation/en-us/red_hat_developer_hub/1.2/html-single/administration_guide_for_red_hat_developer_hub/index#assembly-rhdh-telemetry_admin-rhdh
