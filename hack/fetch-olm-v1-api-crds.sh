#!/usr/bin/env bash

set -euo pipefail

OPERATOR_CONTROLLER_VERSION="${OPERATOR_CONTROLLER_VERSION:-v1.11.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/.github/fixtures/olm-v1-api-crds.yaml"
UPSTREAM_URL="https://github.com/operator-framework/operator-controller/releases/download/${OPERATOR_CONTROLLER_VERSION}/operator-controller.yaml"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--check]

Fetches OLM v1 API CRDs (CustomResourceDefinition only) from operator-controller
${OPERATOR_CONTROLLER_VERSION} and writes ${OUTPUT_FILE#"${REPO_ROOT}/"}.

  --check   Fail if the committed fixture CRDs differ from upstream.

Environment:
  OPERATOR_CONTROLLER_VERSION   Release tag (default: v1.11.0)
EOF
}

check_only=false
if [[ "${1:-}" == "--check" ]]; then
  check_only=true
elif [[ -n "${1:-}" ]]; then
  usage >&2
  exit 2
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required (see https://github.com/mikefarah/yq)" >&2
  exit 1
fi

canonical_crds() {
  local source_file=$1
  yq -o=json -I=0 ea 'select(.kind == "CustomResourceDefinition")' "${source_file}"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

curl -fsSL --proto '=https' "${UPSTREAM_URL}" -o "${tmpdir}/operator-controller.yaml"
upstream_canonical="$(canonical_crds "${tmpdir}/operator-controller.yaml")"

if [[ "${check_only}" == true ]]; then
  if [[ ! -f "${OUTPUT_FILE}" ]]; then
    echo "Missing ${OUTPUT_FILE#"${REPO_ROOT}/"}" >&2
    exit 1
  fi
  if [[ "$(canonical_crds "${OUTPUT_FILE}")" != "${upstream_canonical}" ]]; then
    echo "Fixture CRDs differ from operator-controller ${OPERATOR_CONTROLLER_VERSION}." >&2
    echo "Run ./hack/fetch-olm-v1-api-crds.sh and commit the result." >&2
    exit 1
  fi
  echo "Fixture matches operator-controller ${OPERATOR_CONTROLLER_VERSION} CRDs."
  exit 0
fi

yq ea 'select(.kind == "CustomResourceDefinition")' "${tmpdir}/operator-controller.yaml" \
  > "${tmpdir}/crds.yaml"
sha256="$(printf '%s' "${upstream_canonical}" | sha256sum | awk '{print $1}')"

{
  cat <<EOF
# OLM v1 API CRDs for orchestrator-infra chart-testing (olmVersion=v1).
# Source: operator-framework/operator-controller ${OPERATOR_CONTROLLER_VERSION} (CRDs only; controller not installed).
# Regenerate: ./hack/fetch-olm-v1-api-crds.sh
# Upstream: https://github.com/operator-framework/operator-controller/releases/tag/${OPERATOR_CONTROLLER_VERSION}
# sha256(crds): ${sha256}
EOF
  cat "${tmpdir}/crds.yaml"
} > "${OUTPUT_FILE}"

echo "Wrote ${OUTPUT_FILE#"${REPO_ROOT}/"} (sha256(crds)=${sha256})"
