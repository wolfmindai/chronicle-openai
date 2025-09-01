#!/bin/bash
set -euo pipefail

SCHEMA="schema/chronicle_entry.schema.yaml"

if ! command -v check-jsonschema >/dev/null 2>&1; then
  echo "⚠️  Missing 'check-jsonschema'. Install:  pip install check-jsonschema" >&2
  exit 1
fi

mapfile -t FILES < <(find attestations -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null || true)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "ℹ️  No Chronicle entries to validate yet."
  exit 0
fi

echo "Validating ${#FILES[@]} Chronicle entries..."
check-jsonschema --schemafile "$SCHEMA" "${FILES[@]}"
echo "✅ Validation passed."
