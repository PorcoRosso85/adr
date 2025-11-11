#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Checking for tracked generated files..."
# Prevent auto-generated files from being committed
TRACKED_GEN_FILES=$(git ls-files \
  'adr/adr-*.jsonl' \
  'adr/allowed.json' \
  'adr/manifest-*.json' \
  'adr/log*.jsonl' \
  'adr/decisions.jsonl' \
  'adr/tree-*.json' \
  || true)
if [ -n "$TRACKED_GEN_FILES" ]; then
  echo "[ERR] Generated files must not be tracked in git:"
  echo "$TRACKED_GEN_FILES"
  echo "[ERR] These files should be in .gitignore. Run: git rm <file>"
  exit 1
fi

echo "[INFO] Validating CUE schemas..."

# Validate schema and allowed.cue
cue vet adr/schema.cue adr/allowed.cue

# Validate all Decision files against schema (one by one to avoid conflicts)
if compgen -G "adr/src/*.cue" > /dev/null; then
  for f in adr/src/*.cue; do
    cue vet adr/schema.cue "$f"
  done
else
  echo "[WARN] No Decision files found in adr/src/"
fi

echo "[INFO] Building preview..."
bash tools/adr/build

echo "[INFO] Running checks..."
bash tools/adr/check
