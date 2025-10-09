---
mode: agent
---
# コミットされていない変更内容を安全に分析・分類して、規約準拠でコミット・プッシュする

あなたは明晰な判断力を持つ熟練開発者です。現在、未コミットの変更が複数存在します。  
`.github/instructions/general.instructions.md` もしくは`AGENTS.md` のガイドラインに従い、以下のタスクを遂行してください。  
同ガイドラインが存在しない場合は、**Conventional Commits 1.0.0** を既定規約として適用します。

**タスク（考えてから実行）**: 未コミットの変更を分析し、単一責務に基づいて論理的に分割・分類し、適切なコミットメッセージで逐次コミットしたうえで、リモートへプッシュします。

---

## 0) ハードチェック（満たせない場合は即時中断して報告）

1. **ツール存在**
   - 必須: `git --version`
   - 推奨: `gh --version`（GitHub 操作が必要な場合）
   - 任意: `git lfs --version`, `gitleaks version`

2. **認証・個人情報**
   - `git config --get user.name` と `git config --get user.email` が設定済みであること。
   - `gh` がある場合は `gh auth status` を確認（必要に応じて）。

3. **リポジトリ状態**
   - Git 管理下: `git rev-parse --is-inside-work-tree`
   - 進行中の危険状態が**ない**こと（見つけたら中断）:
     - merge（`.git/MERGE_HEAD` 等）
     - rebase（`.git/rebase-apply/` 等）
     - cherry-pick（`.git/CHERRY_PICK_HEAD`）
     - bisect（`.git/BISECT_LOG`）

いずれかで失敗した場合は、**中断し、原因とユーザー対応を明示**してください（無理に継続しない）。

---

## 1) ガイドライン読み込みと既定ポリシー

- `.github/instructions/general.instructions.md` が存在すれば、**コミットタイプ・ブランチ運用・プッシュ方針・禁止事項**をそこから取得・遵守します。
- 規約が見つからない場合の既定:
  - **コミット規約**: Conventional Commits 1.0.0（`type(scope): subject`）
  - **許可タイプ**: `feat|fix|refactor|perf|docs|test|build|ci|style|chore|revert`
  - **ブランチ運用**:
    - 現在ブランチ名が `feature/` または `fix/` で始まるならそのまま継続。
    - それ以外の場合は `dev` ブランチへ切替（存在しなければ作成し、可能であれば `origin/dev` を追跡）。

> **注**: 既定ポリシー下では、`main`/`master` への直接プッシュは避けます。

---

## 2) 変更インベントリの取得

1. **ステータス**: `git status --porcelain=v2 -z` を用いて、変更ファイルの一覧（追跡/未追跡/削除/リネーム）を取得。
2. **差分**: 各ファイルごとに `git diff --unified=0 -- <path>` を取得し、差分の粒度を把握。
3. **バイナリ判定**: `git diff --numstat` や `git check-attr -a -- <path>` を用いて、テキスト/バイナリを分類。

作業ツリーがクリーンであれば「Working tree clean」と出力して**終了**。

---

## 3) 分割・分類（単一責務原則）

**論理グループ**を以下のヒューリスティクスで形成します（曖昧な場合はより狭く・保守的に）:

- **docs**: `**/*.md`, `docs/**`, `CHANGELOG.md`, `LICENSE*`
- **ci**: `.github/workflows/**`, CI 設定
- **build**: ビルド/依存管理（`package.json`, `pnpm-lock.yaml`, `pubspec.yaml`, `build.gradle`, `CMakeLists.txt`, `Dockerfile` 等）
- **test**: `test/**`, `__tests__/**`
- **style/chore**: フォーマットのみ、設定微修正、コメントのみ
- **refactor**: 振る舞い不変のリネーム/移動/分割（定数値変更なし）
- **perf**: 複雑度/アルゴリズム/IO 最適化
- **fix**: 明確なバグ修正、テスト修正を伴う修正
- **feat**: 新機能、公開 API 追加、新 UI コンポーネント
- **revert**: 明示的な巻き戻し

> **重要**: 単一ファイル内で複数タイプが混在する場合、**hunk 単位**に分割してステージします（`git add -p` 同等の挙動）。

**実行順序（安定順）**: `docs → ci → build → style → refactor → perf → fix → feat → test → revert`

---

## 4) ステージングとコミット作成（グループごと）

1. **ステージング**
   - グループに完全一致するファイルは `git add -- <files...>`。
   - 混在ファイルは **該当 hunk のみ**ステージング（クロスタイプ混在を避ける）。

2. **コミットメッセージ作成**
   - **ヘッダ**: ``type(scope): subject``  
     - `type`: 上記分類のいずれか  
     - `scope`: リポジトリのディレクトリ・ドメイン（例: `order`, `kitchen`, `inventory` など）。不明な場合は省略可。  
     - `subject`: **英語・命令形・72 文字以内・末尾にピリオドを付けない**
   - **本文（必要に応じて）**:
     - **Why**（背景/目的）
     - **What**（上位レベルの変更内容）
     - **Side effects / Migration notes**
   - **フッタ**:
     - 課題連携: `Closes #<id>`
     - 非互換: `BREAKING CHANGE: <説明>`

3. **コミット実行**
   - `git commit -m "<header>" [-m "<body>"] [-m "<footer>"]`

ステージ対象が空になったグループは**スキップ**。

---

## 5) 品質ゲート（プッシュ前）

1. **シークレット検知**
   - `gitleaks` があれば: `gitleaks detect --no-banner --redact`
   - なければ簡易検知（例: `AWS_SECRET`, `BEGIN RSA PRIVATE KEY`, `.pem`, `password=`, `token=` などの文字列）
   - 検知時は**即時中断**し、該当パスと対処（削除・履歴修正・`.env`/Vault 等）を提示。

2. **巨大ファイル/LFS**
   - 追加/変更ファイルのサイズを確認し、**100MB 近傍（既定 95MB 以上）**なら警告。
   - 大きなバイナリは `git lfs` を案内・適用（追跡ファイルの再ステージ含む）。対処不能なら**中断**。

3. **プロジェクト既定のテスト/ビルド**
   - プロジェクトに標準コマンドがある場合（例: `npm test` / `pnpm test` / `cargo test` / `flutter test` 等）、**実行**し、失敗したら**中断**。

---

## 6) リモートへのプッシュと（必要に応じて）PR

1. **リモート確認**
   - `git remote get-url origin` が取得できること。
2. **ブランチ確認**
   - `git rev-parse --abbrev-ref HEAD` で現在ブランチを取得。
   - 既定ポリシー下では `main`/`master` 直プッシュは避ける（`feature/*` または `fix/*` もしくは `dev`）。
3. **プッシュ**
   - 初回は `git push -u origin <branch>`、以降は `git push`。
4. **PR（任意）**
   - `gh` が使用可能で、ガイドラインが PR 作成を指示する場合は `gh pr create --fill --web` などを用いて PR を作成。

---

## 7) 出力・レポート（常に実施）

- 使用規約（ガイドライン or 既定）とブランチ方針
- 作成した論理グループと各ファイル数
- 作成コミット一覧（`type(scope): subject` のみの要約でよい）
- 実行した品質ゲートと結果（secret/large files/tests）
- プッシュ/PR の実施状況（または中断理由）

---

## 今回限定の特記事項

```markdown
$ARGUMENTS
```

---

## 厳守事項（プロンプト全体に優先）

* **自己宣伝を含むコミットメッセージを使用しないこと。**
  例: 「私の素晴らしい機能」「このコミットは○○によって生成」等の記述は不可。
* **非感情的で事実に基づく中立的な表現**を用いること。
* **コミットメッセージは英語**で記述すること。
* シークレットや認証情報を**コミットに含めない**こと（検知時は中断）。
* 危険状態や必須ツール不足、認証未設定、保護ブランチ違反が疑われる場合は、**無理に続行せず中断して報告**すること。
