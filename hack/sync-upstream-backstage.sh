#!/usr/bin/env bash
#
# Sync the vendored Backstage chart from upstream while preserving
# RHDH-specific template modifications.
#
# Usage:
#   ./hack/sync-upstream-backstage.sh [OPTIONS]
#
# Options:
#   --remote <name>   Git remote for upstream Backstage charts (default: upstream-backstage)
#   --ref <branch>    Upstream branch to sync from (default: main)
#   --prefix <path>   Subtree prefix (default: charts/backstage/vendor/backstage)
#
# The script:
#   1. Fetches the upstream remote
#   2. Generates a patch of RHDH-specific changes to vendored templates
#   3. Performs a git subtree pull (which resets vendored files to upstream)
#   4. Re-applies the RHDH patch
#   5. Applies other RHDH fixups (.gitignore, Helm dependency .tgz files)
#   6. Commits the result
#
# If the RHDH patch fails to apply (e.g. upstream changed the same lines),
# the patch is saved to rhdh-vendored.patch for manual resolution.

set -euo pipefail

REMOTE="upstream-backstage"
REF="main"
PREFIX="charts/backstage/vendor/backstage"
UPSTREAM_URL="https://github.com/backstage/charts.git"

usage() {
  sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) REMOTE="$2"; shift 2 ;;
    --ref)    REF="$2";    shift 2 ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

UPSTREAM_TEMPLATES="charts/backstage/templates"
VENDOR_TEMPLATES="${PREFIX}/charts/backstage/templates"
VENDOR_GITIGNORE="${PREFIX}/.gitignore"

# ── Ensure upstream remote exists and is fetched ─────────────────────
if ! git remote get-url "$REMOTE" &>/dev/null; then
  echo "Adding remote ${REMOTE} -> ${UPSTREAM_URL}"
  git remote add "$REMOTE" "$UPSTREAM_URL"
fi
echo "Fetching ${REMOTE}/${REF}..."
git fetch "$REMOTE" "$REF"

# ── Generate RHDH-specific patch ─────────────────────────────────────
PATCH_FILE=$(mktemp "${TMPDIR:-/tmp}/rhdh-patch.XXXXXX")
cleanup() { rm -f "$PATCH_FILE"; }
trap cleanup EXIT

echo "Generating RHDH-specific template patches..."

has_meaningful_diff() {
  # A diff is meaningful if added and removed lines differ in content,
  # not just in trailing whitespace or newline presence.
  local diff_file="$1"
  local added removed
  added=$(sed -n 's/^+//p' "$diff_file" | grep -v '^++' | sed 's/[[:space:]]*$//' | sort)
  removed=$(sed -n 's/^-//p' "$diff_file" | grep -v '^--' | sed 's/[[:space:]]*$//' | sort)
  [[ "$added" != "$removed" ]]
}

for vendored_file in "${VENDOR_TEMPLATES}"/*.yaml; do
  [[ -f "$vendored_file" ]] || continue
  filename=$(basename "$vendored_file")

  # Only diff files that also exist upstream; RHDH-only files won't be
  # touched by the subtree pull so they don't need patching.
  upstream_content=$(git show "${REMOTE}/${REF}:${UPSTREAM_TEMPLATES}/${filename}" 2>/dev/null) || continue

  # Produce a unified diff with paths relative to the repo root so
  # git-apply works from the top level.
  FILE_DIFF=$(mktemp "${TMPDIR:-/tmp}/rhdh-filediff.XXXXXX")
  diff -u <(printf '%s\n' "$upstream_content") "$vendored_file" \
    | sed "1s|^--- .*|--- a/${VENDOR_TEMPLATES}/${filename}|
           2s|^+++ .*|+++ b/${VENDOR_TEMPLATES}/${filename}|" \
    > "$FILE_DIFF" || true   # diff exits 1 when files differ

  if [[ -s "$FILE_DIFF" ]] && has_meaningful_diff "$FILE_DIFF"; then
    cat "$FILE_DIFF" >> "$PATCH_FILE"
  fi
  rm -f "$FILE_DIFF"
done

if [[ -s "$PATCH_FILE" ]]; then
  patched_files=$(grep -c '^--- a/' "$PATCH_FILE" || true)
  echo "  Found patches for ${patched_files} file(s)."
else
  echo "  No RHDH-specific template patches to preserve."
fi

# ── Subtree pull ─────────────────────────────────────────────────────
BEFORE_SHA=$(git rev-parse HEAD)

echo "Pulling upstream subtree..."
git subtree pull --prefix "$PREFIX" "$REMOTE" "$REF" --squash \
  -m "Squashed sync of upstream Backstage chart"

AFTER_SHA=$(git rev-parse HEAD)

if [[ "$BEFORE_SHA" = "$AFTER_SHA" ]]; then
  echo "No changes from upstream."
  exit 0
fi

echo "Upstream changes merged."

# ── Re-apply RHDH patches ───────────────────────────────────────────
if [[ -s "$PATCH_FILE" ]]; then
  echo "Re-applying RHDH-specific template patches..."
  if ! git apply "$PATCH_FILE"; then
    cp "$PATCH_FILE" rhdh-vendored.patch
    trap - EXIT
    echo "" >&2
    echo "ERROR: RHDH patch failed to apply cleanly." >&2
    echo "The patch has been saved to: rhdh-vendored.patch" >&2
    echo "" >&2
    echo "To resolve:" >&2
    echo "  1. Review the patch:  cat rhdh-vendored.patch" >&2
    echo "  2. Try with 3-way:    git apply --3way rhdh-vendored.patch" >&2
    echo "  3. Or with rejects:   git apply --reject rhdh-vendored.patch" >&2
    echo "  4. Resolve any .rej files, then:  git add <files>" >&2
    echo "  5. Clean up:          rm rhdh-vendored.patch" >&2
    exit 1
  fi
  echo "  RHDH template patches re-applied successfully."
fi

# ── Apply .gitignore and .tgz fixups ────────────────────────────────
RHDH_MARKER="# RHDH: track vendored chart dependencies"

# Fix directory ignore pattern so negation rules work
if [[ -f "$VENDOR_GITIGNORE" ]]; then
  sed -i'' -e 's|^charts/\*/charts/$|charts/*/charts/*|' "$VENDOR_GITIGNORE"

  if ! grep -q "$RHDH_MARKER" "$VENDOR_GITIGNORE"; then
    cat >> "$VENDOR_GITIGNORE" <<EOF

${RHDH_MARKER}
# Since this chart is vendored, we commit its dependencies rather than fetching them at install time
!charts/*/charts/*.tgz
EOF
  fi
fi

# Rebuild vendored chart dependencies to restore .tgz files
helm dependency update "${PREFIX}/charts/backstage"

# ── Commit RHDH-specific changes ────────────────────────────────────
git add "$VENDOR_GITIGNORE"
git add "${PREFIX}/charts/backstage/charts/"*.tgz 2>/dev/null || true
git add "${VENDOR_TEMPLATES}/"
if ! git diff --cached --quiet; then
  git commit -m "chore: apply RHDH-specific changes to vendored Backstage chart"
fi

echo "Upstream sync complete."
