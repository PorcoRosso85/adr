package adr

// Core type definitions with strict validation
#ULID:   string & =~"^[0-9A-HJKMNP-TV-Z]{26}$"
#ISO8601: string & =~"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(Z|[+-]\\d{2}:?\\d{2})$"

// URI format: scheme://namespace/METHOD:/path
// CRITICAL: No whitespace allowed (use colon separator)
// Valid schemes: code, api, db, infra, doc, accounts
// Example: api://billing/POST:/charges (NOT "POST /charges")
#URI: string & =~"^(code|api|db|infra|doc|accounts)://\\S+$"

// Decision record with strict schema enforcement
#Decision: {
  id:     string & #ULID
  uri:    string & #URI  // Must be pre-registered in allowed.cue (deny-by-default)
  ts:     string & #ISO8601
  status: *"Accepted" | "Deprecated"

  // Supersedes: Must reference existing Decision IDs with same URI
  // DAG constraint: No cycles allowed (enforced by tools/adr/check)
  supersedes?: [...string & #ULID] | string & #ULID

  // Alias: Deprecated Decisions must specify redirect target
  // Target URI must be in AllowedURIs, no redirect cycles
  alias_to?:   string & #URI

  // Spec: Required for Accepted Decisions (contract definition)
  spec?:         _
  rationale_md?: string
  evidence?:     [...string]

  // Provenance: Auto-injected at release time
  actor?:  string
  source?: {
    path:         string
    commit:       string
    blob:         string  // SHA-256 of build script for reproducibility
    repo:         string
    cue_version?: string
    schema_hash?: string
    spec_hash?:   string
  }

  // Metadata: Arbitrary key-value pairs (backward compatibility)
  meta?: [string]: string | number | bool
}

// Invariants enforced by tools/adr/check:
// 1. URI must be in AllowedURIs (deny-by-default)
// 2. Only one Accepted Decision per URI (excluding superseded)
// 3. supersedes must point to same URI and form DAG (no cycles)
// 4. alias_to must be in AllowedURIs and form DAG (no cycles)
// 5. Accepted Decisions must have spec field
// 6. Compatibility: new spec ⊇ old spec (key inclusion)
