#!/bin/bash
set -euo pipefail

echo "==> Chronicle OpenAI: self-test starting"

# --- deps check (soft for optional tools) ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "✗ Missing: $1"; return 1; }; }
soft() { command -v "$1" >/dev/null 2>&1 && echo "✓ Found: $1" || echo "• Optional missing: $1"; }

echo "==> Checking required tools"
REQ_OK=1
for cmd in check-jsonschema; do
  if ! need "$cmd"; then REQ_OK=0; fi
done
[ "$REQ_OK" -eq 1 ] || { echo "Install missing required tools (e.g. pip install check-jsonschema)"; exit 1; }

echo "==> Checking optional tools"
soft yamllint
soft pre-commit
soft shellcheck
soft openssl

# --- basic repo structure ---
echo "==> Verifying repo structure"
test -d schema && echo "✓ schema/ ok" || { echo "✗ missing schema/"; exit 1; }
test -f schema/chronicle_entry.schema.yaml && echo "✓ schema file ok" || { echo "✗ missing schema/chronicle_entry.schema.yaml"; exit 1; }
test -d scripts && echo "✓ scripts/ ok" || { echo "✗ missing scripts/"; exit 1; }
test -d attestations && echo "✓ attestations/ ok" || { echo "• creating attestations/"; mkdir -p attestations; }

# --- yaml lint (if available) ---
if command -v yamllint >/dev/null 2>&1; then
  echo "==> yamllint on repo YAML"
  yamllint -s .
else
  echo "• Skipping yamllint (not installed)"
fi

# --- validate existing entries (if any) ---
echo "==> Validating existing Chronicle entries (if any)"
mapfile -t FILES < <(find attestations -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null || true)
if [ ${#FILES[@]} -eq 0 ]; then
  echo "• No existing entries yet."
else
  check-jsonschema --schemafile schema/chronicle_entry.schema.yaml "${FILES[@]}"
  echo "✓ Existing entries validate against schema"
fi

# --- smoke-test: create temp entry, validate, check filename, cleanup ---
echo "==> Smoke-testing attest.sh"
test -x scripts/attest.sh || { echo "✗ scripts/attest.sh not executable"; exit 1; }
TMP_OUT=$(scripts/attest.sh seaph "selftest attest" | awk '/Created /{print $2}')
echo "• Created: $TMP_OUT"

# filename pattern check
BASENAME=$(basename "$TMP_OUT")
if [[ "$BASENAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z--[a-zA-Z0-9._-]+--[a-z0-9-]+--[0-9a-f]+\.yaml$ ]]; then
  echo "✓ Filename pattern ok: $BASENAME"
else
  echo "✗ Filename pattern mismatch: $BASENAME"
  exit 1
fi

# schema validate the temp file
check-jsonschema --schemafile schema/chronicle_entry.schema.yaml "$TMP_OUT"
echo "✓ Temp entry validates against schema"

# optional: YAML load smoke (via python)
if command -v python3 >/dev/null 2>&1; then
  python3 - <<PY
import sys, yaml
with open("$TMP_OUT") as f:
    y = yaml.safe_load(f)
assert isinstance(y, dict) and 'timestamp' in y and 'structured_summary' in y
print("✓ YAML loads via Python")
PY
fi

# clean up temp file from working tree (leave it staged only if user wants)
echo "• Cleaning up temp entry"
git rm --cached -q -- "$TMP_OUT" 2>/dev/null || true
rm -f -- "$TMP_OUT"

# --- optional hooks and script lint ---
if command -v pre-commit >/dev/null 2>&1; then
  echo "==> Running pre-commit on all files"
  pre-commit run -a || { echo "✗ pre-commit checks failed"; exit 1; }
else
  echo "• Skipping pre-commit (not installed)"
fi

if command -v shellcheck >/dev/null 2>&1; then
  echo "==> shellcheck scripts"
  shellcheck scripts/*.sh || { echo "✗ shellcheck found issues"; exit 1; }
else
  echo "• Skipping shellcheck (not installed)"
fi

echo "==> Self-test complete ✓"
