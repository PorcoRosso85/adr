package adr

#ULID:   string & =~"^[0-9A-HJKMNP-TV-Z]{26}$"
#ISO8601: string & =~"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(Z|[+-]\\d{2}:?\\d{2})$"
#URI:    string & =~"^(code|api|db|infra|doc|accounts)://\\S+$"

#Decision: {
  id:     string & #ULID
  uri:    string & #URI
  ts:     string & #ISO8601
  status: *"Accepted" | "Deprecated"

  supersedes?: [...string & #ULID] | string & #ULID
  alias_to?:   string & #URI

  spec?:         _
  rationale_md?: string
  evidence?:     [...string]

  actor?:  string
  source?: {
    path:         string
    commit:       string
    blob:         string
    repo:         string
    cue_version?: string
    schema_hash?: string
    spec_hash?:   string
  }
  meta?: [string]: string | number | bool
}
