#!/usr/bin/env bash

set -euo pipefail

OPERATOR_CONTROLLER_VERSION="${OPERATOR_CONTROLLER_VERSION:-v1.11.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/.github/fixtures/olm-v1-api-crds.yaml"
UPSTREAM_URL="https://github.com/operator-framework/operator-controller/releases/download/${OPERATOR_CONTROLLER_VERSION}/operator-controller.yaml"

if [[ -n "${1:-}" ]]; then
  echo "Usage: $(basename "$0")" >&2
  exit 2
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required (see https://github.com/mikefarah/yq)" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

curl -fsSL --proto '=https' "${UPSTREAM_URL}" -o "${tmpdir}/operator-controller.yaml"
yq ea 'select(.kind == "CustomResourceDefinition")' "${tmpdir}/operator-controller.yaml" \
  > "${tmpdir}/crds.yaml"

{
  cat <<EOF
# OLM v1 API CRDs for orchestrator-infra chart-testing (olmVersion=v1).
# Source: operator-framework/operator-controller ${OPERATOR_CONTROLLER_VERSION} (CRDs only; controller not installed).
# Regenerate from repo root: hack/fetch-olm-v1-api-crds.sh
# See charts/orchestrator-infra/README.md — "OLM v1 API CRDs (chart-testing CI)".
# Upstream: https://github.com/operator-framework/operator-controller/releases/tag/${OPERATOR_CONTROLLER_VERSION}
EOF
  cat "${tmpdir}/crds.yaml"
} > "${OUTPUT_FILE}"

echo "Wrote ${OUTPUT_FILE#"${REPO_ROOT}/"}"
