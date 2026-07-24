# Contributing

## Checklist

Before making a contribution to the charts in this repository, you will need to ensure the following steps have been done:

- Run `helm template` on the changes you're making to ensure they are correctly rendered into Kubernetes manifests.
- Lint tests have been run for the Chart using the [Chart Testing](https://github.com/helm/chart-testing) tool and the `ct lint` command.
- For each Chart updated, version bumped in the corresponding `Chart.yaml` according to [Semantic Versioning](http://semver.org/).
- For each Chart updated, ensure variables are documented in the corresponding `values.yaml` file and the [pre-commit](https://pre-commit.com/) hook has been run with `pre-commit run --all-files` to generate the corresponding `README.md` documentation. The [pre-commit Workflow](./.github/workflows/pre-commit.yaml) will enforce this and warn you if needed.
- JSON Schema template updated and re-generated the raw schema via the `pre-commit` hook.
- [ ] If you updated the [orchestrator-infra](./charts/orchestrator-infra) chart, make sure the versions of the [Knative CRDs](./charts/orchestrator-infra/crds) are aligned with the versions of the CRDs installed by the OpenShift Serverless operators declared in the [values.yaml](./charts/orchestrator-infra/values.yaml) file. See [Installing Knative Eventing and Knative Serving CRDs](./charts/orchestrator-infra/README.md#installing-knative-eventing-and-knative-serving-crds) for more details.

## Sync Lightspeed vendored config files

The Lightspeed config files under [`charts/rhdh/files/lightspeed`](./charts/rhdh/files/lightspeed) are synced from the upstream [redhat-ai-dev/lightspeed-configs](https://github.com/redhat-ai-dev/lightspeed-configs) repository by [`hack/sync-lightspeed-configs.sh`](./hack/sync-lightspeed-configs.sh).

Use the default upstream branch:

```bash
./hack/sync-lightspeed-configs.sh
```

Sync from a release branch or a tag:

```bash
./hack/sync-lightspeed-configs.sh --ref release-1.9
./hack/sync-lightspeed-configs.sh --ref v0.5.0
```

Verify the vendored files are already in sync without writing changes:

```bash
./hack/sync-lightspeed-configs.sh --ref main --check
```

The script copies the upstream config files directly, except it appends the chart-managed `mcp_servers` block to `lightspeed-stack.yaml` and renders `secret.yaml` from upstream `env/default-values.env` by dropping comment lines plus `LIGHTSPEED_CORE_IMAGE` and `RAG_CONTENT_IMAGE`, then converting each remaining `KEY=value` line into the chart's YAML secret payload.
Choose the upstream branch or tag that matches the Lightspeed release you want to vendor.
