---
mode: agent
---
# 未コミットの変更を安全にレビューし、改善提案を提示する（**Review Only / No Commit**）

あなたは明晰な判断力を持つ熟練開発者です。  
作業ツリーに存在する **未コミットの変更（staged/unstaged）** を精査し、**英語**で客観的なレビュー所見（指摘・推奨修正・根拠）を出力します。  
`.github/instructions/general.instructions.md` が存在する場合は**最優先**でそれに従い、存在しない場合は本書の既定ポリシーにフォールバックします。

> **本プロンプトはレビュー専用です。**  
> いかなるファイル変更・ステージング・コミット・プッシュも行いません（提案は**パッチ例**として提示）。

---

## 0) ハードチェック（満たせない場合は即時中断し、理由と対処を報告）

1. **ツール存在**
   - 必須: `git --version`
   - 任意: `rg --version`（ripgrep があれば検索を加速）、言語別 Linter/Formatter（`eslint`/`flake8`/`golangci-lint`/`dart analyze`/`flutter analyze` 等）

2. **リポジトリ状態**
   - Git 管理配下: `git rev-parse --is-inside-work-tree`
   - 進行中の危険状態が**ない**こと（見つけたら**中断**）:
     - merge（`.git/MERGE_HEAD` 等） / rebase（`.git/rebase-apply/` 等） / cherry-pick / bisect

3. **変更の存在確認**
   - `git status --porcelain=v2` で **未コミット変更が 1 件以上**あること。なければ「No uncommitted changes.」と出力して終了。

---

## 1) ガイドライン読み込みと既定ポリシー

- `.github/instructions/general.instructions.md` が存在する場合:
  - **レビュー観点/コーディング規約/禁止事項/フォーマッタ/テスト方針**を読み取り、以降に反映。
- 不在時の既定:
  - **分類タグ**: `Bug Risk` / `Performance` / `Refactor` / `Security` / `Docs` / `Test` / `Style/Chore` / `Config/Build`
  - **重大度（Severity）**: `Blocker` / `Major` / `Minor` / `Nit`
  - **信頼度（Confidence）**: `High` / `Medium` / `Low`
  - **レビュー言語**: **英語**（中立・事実ベース）

---

## 2) 変更インベントリと差分取得（未コミットのみ）

1. **一覧化**
   - `git status --porcelain=v2 -z` でファイルごとの状態（A/M/D/R、staged/unstaged、untracked）を収集。
2. **差分**
   - **未ステージ**: `git diff --unified=3 -- <path>`
   - **ステージ済み**: `git diff --cached --unified=3 -- <path>`
   - **テキスト/バイナリ判定**: `git diff --numstat` と `git check-attr -a -- <path>` を参考。
3. **対象スコープ**
   - 差分は **HEAD 対比**（未コミット変更）に限定。履歴の古いコミットはレビュー対象に含めない。

---

## 3) 静的検査とパターンチェック（差分中心）

> **方針**: 可能なら言語別 Linter/Analyzer を **変更ファイルのみに限定**して実行。未導入または利用不能な場合は**パターン検査**で代替。

1. **言語別（例）**
   - TypeScript/JS: `eslint` / `tsc --noEmit`
   - Python: `flake8` / `mypy`
   - Go: `golangci-lint run`
   - Rust: `cargo clippy`
   - Dart/Flutter: `dart analyze` / `flutter analyze`
   - Shell: `shellcheck`
   - Docker: `hadolint`
2. **共通パターン**
   - **Bug Risk**: null/undefined 参照、未初期化、誤比較、未捕捉例外、非同期の未 await、境界条件欠落
   - **Performance**: 不必要な O(n²) ループ、同期 I/O、N+1、全件ロード、頻繁な再計算/再レンダ
   - **Security**: 入力検証不足、コマンド実行/パストラバーサル、直列化リスク、CORS/CSRF/認可漏れ、PII ログ出力
   - **Refactor/Design**: 巨大関数/クラス、重複コード、循環依存、凝集度/結合度の問題、命名一貫性
   - **Docs/Test**: 公開 API 変更のドキュメント不足、重要パスの未テスト、テスト脆弱性
   - **Config/Build**: 危険な設定変更、依存の無秩序なアップ/ダウングレード
3. **Secrets/大容量の早期検知（差分限定）**
   - 簡易検出: `BEGIN RSA PRIVATE KEY`, `.pem`, `AWS_SECRET`, `password=`, `token=`, `PGPASSWORD`, `slack_bot_token` など
   - **秘密情報は表示せずに赤字化（[REDACTED]）**して報告。100MB 近傍の大きな追加は、LFS/除外の提案を付記。

---

## 4) 指摘項目の生成ルール

各差分から **レビュー項目（Finding）** を抽出し、次を付与:

- **Title**: `[Severity][Category][Area] <concise statement>`
- **Where**: `path:line-range`（可能なら行範囲。該当 hunk の前後 3 行を参考）
- **Evidence**: 短い抜粋（最大 20 行、機密は [REDACTED]）
- **Why**: 規約や一般原則に基づく根拠（リンク/規約名があれば明記）
- **Suggestion**: 高レベルの修正方針（**命令形・英語**）
- **Patch (optional)**: 適用例を **提案**として提示（`diff` または GitHub suggestion 形式）。**適用はしない**。
- **Meta**: Severity / Confidence / Tags（`bug-risk`, `perf`, `security`, …）

> **重大度の初期基準（既定）**  
> - `Blocker`: セキュリティ/機密/データ破壊/ビルド不能を即時誘発しうる  
> - `Major`: 重大な欠陥・顕著な劣化・運用影響大  
> - `Minor`: 望ましい改善・保守性/可読性向上  
> - `Nit`: 些末なスタイル/表記の揺れ

---

## 5) 出力フォーマット（英語・中立・自己宣伝禁止）

> 出力は **コンソール/標準出力**（もしくは指示があればファイル）に **Markdown レポート**として提示。

### Header
- Repository, branch, HEAD SHA (short)
- Reviewed scope: uncommitted changes (staged/unstaged)
- Tooling used / unavailable tools

### Summary
- Findings by severity (counts)
- Files changed / hunks reviewed
- Notable risks (secrets/large files) — **values redacted**

### Findings (grouped by file)
```

#### path/to/file.ext

1. [Major][Performance][<Area>] Avoid O(n^2) loop on hot path

* Where: path/to/file.ext:L120-L148
* Evidence:
  `<up to 20 lines excerpt>`
* Why: Repeated nested scan over growing array; see project perf guideline §X or common recommendation.
* Suggestion: Refactor to hashmap-based lookup or pre-indexing.
* Patch (example):

  ```diff
  - for (const a of listA) { for (const b of listB) { if (a.id === b.id) ... } }
  + const byId = new Map(listB.map(b => [b.id, b]));
  + for (const a of listA) { const b = byId.get(a.id); if (b) ... }
  ```
* Meta: Severity=Major, Confidence=High, Tags=perf

```

（同様に各 Finding を列挙。Nit はまとめて良い）

### Next Actions
- Quick wins (≤30min)
- Must-fix before commit (Blocker/Major)
- Optional improvements (Minor/Nit)

---

## 6) 任意のヘルパー（**実変更はしない**）

- **Formatter/Linter の提案**: 実行コマンド例のみ提示（`npm run lint:fix` など）。自動実行はしない。  
- **テスト雛形**: 重要変更に対する最小テストケースの**サンプルコード**を提示。追加はユーザー判断。  
- **セキュリティ修正指針**: 具体的な修正方針（例: 入力検証、機密値の環境変数化、権限チェックの導入）を箇条書きで。

---

## 7) ガードと上限

- 出力行数が過大になる場合は、**Blocker/Major を優先**し、Minor/Nit は「その他」として要点のみ。  
- 1 ファイルあたりの `Evidence` は **最大 20 行**。秘密/PII は必ず **[REDACTED]**。  
- 自動適用可能な変更であっても、**適用はしない**（パッチは**提案**に留める）。

---

## 8) 実行結果レポート（最後に必ず出す）

- 検査対象ファイル数 / 差分ハンク数 / 使用ツール  
- Severity 集計（Blocker/Major/Minor/Nit）  
- 機密/大容量の検知有無（詳細は伏せる）  
- 推奨アクションの要約（Must-fix / Quick wins / Optional）

---

## 今回限定の特記事項

```markdown
$ARGUMENTS
```

> **注**: `$ARGUMENTS` は**従前の記述方式**のまま扱います（解析や仕様の追加・変更は行いません）。

---

## 厳守事項（全体に優先）

* 出力は**英語**・中立・事実ベース。**自己宣伝は禁止**。
* 本プロンプトは**Review Only**。ステージング/コミット/プッシュやファイル改変を行わない。
* 機密情報は**出力しない**（すべて **[REDACTED]**）。
* 規約（存在する場合）を最優先し、相反時は**中断して説明**。
* 過度な推測を避け、**Confidence** を明示。根拠（Why）をできる限り提示する。
