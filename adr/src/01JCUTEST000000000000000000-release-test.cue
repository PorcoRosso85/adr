package adr

Decision: #Decision & {
	id:  "01JCUTEST000000000000000000"
	uri: "doc://test/release-creation-verification"
	ts:  "2025-11-07T12:30:00Z"
	status: "Accepted"
	rationale_md: """
# Release作成テスト
- 目的: GitHub Releaseへのスナップショット作成を検証
- 期待動作: mainマージ後に adr-snap-* タグと Release が作成される
- 検証項目:
  1. adr/ 配下の変更検出
  2. タグの自動作成
  3. .jsonl ファイルのアップロード
"""
	meta: {pr: 999, author: "test-bot"}
}
