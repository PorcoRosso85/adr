#!/usr/bin/env bash
set -euo pipefail
bash tools/adr/build
bash tools/adr/check adr/log.jsonl.preview
