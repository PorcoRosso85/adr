package adr

Decision: #Decision & {
  id:  "01JCATESTCAAAABBBBCCCCDDDD"
  uri: "api://test/GET:/health"
  ts:  "2025-11-07T08:10:00Z"
  status: "Accepted"
  spec: {
    request?: _
    response?: _
  }
  rationale_md: """
# ヘルスチェックエンドポイント
- 目的: サービス稼働状態の監視
- 採用: シンプルなGETエンドポイント
- 理由: CI動作テスト用のサンプル決定
"""
  meta: { pr: 999, author: "ci-test" }
}
