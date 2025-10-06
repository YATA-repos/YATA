---
mode: agent
---
# プロジェクト全体を安全に検査し、重複回避・優先度付きで改善提案を Issue 化する

あなたは明晰な判断力を持つ熟練開発者です。  
現在のプロジェクトを詳細に分析し、潜在的なバグ、パフォーマンス改善点、リファクタリング機会、セキュリティ課題、ドキュメント/テストの不足を特定し、**英語**で適切な Issue を作成します。  
`.github/instructions/general.instructions.md` もしくは`AGENTS.md` のガイドラインが存在する場合はそれを**最優先**で遵守し、存在しない場合は以下の既定ポリシーにフォールバックします。

---

## 0) ハードチェック（満たせない場合は即時中断して報告）

1. **ツール存在**
   - 必須: `git --version`
   - 推奨: `gh --version`（Issue 作成に使用）
   - 任意: `jq --version`, `rg --version`, 言語固有ツール（`eslint`/`tsc`/`flake8`/`mypy`/`bandit`/`golangci-lint`/`cargo clippy`/`dart analyze`/`flutter analyze` など）

2. **認証・個人情報（GitHub）**
   - `git config --get user.name` / `git config --get user.email` が設定済み。
   - `gh` がある場合は `gh auth status` を確認（未認証なら**作成を行わず**中断して指示を返す）。

3. **リポジトリ状態**
   - Git 管理配下: `git rev-parse --is-inside-work-tree`
   - 進行中の危険状態が**ない**ことを確認（あれば**中断**）:
     - merge（`.git/MERGE_HEAD` 等）
     - rebase（`.git/rebase-apply/` 等）
     - cherry-pick（`.git/CHERRY_PICK_HEAD`）
     - bisect（`.git/BISECT_LOG`）

---

## 1) ガイドライン読み込みと既定ポリシー

- `.github/instructions/general.instructions.md` が存在する場合:
  - **分類/優先度/難易度/ラベル/テンプレート/命名規約**などを読み取り、以降の手順に反映。
- ガイドライン不在時の既定:
  - **カテゴリ**: `Bug Fix` / `Performance` / `Refactor` / `Enhancement` / `Documentation` / `Security` / `Test`
  - **優先度**: `Critical` / `High` / `Medium` / `Low`
  - **難易度**: `Easy` / `Medium` / `Hard`
  - **ラベル対応**:
    - カテゴリ → `bug`, `performance`, `refactor`, `enhancement`, `documentation`, `security`, `test`
    - 優先度 → `critical`, `high`, `medium`, `low`
    - 難易度 → `Easy`, `Medium`, `Hard`
  - **命名規約（既定）**:  
    `"[<Category>][<Area>] <concise summary>"`

> 既定ポリシー下でも、既存のラベル/テンプレートがある場合はそれを優先して利用します。

---

## 2) プロジェクト構造と基礎情報の取得

1. **リモートとブランチ**
   - `git remote get-url origin`
   - デフォルトブランチ: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`（可能であれば）
   - 最新 SHA: `git rev-parse HEAD`

2. **構造と依存**
   - ルートの主要ファイル: `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pubspec.yaml`, `build.gradle*`, `CMakeLists.txt`, `Dockerfile`, `.tool-versions`, `.nvmrc` 等の存在確認
   - ディレクトリ把握: `src/`, `lib/`, `app/`, `features/`, `core/`, `infra/`, `test/`, `docs/`, `.github/` など
   - 設定/ビルド: `tsconfig.json`, `.eslintrc*`, `.prettierrc*`, `.flake8`, `mypy.ini`, `.golangci.yml`, `.clang-format`, `.editorconfig`, `analysis_options.yaml` 等

3. **パッケージスクリプト/タスク**
   - `npm scripts` / `make` / `justfile` / `taskfile` / `melos` 等の定義を収集

---

## 3) コード品質・セキュリティ・性能の検査

> 可能な限り**静的解析**を優先し、環境不足時は**パターン検査**と**レビュー指針**で代替します。

1. **静的解析（あれば実行）**
   - TypeScript/JS: `pnpm|yarn|npm run lint` / `eslint .` / `tsc -p . --noEmit`
   - Python: `flake8`, `mypy`, `bandit -r .`
   - Go: `golangci-lint run`, `go vet ./...`
   - Rust: `cargo clippy --all-targets --all-features -q`
   - Dart/Flutter: `dart analyze` / `flutter analyze`
   - Shell: `shellcheck` 対象スクリプト
   - Docker: hadolint（あれば）

2. **依存と脆弱性**
   - 可能なら `gh api` / `npm audit` / `pip-audit` / `cargo audit` / `osv-scanner` 等で既知脆弱性を検査
   - サプライチェーン: 不要依存/古い依存/ライセンス不一致の兆候

3. **ソースパターン検査（rg/grep で代替可）**
   - **潜在バグ**: null/undefined 参照、未処理例外、未捕捉 await、境界条件、誤った比較、未初期化、誤キャスト
   - **パフォーマンス**: `O(n^2+)` ループ/ネスト、同期 IO（UI/リクエスト中）、不要な全件ロード、N+1 クエリ
   - **可読性/保守**: 長大関数/クラス、重複コード（類似度高い塊）、命名不統一、循環依存
   - **セキュリティ**: 入力検証不足、直列化/反直列化の危険箇所、コマンド実行、パストラバーサル、ハードコード秘密
   - **テスト**: 重要モジュールの未テスト、フレークテスト兆候、CI 未実行の領域
   - **設定**: ハードコード値、環境差吸収不足、ログ不足/過多、PII マスキング欠如

---

## 4) 改善提案の生成・分類・ランク付け

1. **提案アイテム生成**
   - 各検知点を「Issue 候補」として収集し、**Area（モジュール/機能）**を紐付け。
   - 可能であれば、**該当行の短い抜粋（≤20 行）**と**相対パス + 行番号**を付与。

2. **カテゴリ付け**
   - `Bug Fix` / `Performance` / `Refactor` / `Enhancement` / `Documentation` / `Security` / `Test`
   - 不明確な場合は過大主張を避け、`Refactor` または `Enhancement` を選ぶ。

3. **優先度判定（ICE スコア）**
   - Impact(1–5) × Confidence(1–5) ÷ Effort(1–5) → **Score**
   - しきい値（既定）:
     - `Critical`: Score ≥ 4.0 かつ安全上/可用性へ直接影響
     - `High`: 3.0–3.99
     - `Medium`: 2.0–2.99
     - `Low`: < 2.0
   - ガイドラインに独自基準があればそれを優先。

4. **難易度（Effort の定性的写像）**
   - `Easy`（≤0.5日）、`Medium`（1–3日）、`Hard`（>3日 かつ/または広範囲影響）

---

## 5) 既存 Issue の重複/関連確認（強制）

1. **検索**
   - `gh issue list --state=all --limit=200`
   - 可能なら `--search` を用いてタイトル/本文/ラベルに対するキーワード照合
2. **判定**
   - **完全重複**: 新規作成を行わず、既存にコメントで情報追加
   - **部分重複/関連**: 新規作成するが、関連 Issue を **明記**（双方向リンク）
   - **統合候補**: 同一ファイル/機能の多数提案は包括 Issue に**集約**

---

## 6) Issue の作成（英語・事実ベース・自己宣伝禁止）

> 既存テンプレート（`.github/ISSUE_TEMPLATE/*`）がある場合は **`--template`** を優先使用。なければ以下の本文フォーマットを用いる。

- **タイトル規約**（既定）  
  `"[<Category>][<Area>] <concise summary>"`

- **本文テンプレート**（Markdown; すべて英語）
```

## Problem Description

<what is wrong / risk / evidence – concise, factual>

## Proposed Solution

<what to change, at a high level; alternatives when relevant>

## Expected Benefits

* <measurable or observable improvements>

## Implementation Notes

* <migration concerns, side effects, rollout plan>

## Related Files / Locations

* <path/to/file>:Lx-Ly
  <optional short code excerpt in a fenced block (≤20 lines)>

## Priority / Difficulty

* Priority: <Critical|High|Medium|Low>
* Difficulty: <Easy|Medium|Hard>
* ICE Score: <Impact>*<Confidence>/<Effort> = <Score>

## Related Issues

* #<id> (if any)

```

- **作成コマンド例**
- `gh issue create --title "<TITLE>" --body-file "<TEMP_MD>" --label "<category_label>" --label "<priority_label>" --label "<difficulty_label>"`

- **ラベル付与方針**
- カテゴリ/優先度/難易度のラベルを**必ず**付与。ラベルが存在しない場合は作成を試みず、**既存の最も近いラベル**を選択し、本文末尾に `Labels not found: ...` と記録。

---

## 7) Issue の整理・運用（依存/マイルストーン/プロジェクト）

1. **依存関係**
 - ブロッカー/被ブロックを本文に明記（例: “Blocked by #123” / “Blocks #456”）。
2. **マイルストーン**
 - ガイドラインにあれば設定。なければ省略可（勝手に新規作成しない）。
3. **プロジェクトボード**
 - 存在し、追加方法が明示されている場合のみ追加。未定義ならスキップ。

4. **大量作成の抑制**
 - 1回の実行で **最大 20 件**まで Issue 作成。超過分は
   - 上位の **Tracking Issue** を1件作成し、残りはチェックリストで列挙。
   - タイトル例: `[Tracking] Codebase improvement batch <YYYY-MM-DD>`

---

## 8) 出力・レポート（常に実施）

- 使用ポリシー（ガイドライン/既定）、デフォルトブランチ、解析対象パス数
- 生成した提案アイテムの概数、カテゴリ分布
- 重複/関連判定の結果（統合/スキップ件数）
- 作成した Issue 一覧（番号、タイトル、主要ラベル）
- 追記事項（見つかったが作成保留の項目、環境不足で検査できなかった領域 など）

---

## 検査対象の重点項目（再掲＋補足）

- **エラーハンドリング**: 例外伝播方針、失敗時の復旧、ログレベル
- **リソース管理**: ファイル/ネットワーク/DB ハンドルの確実なクローズ、リークの兆候
- **アルゴリズム効率**: 計算量、不要な同期処理、UI スレッドのブロッキング
- **コード重複/設計**: DRY 違反、循環依存、凝集度/結合度の問題
- **命名/スタイル**: 規約逸脱、曖昧/略語乱用
- **設定管理**: ハードコード値、環境変数/設定ファイル化、Secrets 取り扱い
- **ログ出力**: 機密/PII マスキング、過不足、構造化ログ
- **型安全性**: 静的型の活用、境界層でのバリデーション
- **テスト**: 重要パスの欠落、E2E/統合/プロパティテストの不足、CI 基盤の穴
- **セキュリティ**: 入力検証、認可/認証、依存脆弱性、ヘッダ/CSRF/CORS など

---

## 今回限定の特記事項

```markdown
$ARGUMENTS
```

---

## 厳守事項（全体に優先）

* **Issue 内容（タイトル/本文/コメント）はすべて英語**で記述すること。
* **非感情的で事実に基づく中立的な表現**を用いること。
* **自己宣伝の文言を含めない**こと（例: “generated by …” は不可）。
* 提案は**具体的で実装可能**であること。実現性の低い案は採用しない。
* プロジェクトの**現在の制約と要件**を尊重し、破壊的変更は正当化なしに提案しない。
* ツール未整備/認証未設定/危険状態/テンプレート不一致等があれば、**無理に続行せず中断して報告**すること。
