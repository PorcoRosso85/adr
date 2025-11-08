#!/usr/bin/env bash
# Common library functions for ADR tooling
# Provides portable, reproducible operations across platforms

set -euo pipefail

# Portable SHA-256 hash function
# Tries sha256sum (Linux), then shasum (macOS), then openssl (fallback)
hash256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    openssl dgst -sha256 | awk '{print $2}'
  fi
}

# Normalize allowed URIs from CUE (single source of truth)
# Uses subshell isolation to avoid polluting caller's working directory
# Returns: sorted, unique JSON array of allowed URIs
normalize_allowed() {
  (cd adr && cue export schema.cue allowed.cue -e AllowedURIs | LC_ALL=C jq -rc 'sort|unique')
}

# Get hash of normalized allowed URIs with locale independence
allowed_hash() {
  LC_ALL=C normalize_allowed | hash256
}

# Detect duplicate URIs BEFORE normalization
# Returns: count of duplicate groups (0 means no duplicates)
detect_dups() {
  (cd adr && cue export schema.cue allowed.cue -e AllowedURIs \
    | LC_ALL=C jq -rc 'sort|group_by(.)|map(select(length>1))|length')
}

# Check for duplicates and fail if any exist
# Returns: 0 if no duplicates, 1 if duplicates found
check_no_dups() {
  local count=$(detect_dups)
  if [ "$count" -ne 0 ]; then
    echo "[ERR] Found $count duplicate URI groups in AllowedURIs" >&2
    return 1
  fi
  return 0
}
