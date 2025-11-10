package adr

Decision: #Decision & {
  id:  "01JB0K9W6S7F4Z8DR8V6NQ9C5X"
  uri: "api://billing/POST:/charges"
  ts:  "2025-11-07T03:10:00Z"
  status: "Accepted"
  spec: {
    request?: _
    response?: _
  }
  rationale_md: """
# 課金APIの整合性
- 目的: 二重課金防止・リトライ安全性
- 採用: Outbox + WAL
- 理由: ~~中略~~
"""
  meta: { pr: 428, author: "you" }
}
