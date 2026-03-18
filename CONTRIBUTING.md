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

To sync with the upstream Backstage repository, add it as a remote on your local machine:

```bash
git remote add -f upstream-backstage https://github.com/backstage/charts.git
```

When the upstream Backstage team releases an update, we can pull their changes into our subtree:

```bash
git fetch upstream-backstage main
git subtree pull --prefix charts/backstage/vendor/backstage upstream-backstage main --squash

# You may also need to update the dependency version under charts/backstage/Chart.yaml
```

It is important to use `--squash` to avoid pulling the entire commit history of the upstream chart repository.

*Note: If merge conflicts occur, resolve them in your editor, then `git add` and `git commit` the resolution as a normal merge.*

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
