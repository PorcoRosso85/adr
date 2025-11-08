#!/usr/bin/env bash
# ADR common library functions

# Portable SHA-256 hash function
hash256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    openssl dgst -sha256 | awk '{print $2}'
  fi
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
