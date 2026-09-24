# CI fixtures

## OLM v1 API CRDs (`olm-v1-api-crds.yaml`)

KinD chart-testing for `charts/orchestrator-infra` with `olmVersion: v1` needs the OLM v1 API CRDs (`ClusterCatalog`, `ClusterExtension`) so `ClusterExtension` manifests can be admitted. The full `operator-controller` is not installed in CI—only these CRD definitions.

**Update when bumping OLM v1 API version:**

1. Set `OPERATOR_CONTROLLER_VERSION` if needed (default `v1.11.0` in the script).
2. From the repo root: `./hack/fetch-olm-v1-api-crds.sh`
3. Commit the updated `olm-v1-api-crds.yaml`.

**Verify without writing:**

```bash
./hack/fetch-olm-v1-api-crds.sh --check
```

The script downloads the upstream release manifest, keeps `CustomResourceDefinition` objects only, and records a `sha256(crds)` line in the file header.
