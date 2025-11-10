package adr

// AllowedURIs defines the whitelist of permitted Decision URIs.
// Each URI must match the #URI schema pattern (no whitespace allowed).
AllowedURIs: [...#URI] & [
	"api://billing/POST:/charges",
	"api://test/GET:/health",
]
