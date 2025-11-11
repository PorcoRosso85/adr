#!/usr/bin/env bash
# ADR common library functions

# Portable SHA-256 hash function (returns hex)
hash256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    openssl dgst -sha256 | awk '{print $2}'
  fi
}

# Convert hex hash to Nix-style base32 (simplified: use first 32 chars of hex as base32-like)
# TODO: Implement full Nix base32 alphabet (0123456789abcdfghijklmnpqrsvwxyz)
# For now, use hex substring for deterministic content-addressing
hex_to_nar_base32() {
  local hex="$1"
  # Simplified: take first 32 chars of hex as "base32-like" identifier
  # In production, this should use Nix base32 encoding
  echo "${hex:0:32}"
}

# Compute narHash of JSON file (content-addressable storage)
# Input: JSON file path
# Output: sha256-<base32> format (Nix narHash style)
nar_hash() {
  local file="$1"
  # Deterministic serialization: minified JSON with sorted keys, UTF-8, LF
  local hex
  hex=$(jq -cS . "$file" | hash256)
  local nar_b32
  nar_b32=$(hex_to_nar_base32 "$hex")
  echo "sha256-${nar_b32}"
}

# URI to filesystem-safe slug (for manifest filenames)
# Example: api://billing/POST:/charges → api.billing.POST.charges
uri_to_slug() {
  local uri="$1"
  echo "$uri" | sed 's|://|.|g; s|/|.|g; s|:||g'
}

# Normalize allowed URIs from CUE (canonical form with sort|unique)
# Note: Uses subshell to avoid polluting caller's cwd
normalize_allowed() {
  (cd adr && cue export schema.cue allowed.cue -e AllowedURIs | LC_ALL=C jq -rc 'sort|unique')
}

# Get allowed URIs hash (stable, locale-independent)
allowed_hash() {
  LC_ALL=C normalize_allowed | hash256
}

# Detect duplicate URIs in allowed.cue (before normalization)
detect_dups() {
  (cd adr && cue export schema.cue allowed.cue -e AllowedURIs \
    | LC_ALL=C jq -rc 'sort|group_by(.)|map(select(length>1))|length')
}

# Verify no duplicate URIs
check_no_dups() {
  local count
  count=$(detect_dups)
  if [ "$count" -ne 0 ]; then
    echo "[FAIL] Duplicate URIs found in allowed.cue" >&2
    (cd adr && cue export schema.cue allowed.cue -e AllowedURIs \
      | LC_ALL=C jq -rc 'sort|group_by(.)|map(select(length>1))') >&2
    return 1
  fi
  return 0
}
