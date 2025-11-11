# ADR (Architectural Decision Records) Repository

This repository implements ADR v2 specification with CUE-based schema validation, reproducible builds, and comprehensive audit trails.

## Architecture

### Single Source of Truth: `adr/allowed.cue`

All permitted Decision URIs are defined in `adr/allowed.cue` using CUE language for type safety:

```cue
package adr

AllowedURIs: [...#URI] & [
    "api://billing/POST:/charges",
    "api://test/GET:/health",
]
```

**Key Points:**
- `allowed.json` is **auto-generated** during build/release (never edit manually)
- CUE provides compile-time validation and type checking
- Schema enforcement prevents invalid URIs from being committed

### Deny-by-Default Validation

All Decision URIs **must** be pre-registered in `allowed.cue`. Attempting to use unauthorized URIs will fail CI with clear error messages:

```bash
[ERR] Unauthorized URIs detected (not in AllowedURIs):
api://unauthorized/POST:/endpoint
[ERR] deny-by-default: unauthorized URIs found
```

This ensures explicit approval for all architectural decisions before implementation.

## Repository Structure

```
adr/
├── schema.cue              # CUE schema definitions for ADR v2
├── allowed.cue             # Whitelist of permitted URIs (single source of truth)
├── src/                    # Decision files (.cue format)
│   ├── <ULID>-<name>.cue
│   └── ...
└── (generated files)       # NEVER committed to git:
    ├── allowed.json        # Auto-generated from allowed.cue
    ├── log.jsonl.preview   # Build preview
    ├── adr-*.jsonl         # Release snapshots (published to GitHub Releases only)
    └── manifest-*.json     # Release manifests (published to GitHub Releases only)

tools/adr/
├── lib.sh                  # Common library functions (portable hashing, normalization)
├── build                   # Build preview JSONL
├── check                   # Validation checks (deny-by-default, DAG, compatibility)
└── build_release           # Build release snapshot with manifest

ci/
└── validate.sh             # CI validation entry point (includes generated file tracking guard)
```

**Important:** All generated files (`.jsonl`, `manifest-*.json`, `allowed.json`) are **never committed** to the main branch. They are either:
- Transient build artifacts (`.preview` files)
- Published exclusively to GitHub Releases (snapshots and manifests)

## Workflow

### 1. Adding a New Decision URI

1. **Register URI in `adr/allowed.cue`:**
   ```cue
   AllowedURIs: [...#URI] & [
       "api://billing/POST:/charges",
       "api://newservice/POST:/action",  // Add here
   ]
   ```

2. **Validate schema:**
   ```bash
   cue vet adr/schema.cue adr/allowed.cue
   ```

3. **Create Decision file** in `adr/src/`:
   ```cue
   package adr

   Decision: {
       id: "01JB..."
       uri: "api://newservice/POST:/action"
       status: "Accepted"
       spec: { /* CUE schema */ }
       rationale_md: "# Decision rationale..."
       meta: {pr: 123, author: "user"}
   }
   ```

4. **Run validation:**
   ```bash
   bash ci/validate.sh
   ```

### 2. Release Process

On merge to `main`, GitHub Actions automatically:

1. Validates all schemas and checks
2. Builds release snapshot: `adr-YYYYMMDD-HHMMSS-7charhex.jsonl`
3. Generates manifest: `manifest-YYYYMMDD-HHMMSS-7charhex.json`
4. Creates GitHub Release with both artifacts
5. Runs reproducibility verification (`repro_check`)

**Tag Format:** `adr-snap-YYYYMMDD-HHMMSS-7charhex`
- Strictly validated with regex: `^adr-snap-[0-9]{8}-[0-9]{6}-[a-f0-9]{7}$`
- Example: `adr-snap-20251108-120004-05da7c6`

### 3. Manifest Structure

Each release includes a manifest with complete reproducibility metadata:

```json
{
  "repo": "org/repo",
  "commit": "abc123...",
  "ts": "2025-11-08T12:00:04Z",
  "actor": "username",
  "source": {
    "repo": "org/repo",
    "commit": "abc123...",
    "path": "tools/adr/build_release",
    "blob": "sha256:..."
  },
  "cue_version": "v0.9.2",
  "cue_flags": "",
  "toolchain": "default",
  "schema_hash": "sha256:...",
  "allowedURIs_hash": "sha256:..."
}
```

**Audit Trail:**
- `source.blob`: SHA-256 of build script ensures exact tooling version
- `allowedURIs_hash`: SHA-256 of normalized allowed URIs (reproducible)
- `schema_hash`: SHA-256 of schema.cue for compatibility tracking

## Reproducibility

### Verifying a Release

Download and verify any release:

```bash
# Set release tag
TAG="adr-snap-20251108-120004-05da7c6"

# Download artifacts
gh release download "$TAG" -p "*.jsonl" -p "manifest-*.json"

# Verify allowedURIs_hash
source tools/adr/lib.sh
MANIFEST_HASH=$(jq -r '.allowedURIs_hash' manifest-*.json)
COMPUTED_HASH=$(allowed_hash)

if [ "$MANIFEST_HASH" = "$COMPUTED_HASH" ]; then
  echo "✓ Reproducibility verified"
else
  echo "✗ Hash mismatch!"
fi
```

### Deterministic Builds

All builds use:
- **CUE v0.9.2** (pinned for reproducibility)
- **LC_ALL=C** (locale-independent sorting)
- **Portable hash functions** (sha256sum/shasum/openssl fallbacks)
- **Subshell isolation** (no working directory pollution)

## Validation Checks

The `tools/adr/check` script enforces:

1. **Deny-by-default:** All URIs must be in `AllowedURIs`
2. **ID uniqueness:** No duplicate Decision IDs
3. **Spec requirement:** All Accepted Decisions must have `spec` field
4. **Supersedes rules:**
   - Referenced IDs must exist
   - Same-URI constraint (can only supersede same URI)
   - DAG structure (no cycles)
5. **Alias rules:**
   - Deprecated Decisions must have `alias_to`
   - `alias_to` must point to allowed URI
   - No cycles in redirect graph
6. **Compatibility:**
   - Key inclusion (old spec ⊆ new spec)
   - Old valid examples pass new spec

## Development

### Prerequisites

- Go 1.20+ (for CUE installation)
- jq (JSON processor)
- git

### Install CUE

```bash
go install cuelang.org/go/cmd/cue@v0.9.2
```

### Local Testing

```bash
# Validate schemas
bash ci/validate.sh

# Build preview
bash tools/adr/build

# Run checks
bash tools/adr/check adr/log.jsonl.preview

# Build release snapshot
bash tools/adr/build_release adr/adr-test.jsonl
```

## Migration Notes

### From allowed.json to allowed.cue

This repository has migrated from JSON to CUE for the allowed URI whitelist:

- **Before:** `adr/allowed.json` (manually edited)
- **After:** `adr/allowed.cue` (single source of truth)

`allowed.json` is now auto-generated during builds and **must never be committed** (enforced by `.gitignore` and CI guard).

### URI Format Migration

URIs have been normalized to prohibit whitespace:
- **Old format:** `api://billing/POST /charges` (space before path)
- **New format:** `api://billing/POST:/charges` (colon separator)

All URIs must match the pattern defined in `schema.cue` (`#URI`): no whitespace allowed.

## Troubleshooting

### "Generated files must not be tracked in git"

This error means you've accidentally committed auto-generated files. To fix:

```bash
git rm adr/allowed.json adr/adr-*.jsonl adr/manifest-*.json
git commit -m "fix: remove tracked generated files"
```

These files are auto-generated and should only exist in GitHub Releases, not in git history.

### "unauthorized URIs found"

Add the URI to `adr/allowed.cue` and commit the change.

### "Hash mismatch" in repro_check

Ensure you're using the exact same CUE version (v0.9.2) and that `LC_ALL=C` is set for reproducible sorting.

### "supersedes points to different URI"

A Decision can only supersede another Decision with the **same URI**. Check your `supersedes` field.

## License

[Your License Here]
