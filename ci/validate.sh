#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Validating CUE schemas..."

# Validate schema.cue and allowed.cue
cue vet adr/schema.cue adr/allowed.cue

# Validate each Decision file individually to avoid conflicts
for f in adr/src/*.cue; do
  [ -e "$f" ] || continue  # Skip if no .cue files exist
  echo "[INFO] Validating $f..."
  cue vet adr/schema.cue "$f"
done

echo "[INFO] Building preview..."
bash tools/adr/build

echo "[INFO] Running checks..."
bash tools/adr/check adr/log.jsonl.preview
