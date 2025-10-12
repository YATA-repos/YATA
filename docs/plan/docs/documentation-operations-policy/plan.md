---
title: "Documentation Operations Policy Refresh Plan"
domain: docs
status: proposed
version: 1
authors:
	- "Docs Platform WG"
created: 2025-10-10
updated: 2025-10-10
related_issues: []
related_prs: []
references: []
scope:
	- "docs/draft/ と docs/plan/ の目的・役割・境界線を定義する"
	- "ライフサイクル、昇格ゲート、更新・廃止フローの標準化"
	- "Front-matter スキーマを全計画ドキュメントで共通化"
	- "軽量な自動チェックとステップバイステップなCI導入を計画"
non_goals:
	- "guide/reference/survey/intent 以下の構造変更そのもの"
	- "Docs外のコードベースやAPI仕様の直接的な改修"
	- "完全自動化されたDocsリリース管理の即時実装"
requirements:
	functional:
		- "draft と plan の目的・スコープ・責務を明文化する"
		- "draft→plan 昇格時の最低限ゲートを定義し、チェックリスト化する"
		- "Front-matter の必須フィールドを策定し、テンプレートに反映する"
		- "文書レビューと承認フローを標準化し、CODEOWNERS と連携する"
		- "lint / link-check / front-matter 検証の導入計画を提示する"
	non_functional:
		- "既存ドキュメントとの互換性を保ちつつ段階的に導入可能である"
		- "運用負荷を最小限に抑え、CI実行時間を5分以内に収める"
		- "ドキュメントの可観測性（指標・期限管理）が改善される"
constraints:
	- "docs 配下の既存構造を前提とし、破壊的変更は後続intentで扱う"
	- "CI/CD は GitHub Actions を想定し、夜間バッチや専用サーバーは用意しない"
	- "運用ルールは OSS 化を考慮し、秘密情報の記載は禁止する"
api_changes: []
data_models: []
migrations: []
rollout_plan:
	phases:
		- name: Phase 0 - Alignment
			description: "指針案の合意形成とテンプレート草案の共有"
			exit_criteria:
				- "本計画が承認され、issue tracker にEpicが作成されている"
		- name: Phase 1 - Templates & Checklists
			description: "draft/plan テンプレートとPRチェックリストの導入"
			exit_criteria:
				- "テンプレートがリポジトリに追加され、CODEOWNERSに通知済み"
				- "PRテンプレートにdraft/plan項目が統合されている"
		- name: Phase 2 - CI Automation
			description: "markdownlint とリンクチェックをGitHub Actionsに組み込む"
			exit_criteria:
				- "CIがdocs変更を検知してlint/link-checkを実行する"
				- "失敗時にレビュアへ通知される運用が確立"
		- name: Phase 3 - Front-matter Validation & Stale Bot
			description: "front-matter 必須キー検証とstale draft検出Botの導入"
			exit_criteria:
				- "front-matter検証スクリプトがCIに組み込まれている"
				- "ttl_days超過draftへの自動Issue起票が動作検証済み"
rollback:
	- "指針導入により作業負荷が急増した場合、Phase 2以降のCIジョブを一時停止し、テンプレート運用のみ継続する"
	- "Front-matter スキーマ変更で互換性問題が発生した際は、旧スキーマ互換モードを30日間併用する"
test_plan:
	- "Phase 1 完了時にサンプルdraft/planを用いたドライランレビューを実施し、チェックリストの欠落を洗い出す"
	- "CI導入フェーズではフォーク環境で失敗・成功ケースを検証し、所要時間を記録する"
observability:
	- "docs関連CIの実行時間・失敗率をGitHub Insightsで週次確認する"
	- "stale draft Bot のIssue生成数と対応時間をダッシュボード化する"
security_privacy:
	- "docsには秘密情報・個人情報を記載しない明示ルールをテンプレートに含める"
	- "CIログに機密情報が出力されないようにmask設定を徹底する"
performance_budget:
	- "markdownlint + link-check の合計実行時間を5分以内に維持する"
	- "front-matter検証スクリプトは100ms/ファイル以内で完了する"
i18n_a11y:
	- "テンプレートで用語の多言語対応方針を明確にし、翻訳が必要なセクションをタグ付けする"
	- "Plan本文では支援技術利用者向けに構造化見出しと表の代替テキスト方針を定義する"
acceptance_criteria:
	- "draft と plan の目的・スコープ・ライフサイクルが文書化されている"
	- "昇格ゲートとレビュー/承認フローがチェックリスト形式で提示されている"
	- "Front-matter スキーマと必須フィールドが定義されている"
	- "自動化ロードマップがフェーズ別に記載されている"
owners:
	- "Docs Platform WG"
---

# Documentation Operations Policy Refresh Plan

## 🧭 背景
- `docs/draft/` は仮説や検討メモが混在し、更新期限が曖昧なまま残存している。
- `docs/plan/` は実装計画と意思決定の受け皿だが、昇格基準が明文化されておらず品質にばらつきがある。
- Front-matter の構造が統一されていないため、自動チェックやメタデータ活用が困難。
- CI に lint/review ガードが存在せず、リンク切れや期限切れドキュメントの検知が手作業に依存している。

## 🎯 目的
1. `docs/draft/` と `docs/plan/` の役割・運用境界を明文化し、誰でも同じ基準で管理できる状態にする。
2. 昇格・更新・廃止のフローを標準化し、メタデータで追跡可能にする。
3. Front-matter の必須項目を策定し、テンプレートとCIで自動検証できるようにする。
4. 段階的な自動化（lint → link-check → front-matter → stale検知）を進め、ドキュメント運用の健全性を高める。

## 📦 スコープ詳細
- 対象: `docs/draft/`、`docs/plan/`、付随する PR テンプレートと CI ワークフロー。
- 関連: `docs/intent/`、`docs/survey/`、`docs/guide/`、`docs/reference/` との情報連携。
- 成果物: 運用指針本文、テンプレート案、CI導入ロードマップ、レビューフロー定義、Bot運用方針。

## 🧩 ライフサイクルと昇格ルール
### ライフサイクル全体像
`draft → (survey) → plan → intent → guide/reference`

### draft 運用
- **目的**: アイデア、調査途中メモ、代替案比較、未確定事項を一時保管。
- **原則**: 一時的・仮。決定事項は `intent/` や `plan/` へ移送。TTL（既定30日）以内に昇格 or クローズ判断。
- **Front-matter（追加フィールド）**:
	- `state: idea | exploring | paused`
	- `hypothesis`, `options`, `open_questions`
	- `next_action_by`, `review_due`, `ttl_days`

### plan 運用
- **目的**: 実装・運用の合意済み仕様と実施計画の単一参照点。
- **原則**: 抽象的な議論は `intent/` へ移し、plan には結論と実行事項を記載。
- **必須要素**: スコープ/非スコープ、要求/制約、API/データモデル/マイグレーション、テスト/観測、リスク/ロールバック、関連Issue/PR。

### draft → plan 昇格ゲート
- 明確な `scope` / `non_goals` の定義。
- `acceptance_criteria` が列挙されている。
- 影響範囲（API/データ/移行/セキュリティ/パフォーマンス/i18n/a11y）が整理済み。
- `test_plan` と `observability` の方針がある。
- リスクとロールバック戦略が具体的に記述されている。
- 関連Issue/PRが front-matter で紐づけられている。

### plan の更新と廃止
- 意思決定の記録は `docs/intent/` へ集約し、plan には結果のみ反映。
- 破壊的変更や方針転換は `version` を +1 し、`supersedes` / `superseded_by` で連結。
- 非推奨となった plan は `status: deprecated` とし、後継 plan へのリンクを明示。
- draft は TTL 経過で Bot がIssueを起票し、担当者が昇格/クローズ/延長を判断。

## 🗂 Front-matter スキーマ
- **共通**: `title`, `domain`, `status`, `version`, `authors`, `created`, `updated`, `related_issues`, `related_prs`, `references`。
- **draft専用**: `state`, `hypothesis`, `options`, `open_questions`, `next_action_by`, `review_due`, `ttl_days`。
- **plan専用**: `scope`, `non_goals`, `requirements`, `constraints`, `api_changes`, `data_models`, `migrations`, `rollout_plan`, `rollback`, `test_plan`, `observability`, `security_privacy`, `performance_budget`, `i18n_a11y`, `acceptance_criteria`, `owners`。
- **管理方法**: リポジトリ共通の JSON Schema を `docs/_schemas/plan.schema.json` として後続Issueで整備し、CIで検証する。

## 🔁 レビュー & 承認フロー
- **PR テンプレート拡張**:
	- draft: 目的 / 仮説 / 期限 / 担当をチェックリスト化。
	- plan: 昇格ゲート項目（スコープ/AC/影響/テスト/リスク/ロールアウト/観測）をYes/No確認する。
- **レビュア**:
	- Domain CODEOWNERS + 影響領域（infra/core/shared）の代表。
	- plan は少なくとも2名承認。draft は1名 or 自己承認可。
- **マージ後運用**:
	- plan 作成/更新時は GitHub Issues にEpicを作成 or 紐付け、front-matter と相互リンク。

## ⚙️ 自動化ロードマップ
| フェーズ | 対応内容 | 所要 | 担当 |
| --- | --- | --- | --- |
| Phase 0 | 計画承認、Epic発行、テンプレート案レビュー | 1週 | Docs Platform WG |
| Phase 1 | draft/plan テンプレート追加、PRチェックリスト更新 | 1-2週 | Docs Platform WG + DevRel |
| Phase 2 | markdownlint-cli2 + lychee を GitHub Actions に組み込み | 2週 | Infra |
| Phase 3 | front-matter schema validation 導入、stale draft Bot 実装 | 2-3週 | Infra + Docs Platform WG |

## 📊 指標とレポート
- ドキュメントCIの成功率・平均実行時間を週次で確認し、閾値超過で改善Issueを起票。
- stale draft Bot のIssueクローズ率を月次レビューし、TTL設定を見直す。
- plan 更新時は `updated` フィールドを必須更新し、変更履歴を intent と連携させる。

## ⚠️ リスクと軽減策
- **導入負荷**: テンプレート変更で心理的ハードルが上がる → ガイド付きチュートリアルとリファレンスサンプルを同時提供。
- **CI遅延**: lint/link-checkが遅くなる → 並列実行とキャッシュを有効活用し、5分超過でフェーズバック。
- **スキーマ破綻**: 既存planが必須フィールド未記載 → 移行期は警告モードでCIを走らせ、段階的に必須へ格上げ。
- **stale判定の過検知**: TTLが短すぎる → 初期は60日に設定し、実データを基に最適化する。

## ✅ 受け入れ基準トレース
1. Role境界・ライフサイクル・昇格ゲートが本文で具体化されている。
2. Front-matter スキーマとテンプレート導入計画が提示されている。
3. レビュー/承認フローと自動化ロードマップが定義されている。
4. リスク、ロールバック、観測指標が明文化されている。

## 📎 後続タスク（参考）
- [ ] `docs/_templates/` 配下に draft.md / plan.md テンプレートを追加。
- [ ] PR テンプレートにチェックリストを反映し、CODEOWNERSへ共有。
- [ ] markdownlint-cli2 / lychee を導入する GitHub Actions ワークフローを追加。
- [ ] front-matter schema validation スクリプトを作成し、CIへ組み込む。
- [ ] stale draft Bot の PoC を実装し、ttl_daysをメタデータで読み取る。

---
この計画書は `docs/plan/` におけるドキュメント運用の単一参照点として機能し、合意後はテンプレートとCI整備を段階的に進める。
