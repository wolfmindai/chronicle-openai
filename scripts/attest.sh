#!/bin/bash
#
# attest.sh — generate a new Chronicle entry (YAML) in the attestations/ tree
#
# Part of the Chronicle OpenAI project under Wolf Core Trust LLC.
#
# © 2025 Wolf Core Trust LLC. All rights reserved.
# Original thesis and design: Seaph Antelmi
#
# This script is provided as part of a sovereign truth-ledger toolchain
# (SES → Wolf Mind → Veritas). It creates timestamped, slugified, and
# schema-compliant YAML entries to be signed and committed into Git.
#
# License: Internal use only unless explicitly licensed by Wolf Core Trust LLC.
#
# Usage:
#   scripts/attest.sh <username> <topic-slug or phrase>
#
# Example:
#   scripts/attest.sh seaph "model regression"

#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <username> <topic-slug or phrase>"
  exit 1
fi

USER="$1"
RAW_TOPIC="$2"

# slugify: non-alnum -> '-', lowercase, trim dashes
TOPIC=$(printf "%s" "$RAW_TOPIC" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

TS=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
YEAR=$(date -u +"%Y")
MONTH=$(date -u +"%m")

# random 8-hex (fallback if openssl missing)
if command -v openssl >/dev/null 2>&1; then
  RID=$(openssl rand -hex 4)
else
  RID=$(hexdump -n 4 -e '"/"%02x' /dev/urandom 2>/dev/null | tr -d '/')
  RID="${RID:-$(date +%s)}"
fi

DIR="attestations/$YEAR/$MONTH"
mkdir -p "$DIR"

FNAME="$DIR/${TS}--${USER}--${TOPIC}--${RID}.yaml"

cat > "$FNAME" <<EOF
version: "1.0.0"
timestamp: "$TS"
username: "$USER"
terse_summary: "TODO: one-line summary"
structured_summary:
  topic_focus: "TODO"
  key_claims_contradictions: []
  implications_collapse_points: []
  next_actions_witnessed_silences: []
links:
  related_commits: []
  exhibits: []
  gpg_keyid: "TODO"
EOF

echo "Created $FNAME"
echo "→ Edit the file, then: git add '$FNAME' && git commit -S -m 'Add Chronicle entry: $USER/$TOPIC'"

