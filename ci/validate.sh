#!/usr/bin/env bash
set -euo pipefail

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
