package adr

// AllowedURIs defines the whitelist of permitted Decision URIs.
// Each URI must match the #URI schema pattern.
// This is the single source of truth - allowed.json is auto-generated from this.
AllowedURIs: [...#URI] & [
	"api://billing/POST /charges",
	"api://test/GET /health",
]
