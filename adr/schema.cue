package adr

#ULID:   string & =~"^[0-9A-HJKMNP-TV-Z]{26}$"
#ISO8601: string & =~"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$"
#URI:    string & =~"^(code|api|db|infra|doc)://.+$"

#Decision: {
  id:          string & #ULID
  uri:         string & #URI
  ts:          string & #ISO8601
  status:      *"Accepted" | "Deprecated"
  supersedes?: string & #ULID
  alias_to?:   string & #URI
  rationale_md: string
  meta?: [string]: string | number | bool
}
