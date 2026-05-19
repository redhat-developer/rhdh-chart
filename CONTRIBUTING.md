# Contributing

## Checklist

Before making a contribution to the charts in this repository, you will need to ensure the following steps have been done:

- Run `helm template` on the changes you're making to ensure they are correctly rendered into Kubernetes manifests.
- Lint tests have been run for the Chart using the [Chart Testing](https://github.com/helm/chart-testing) tool and the `ct lint` command.
- For each Chart updated, version bumped in the corresponding `Chart.yaml` according to [Semantic Versioning](http://semver.org/).
- For each Chart updated, ensure variables are documented in the corresponding `values.yaml` file and the [pre-commit](https://pre-commit.com/) hook has been run with `pre-commit run --all-files` to generate the corresponding `README.md` documentation. The [pre-commit Workflow](./.github/workflows/pre-commit.yaml) will enforce this and warn you if needed.
- JSON Schema template updated and re-generated the raw schema via the `pre-commit` hook.
- [ ] If you updated the [orchestrator-infra](./charts/orchestrator-infra) chart, make sure the versions of the [Knative CRDs](./charts/orchestrator-infra/crds) are aligned with the versions of the CRDs installed by the OpenShift Serverless operators declared in the [values.yaml](./charts/orchestrator-infra/values.yaml) file. See [Installing Knative Eventing and Knative Serving CRDs](./charts/orchestrator-infra/README.md#installing-knative-eventing-and-knative-serving-crds) for more details.

## Note on the Backstage chart dependencies

This project uses a **Git Subtree** strategy to manage our dependency on the [upstream Backstage Helm chart](https://github.com/backstage/charts.git). This allows us to maintain local customizations while keeping a link to the upstream source for future updates.

Unlike standard Helm dependencies that fetch tarballs from a remote repository, our dependency on Backstage is **vendored** directly into this repository under [`charts/backstage/vendor/backstage`](./charts/backstage/vendor/backstage).

### Developer workflow

To sync with the upstream Backstage repository, use the [`hack/sync-upstream-backstage.sh`](./hack/sync-upstream-backstage.sh) script:

```bash
./hack/sync-upstream-backstage.sh
```

The script automatically:
1. Fetches the upstream remote (adding it if needed)
2. Generates a patch of RHDH-specific template modifications (e.g., Lightspeed integration, catalog index images)
3. Performs the subtree pull (which resets vendored files to upstream)
4. Re-applies the RHDH patch on top of the updated upstream
5. Restores `.gitignore` exceptions and vendored `.tgz` dependencies
6. Commits the result

You can customize the remote and branch:

```bash
./hack/sync-upstream-backstage.sh --remote upstream-backstage --ref main
```

If the RHDH patch fails to apply (because upstream changed the same lines), the script saves the patch to `rhdh-vendored.patch` in the repo root and exits with an error. To resolve:
1. Review the patch: `cat rhdh-vendored.patch`
2. Try 3-way merge: `git apply --3way rhdh-vendored.patch`
3. Or apply with rejects: `git apply --reject rhdh-vendored.patch`, then resolve any `.rej` files
4. Stage and commit the resolved files, then clean up: `rm rhdh-vendored.patch`

After syncing, you may also need to update the dependency version under `charts/backstage/Chart.yaml` and rebuild the lock file (see below).

> [!NOTE]
> The [weekly CI workflow](./.github/workflows/sync-upstream-backstage.yaml) uses this same script to sync automatically and open a PR.

### Sync Lightspeed vendored config files

The Lightspeed config files under [`charts/backstage/files/lightspeed`](./charts/backstage/files/lightspeed) are synced separately from the Backstage subtree by [`hack/sync-lightspeed-configs.sh`](./hack/sync-lightspeed-configs.sh).

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

**Important:** After any change to the dependency structure or version of the vendored chart, you must rebuild the lock file and local subchart dependencies:

```bash
helm dependency update charts/backstage/vendor/backstage/charts/backstage
helm dependency update charts/backstage
```

To contribute changes back to the upstream repo, you can push them directly to your personal fork of the upstream Backstage charts and open up a PR:

```bash
# Push to your personal fork of the upstream Backstage charts repo
git remote add my-upstream-fork ssh://git@github.com/${YOUR_USERNAME}/${MY_FORK}.git
git subtree push --prefix charts/backstage/vendor/backstage my-upstream-fork ${MY_BRANCH}

# Open up a PR on the upstream Backstage charts repository
```
