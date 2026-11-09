#!/usr/bin/env bash
#
# Renders the rhdh chart with `helm template` and asserts the values that a
# constrained cluster (mirrored registry only, no default StorageClass) relies on:
#   - global.imageRegistry is applied to every rendered image reference,
#   - the helm test pod image follows test.image.*,
#   - the dynamic plugins volume honours the StorageClass settings.
#
# Usage: hack/assert-rendered-values.sh [chart-dir]   (default: charts/rhdh)
# Requires helm and yq (mikefarah v4); run `helm dependency build <chart-dir>` first.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CHART="${1:-${REPO_ROOT}/charts/rhdh}"
MIRROR="mirror.local"

failures=0
checks=0

pass() {
  checks=$((checks + 1))
  echo "  ok: $1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  echo "  FAIL: $1" >&2
}

render() {
  helm template test-release "${CHART}" "$@"
}

# Prints every image reference in the rendered manifests: `image` string fields
# (containers, initContainers, test pod, CRs) and *_IMAGE / *_IMAGES env values.
list_images() {
  yq -N '
    (.. | select(tag == "!!map" and has("image")) | .image | select(tag == "!!str")),
    (.. | select(tag == "!!map" and has("name") and has("value"))
        | select(.name | test("_IMAGES?$")) | .value | select(tag == "!!str")
        | split(",") | .[] | sub("^[^=/]+=", ""))
  ' | { grep -v '^$' || true; } | sort -u
}

assert_images_mirrored() {
  local label=$1
  shift
  local images
  images=$(render --set global.imageRegistry="${MIRROR}" "$@" | list_images)
  if [[ -z "${images}" ]]; then
    fail "${label}: no image references found in the rendered output"
    return
  fi
  local bad
  bad=$(grep -v "^${MIRROR//./\\.}/" <<<"${images}" || true)
  if [[ -n "${bad}" ]]; then
    fail "${label}: images not under ${MIRROR}/: $(tr '\n' ' ' <<<"${bad}")"
  else
    pass "${label}: $(wc -l <<<"${images}" | tr -d ' ') images under ${MIRROR}/"
  fi
}

assert_equals() {
  local label=$1 expected=$2 actual=$3
  if [[ "${actual}" == "${expected}" ]]; then
    pass "${label}"
  else
    fail "${label}: expected '${expected}', got '${actual}'"
  fi
}

plugins_root_volume() {
  yq -N 'select(.kind == "Deployment") | .spec.template.spec.volumes[] | select(.name == "dynamic-plugins-root")'
}

echo "==> global.imageRegistry=${MIRROR} applies to every rendered image"
assert_images_mirrored "default values"
for ci_values in "${CHART}"/ci/*-values.yaml; do
  [[ -f "${ci_values}" ]] || continue
  assert_images_mirrored "$(basename "${ci_values}")" --values "${ci_values}"
done
# Optional images that no CI scenario enables.
assert_images_mirrored "optional images enabled" \
  --set intelligentAssistant.okp.enabled=true \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.dataIndex.image.registry=quay.io \
  --set orchestrator.sonataflowPlatform.dataIndex.image.repository=ci/data-index \
  --set orchestrator.sonataflowPlatform.dataIndex.image.tag=1.0 \
  --set orchestrator.sonataflowPlatform.jobService.image.registry=quay.io \
  --set orchestrator.sonataflowPlatform.jobService.image.repository=ci/jobs-service \
  --set orchestrator.sonataflowPlatform.jobService.image.tag=1.0 \
  --set 'catalogIndex.extraImages[0].name=community' \
  --set 'catalogIndex.extraImages[0].registry=ghcr.io' \
  --set 'catalogIndex.extraImages[0].repository=ci/community-index' \
  --set 'catalogIndex.extraImages[0].tag=1.0' \
  --set 'catalogIndex.extraImages[1].registry=ghcr.io' \
  --set 'catalogIndex.extraImages[1].repository=ci/other-index' \
  --set 'catalogIndex.extraImages[1].tag=1.0'

echo "==> helm test pod image follows test.image.*"
test_image=$(render \
  --set test.image.registry=registry.example.test \
  --set test.image.repository=ci/curl \
  --set test.image.tag=9.9.9 |
  yq -N 'select(.metadata.annotations["helm.sh/hook"] == "test") | .spec.containers[].image')
assert_equals "test pod image" "registry.example.test/ci/curl:9.9.9" "${test_image}"

echo "==> dynamic plugins volume StorageClass"
# Default is an ephemeral claim with no storageClassName, so the cluster default applies.
spec_keys=$(render | plugins_root_volume | yq -N '.ephemeral.volumeClaimTemplate.spec // {} | keys | sort | join(",")')
assert_equals "ephemeral, nothing set: no storageClassName (cluster default)" "accessModes,resources" "${spec_keys}"

sc=$(render --set dynamicPlugins.volume.ephemeral.storageClassName=custom-sc |
  plugins_root_volume | yq -N '.ephemeral.volumeClaimTemplate.spec.storageClassName')
assert_equals "ephemeral.storageClassName" "custom-sc" "${sc}"

sc=$(render --set global.defaultStorageClass=global-sc |
  plugins_root_volume | yq -N '.ephemeral.volumeClaimTemplate.spec.storageClassName')
assert_equals "global.defaultStorageClass" "global-sc" "${sc}"

sc=$(render --set global.defaultStorageClass=global-sc \
  --set dynamicPlugins.volume.ephemeral.storageClassName=custom-sc |
  plugins_root_volume | yq -N '.ephemeral.volumeClaimTemplate.spec.storageClassName')
assert_equals "ephemeral.storageClassName overrides global.defaultStorageClass" "custom-sc" "${sc}"

sc=$(render \
  --set workload.kind=StatefulSet \
  --set dynamicPlugins.volume.type=statefulSetPVC \
  --set dynamicPlugins.volume.statefulSetPVC.storageClassName=custom-sc |
  yq -N 'select(.kind == "StatefulSet") | .spec.volumeClaimTemplates[]
    | select(.metadata.name == "dynamic-plugins-root") | .spec.storageClassName')
assert_equals "statefulSetPVC.storageClassName" "custom-sc" "${sc}"

# emptyDir must not create any claim, even when a StorageClass is configured.
out=$(render --set dynamicPlugins.volume.type=emptyDir \
  --set dynamicPlugins.volume.ephemeral.storageClassName=custom-sc)
vol=$(plugins_root_volume <<<"${out}" | yq -N -o=json -I=0 'keys | sort')
assert_equals "type=emptyDir: plugins volume is an emptyDir" '["emptyDir","name"]' "${vol}"
claims=$(yq ea -N '[select(.kind == "PersistentVolumeClaim"),
  (.. | select(tag == "!!map" and has("volumeClaimTemplate")))]
  | length' <<<"${out}")
assert_equals "type=emptyDir: no PVC or ephemeral claim rendered" "0" "${claims}"

echo
if ((failures > 0)); then
  echo "${failures} of ${checks} rendered-values assertions failed" >&2
  exit 1
fi
echo "All ${checks} rendered-values assertions passed"
