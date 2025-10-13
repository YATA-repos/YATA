# TODO

Next ID No: 29

--- 

Definitions to suppress Markdown warnings

[Bugfix]: #
[Feature]: #
[Enhancement]: #
[Refactor]: #
[Performance]: #
[Documentation]: #
[Chore]: #

## あとでタスク定義

## Backlog

### [Refactor] features/shared/logging をアーキテクチャ整合に再配置する
- **ID**: Core-Refactor-27
- **Priority**: P1
- **Size**: M
- **Area**: Core
- **Dependencies**: None
- **Goal**: `lib/features/shared/logging/ui_action_logger.dart` が適切なレイヤーへ移動され、UI 層から `infra/logging` への直接依存が解消されている。
- **Steps**:
  1. `UiActionLogSession` と `LogFieldsBuilder`／`context_utils` の依存関係を整理し、`docs/standards/logging-structured-fields.md` などに沿って境界設計（core で扱う抽象と infra 実装の切り分け）をまとめる。
  2. 設計に基づき UI ログ用ヘルパーを `core` もしくは `app` 配下へ再配置し、必要に応じて `LogFieldsBuilder` の配置変更やラッパー導入で features → infra 直結を解消する。
  3. `lib/features/order/presentation/controllers/order_management_controller.dart` など既存利用箇所のインポートと実装を更新し、旧 `features/shared/logging` を撤去した上で動作確認とテストを実施する。
- **Description**: 現状は `features/shared/logging/ui_action_logger.dart` が infra 層のユーティリティへ直接アクセスしており、`docs/standards/architecture.md` のレイヤー制約に反している。UI 向けログ集約の責務を適切なレイヤーへ移し、将来の機能追加時に同様の逸脱が発生しないよう整理する。

### [Chore] セキュリティ・権限レビューを実施する
- **ID**: DevOps-Chore-22
- **Priority**: P1
- **Size**: S
- **Area**: DevOps
- **Dependencies**: Core-Enhancement-19
- **Goal**: CSVエクスポート用のRLS・ロール定義がSecurity WGでレビューされ、承認または修正アクションが明確になる。
- **Steps**:
  1. CSVエクスポートで必要な権限要件とRLSポリシー案を整理する。
  2. Security WGとのレビューセッションを実施し、フィードバックを収集する。
  3. 反映内容とフォローアップタスクをドキュメント化しTODOに登録する。
- **Description**: データ抽出機能のリリース前にセキュリティ観点の確認を行い、運用リスクを抑える。

### [Feature] Realtime 監視対象を主要画面へ拡張する
- **ID**: Core-Feature-8
- **Priority**: P2
- **Size**: L
- **Area**: Core
- **Dependencies**: UI/UX-Enhancement-7
- **Goal**: 注文・在庫・履歴等の主要データで Supabase Realtime を活用し、他端末からの更新を即座に UI へ反映できるようにする。
- **Steps**:
  1. 各機能で必要なチャンネル／イベント種別を定義し、既存サービス層へ監視フックを追加する。
  2. Realtime イベントを StateNotifier へ伝搬させる共通ハンドリング（デバウンスやエラー処理を含む）を実装する。
  3. 対象ページでの UI 反映と回帰テスト、運用ドキュメントの更新を行う。
- **Description**: 端末間でデータが乖離しないよう Realtime を段階的に導入し、周期更新と組み合わせて鮮度を高める。

### [Enhancement] 注文状態ボードの左→右導線を強化する
- **ID**: UI/UX-Enhancement-12
- **Priority**: P3
- **Size**: S
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: 注文状態画面で左から右への進行が視覚的に理解できるUIが実装される。
- **Steps**:
  1. 現行UIの導線と課題を整理する。
  2. 矢印的な視覚要素や配置案を検討し決定する。
  3. デザインを実装し、ユーザビリティを確認する。
- **Description**: 注文状態画面の進行方向が分かりづらい。視覚的な導線を強化し操作性を高める。

---

## Ready

### [Refactor] app_routerのパス定義を統一する
- **ID**: UI/UX-Refactor-24
- **Priority**: P2
- **Size**: S
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: `app_router.dart`の各パス定義が統一ポリシーに従い、重複・ハードコードの揺らぎが解消されている。
- **Steps**:
  1. 現在のパス定義箇所と命名規則を洗い出し、問題点を整理する。
  2. Page側・Router側いずれに定義を寄せるか方針を決定し、共通化手段を設計する。
  3. 既存コードを方針に沿ってリファクタリングし、画面遷移が従来通り動作することを検証する。
- **Description**: ルーティング定義が分散・重複しているため、保守性を高めるべくパス定義の統一と命名整理を行う。

---

## In Progress

---

# 使用法ドキュメント

### 基本原則
- タスクは、Backlog, In Progress, Readyの3つのセクションに分類される
- タスクは、タイトル, ID, Priority, Size, Area, Dependencies, Goal, Steps, Descriptionの各フィールドを持つ
- タスクIDは`{エリア}-{タスクカテゴリ}-{連番}`形式で一意に採番する **(連番は全カテゴリで通し番号)**
- タスクは可能な限り少ない関心事を保持するように分割され、各タスクは独立して遂行可能であることが望ましい
- タスクの内容は、他のタスクと重複しないように注意する

### タスクの移動ルール
1. Backlog
2. Ready
3. In Progress
4. 完了(削除)
  の順に移動される。各セクションの移動時に必要な条件は以下の通り。
  - `1. ~ 2.`: 
   - タスクの基本フォーマットに従っている
   - タスクの内容が他のタスクと重複していない
   - タスクの関心事が必要程度まで分解済みである
  - `2. ~ 3.`:
   - タスクの内容が明確で、実行可能な状態である
   - タスクのGoalフィールドに達成条件が記載されている
   - タスクのStepsフィールドに実行計画が記載されている
  - `3. ~ 4.`:
   - タスクのGoalフィールドに記載された達成条件を満たしている
   - タスクのStepsフィールドに記載された実行計画が完了している


### 基本運用ワークフロー

#### タスク追加時
1. 重複タスクの確認
2. タイトル, ID, Priority, Size, Area, Dependencies, Descriptionを記述
3. Goalフィールドにタスクを達成とみなすための条件を記述
4. Sizeが'S'以上である場合、決定事項から現時点で推測できるおおよその段階をStepsフィールドに記述
5. タスクを、重要度・完成度・推定サイズから総合判断してBacklogもしくはReadyセクションに移動

#### タスク遂行時(行うタスクが決定済みの場合)
1. タスクをIn Progressセクションに移動
2. タスク内容やStepsを参考に、実際の行動計画を立案する
3. Stepsフィールドを完成した行動計画に置き換える
4. Goalフィールドに記載された達成条件を満たすまで、タスクを実際に遂行する
5. タスクが完了したら削除する

#### タスク遂行時(行うタスクが決定していない場合)
1. Backlogセクションから、以下の基準でタスクを選定
   - 重要度が高いもの
   - 推定サイズが小さいもの
   - 依存関係が少ないもの
2. 選定したタスクをIn Progressセクションに移動
3. タスク内容やStepsを参考に、実際の行動計画を立案する
4. Stepsフィールドを完成した行動計画に置き換える
5. Goalフィールドに記載された達成条件を満たすまで、タスクを実際に遂行する
6. タスクが完了したら削除する

### 各フィールドの説明

#### タイトル
- タスクの簡潔なタイトルを記載
- 以下の種別を含める
  - Feature: 新機能追加
  - Enhancement: 機能改善
  - Bugfix: バグ修正
  - Refactor: リファクタリング
  - Performance: パフォーマンス改善
  - Documentation: ドキュメント整備
  - Testing: テストコード追加・修正
  - Chore: 雑多な作業
- `[種別] タスク内容`の形式で記載

#### ID
- タスク識別子。
- 形式は`{エリア}-{タスクカテゴリ}-{連番}`。
- 連番は同じエリア・タスクカテゴリの組み合わせごとに1から昇順で採番する。
- 例: `Order-Bugfix-3`, `UI/UX-Enhancement-5`

#### Priority
- タスクの優先度を示す
- **P0**: 運用または開発を阻害するクリティカルな問題。即座に対応が必要。
- **P1**: 重要な機能や修正。優先的に対応が必要。
- **P2**: 中程度の重要度。計画的に対応。依存関係の親にあたるタスクはP2以上に設定。
- **P3**: 低優先度。時間があるときに対応。

#### Size
- タスクの推定サイズ・工数を示す
- **XS**: 0.5日以下の軽微な修正
- **S**: 1日で完了する小規模タスク
- **M**: 2-3日で完了する中規模タスク
- **L**: 1週間で完了する大規模タスク
- **XL**: 2週間以上の大型タスク

#### Area
- タスクが属する領域を示す
- **Core**: アプリケーションのコア機能。
  - `core/`配下

- **UI/UX**: UI,UXに関するタスク。
  - `shared/`配下
  - `features/(feature_name)/presentation/`配下
  - `routing/`配下

- **Inventory**: 在庫管理featureに関するタスク。
  - `features/inventory/`配下(presentationを除く)

- **Order**: 注文管理featureに関するタスク
  - `features/order/`配下(presentationを除く)

- **Analytics**: 分析やレポート機能に関するタスク
  - `features/analytics/`配下(presentationを除く)

- **Menu**: メニュー管理機能に関するタスク
  - `features/menu/`配下(presentationを除く)

- **Documentation**: ドキュメントやガイドラインの整備
  - `docs/`配下

- **Testing**: テストコードの追加や修正
  - `tests/`配下

- **DevOps**: 開発環境やCI/CDに関するタスク
  - 明確な該当ディレクトリは無し。

#### Dependencies
- 他のタスクや機能に依存する場合は、ここに記載
- 依存関係がない場合は"None"と記載
- 依存するタスクが完了しないと着手できない場合は、Backlogセクションに移動
- 明確な記述フォーマット無し

#### Goal
- タスクを達成とみなすための条件を記載
- タスクの目的や成果物を明確にする
- 明確な記述フォーマット無し

#### Steps
- Sizeが`S`以上のタスクに対して、実際の行動計画を記載
- タスクを遂行するための具体的なステップを記載
- タスクの内容に応じて、必要な手順を詳細に記述
- `1.`のように番号を付けて、順序を明確にする

#### Description
- タスクの背景や目的、詳細な説明を記載
- タスクの内容を理解するための補足情報を提供
- 明確な記述フォーマット無し

### タスクの記述例
```markdown
### [Feature] 新規ユーザ登録機能の実装
- **ID**: Core-Feature-1
- **Priority**: P1
- **Size**: M
- **Area**: Core
- **Dependencies**: None
- **Goal**: ユーザが新規登録できるようにする。
- **Steps**:
  1. ユーザ登録フォームのUI設計
  2. バックエンドAPIとの連携実装
  3. 入力バリデーションの実装
  4. ユーザ登録後のリダイレクト処理実装
- **Description**: 新規ユーザがアプリケーションに登録できるようにする機能。ユーザ登録フォームを作成し、バックエンドAPIと連携してユーザ情報を保存する。入力バリデーションを実装し、登録後はログイン画面にリダイレクトする。

### [Bugfix] ログイン画面のバリデーションエラー表示修正
- **ID**: UI/UX-Bugfix-1
- **Priority**: P2
- **Size**: S
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: ログイン画面でのバリデーションエラーが正しく表示されるようにする。
- **Steps**:
  1. ログインフォームのバリデーションロジックを確認
  2. エラーメッセージの表示位置を修正
  3. テストケースを追加して動作確認
- **Description**: ログイン画面でのバリデーションエラーが正しく表示されない問題を修正する。エラーメッセージの表示位置を調整し、ユーザが入力ミスを理解しやすくする。
```
