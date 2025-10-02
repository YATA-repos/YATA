# TODO

Next ID No: 23

--- 

Definitions to suppress Markdown warnings

[Bugfix]: #
[Feature]: #
[Enhancement]: #
[Performance]: #
[Documentation]: #
[Chore]: #

## あとでタスク定義
- loggingのlevelやconfigが全体的にうまく動いていないので修正する
- 注文状況ペーにおいて、注文カードクリック時に詳細モーダルを開く（履歴に移動するのか、ページ維持でモーダルだけ開くのか要検討）
- app_router.dartで、pathをハードコードするのか、Page側で定義するのか、統一する
- メニュー管理画面の、UI完全刷新。おそらくモックを参考にする

## Backlog

### [Documentation] CSVデータ辞書を整備する
- **ID**: Documentation-Documentation-18
- **Priority**: P1
- **Size**: M
- **Area**: Documentation
- **Dependencies**: None
- **Goal**: `docs/reference/dataset_dictionary.md` に主要CSVのカラム定義とキー方針が整理され、チームが参照できる状態になる。
- **Steps**:
  1. 既存スキーマと草案CSVを突き合わせて必要なカラム・キー情報を洗い出す。
  2. データセットごとの定義・データ型・計算式をドキュメントに記載する。
  3. レビューを経て`docs/reference/`配下に公開し、TODOのNext Stepsへ反映する。
- **Description**: CSVエクスポート実装の前提としてデータ辞書を整備し、Phase 0の基盤準備を完了させる。

### [Enhancement] ExportService API設計レビューを完了する
- **ID**: Core-Enhancement-19
- **Priority**: P1
- **Size**: S
- **Area**: Core
- **Dependencies**: Documentation-Documentation-18
- **Goal**: ExportServiceのAPI仕様がレビュー承認され、実装に必要なインターフェースとエラーハンドリング方針が固まる。
- **Steps**:
  1. 提案中のAPI仕様を整理し、入出力・エラーケース・認可要件を明文化する。
  2. Backendリードとのレビューを実施し、指摘事項を反映する。
  3. 承認済み仕様を`docs/plan/`または`docs/reference/`に更新し、実装チケットへリンクする。
- **Description**: CSVエクスポートのサービス層実装を開始するために、API契約とレビューを完了させる。

### [Enhancement] CSVエクスポート画面のUIモックを作成する
- **ID**: UI/UX-Enhancement-20
- **Priority**: P1
- **Size**: M
- **Area**: UI/UX
- **Dependencies**: Core-Enhancement-19
- **Goal**: エクスポート設定画面のUIモックが作成され、デザインレビューで承認される。
- **Steps**:
  1. フィルタ・進捗表示・完了通知を含むワイヤーフレームを作成する。
  2. デザインレビューを実施し、フィードバックを反映する。
  3. 最終モックとUXノートを`docs/plan/2025-10-02-csv-export-implementation-plan.md`へ追記する。
- **Description**: Flutter実装前にUI/UXを固め、Phase 1での画面開発を円滑に進める。

### [Feature] Supabase RPCプロトタイプで売上明細CSVを生成する
- **ID**: Core-Feature-21
- **Priority**: P1
- **Size**: M
- **Area**: Core
- **Dependencies**: Core-Enhancement-19
- **Goal**: `fn_export_csv` プロトタイプが構築され、売上明細CSVを指定期間で出力できることを確認する。
- **Steps**:
  1. モックデータ環境で必要なビュー・サンプルデータを準備する。
  2. Supabase RPCを実装し、期間・店舗パラメータでCSV文字列を返す。
  3. 出力フォーマットと性能を検証し、改善点を記録する。
- **Description**: Phase 1の実装に向けて、Supabase側のエクスポート基盤を技術検証する。

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

### [Enhancement] 在庫管理画面をmockベースで再設計するか検討
- **ID**: Inventory-Enhancement-2
- **Priority**: P2
- **Size**: L
- **Area**: Inventory
- **Dependencies**: None
- **Goal**: モックと現行UIの差分が整理され、再設計方針と後続タスクがドキュメント化されている。
- **Steps**:
  1. 現行画面とモックUIを比較し差分・課題を洗い出す。
  2. 改善事項を優先度と影響範囲ごとに整理する。
  3. 再設計方針と必要タスクをドキュメントにまとめる。
- **Description**: モックの方が完成度が高い現状を解消するため、再設計の方針を決定し後続開発を進められる状態にする。

### [Enhancement] メニュー管理画面のUI整理方針を検討する
- **ID**: Menu-Enhancement-4
- **Priority**: P2
- **Size**: M
- **Area**: Menu
- **Dependencies**: None
- **Goal**: メニュー管理画面の問題点と改善指針を整理したドキュメントが用意され、具体的な改修タスクを切り出せる。
- **Steps**:
  1. 現行画面の情報量・導線・UIコンポーネントを棚卸しする。
  2. 課題をカテゴリ分けし優先度と対応策を検討する。
  3. 整理結果と推奨アクションをまとめたドキュメントを作成する。
- **Description**: メニュー管理画面がごちゃついているため、改善方針を整理し次の実装につなげる準備を行う。

### [Enhancement] PC表示時にレイアウト幅を最適化する
- **ID**: UI/UX-Enhancement-5
- **Priority**: P2
- **Size**: S
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: PCフルスクリーン表示で利用可能領域が適切に広がり、空白が減って見やすいレイアウトになる。
- **Steps**:
  1. 現行のブレークポイント設定とレイアウト挙動を確認する。
  2. 望ましいレイアウト幅とコンポーネント配置を設計する。
  3. レスポンシブ設定を調整し、主要解像度で表示を確認する。
- **Description**: PC全画面に近い表示で余白が大きく非効率なため、ブレークポイントやレイアウトを調整して広い画面を活かす。

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

### [Documentation] menuとrecipeの依存関係を整理する
- **ID**: Documentation-Documentation-9
- **Priority**: P2
- **Size**: M
- **Area**: Documentation
- **Dependencies**: None
- **Goal**: menuとrecipeの依存関係と設計方針が`docs/`配下に整理され、開発チームで共有できる。
- **Steps**:
  1. 現在のデータモデルとコード実装を調査する。
  2. 依存関係上の課題と改善案を整理する。
  3. 最終的な設計指針と影響範囲をドキュメント化する。
- **Description**: menuが材料依存を持つ必要があるか判断できておらず、データモデリングの整理が必要。調査と指針策定を行う。

### [Documentation] リファレンス系ドキュメントを拡充する
- **ID**: Documentation-Documentation-10
- **Priority**: P2
- **Size**: L
- **Area**: Documentation
- **Dependencies**: None
- **Goal**: 主要機能ごとのリファレンス／ガイド文書が追加され、開発と運用で参照できる。
- **Steps**:
  1. 不足しているリファレンス・ガイドの範囲を洗い出す。
  2. 優先度の高い領域からドキュメント原稿を作成する。
  3. レビューを経て`docs/`配下へ公開する。
- **Description**: リファレンスやガイド文書が不足しており、知識共有が難しい。必要なドキュメントを整理し追加する。

### [Bugfix] ログのファイル書き込みが失敗する問題を修正
- **ID**: Core-Bugfix-11
- **Priority**: P1
- **Size**: M
- **Area**: Core
- **Dependencies**: None
- **Goal**: ログが想定通りファイルへ書き込まれ、運用で追跡できるようになる。
- **Steps**:
  1. 現在のログ設定とエラー内容を調査する。
  2. ファイル出力先や権限など原因を特定し修正する。
  3. ログ出力が正常に行われることをテストで確認する。
- **Description**: ログがファイルに残らず、運用でのトラブルシュートが困難。設定や実装を修正し、安定したログ出力を実現する。

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

### [Performance] 注文画面のlogging設定を見直しパフォーマンス確認
- **ID**: Order-Performance-13
- **Priority**: P2
- **Size**: S
- **Area**: Order
- **Dependencies**: None
- **Goal**: loggingレベル調整などで注文画面のレスポンスが改善するか検証結果が得られる。
- **Steps**:
  1. 現在のlogging設定と出力量を確認する。
  2. ログレベルを切り替えてパフォーマンス計測を行う。
  3. 改善が確認できた場合は設定変更案をまとめる。
- **Description**: loggingの影響で注文画面が重いと推測されている。ログ設定を見直し、性能への影響を確認する。

---

## Ready

### [Enhancement] 注文詳細モーダルをオーバーレイクリックで閉じる
- **ID**: UI/UX-Enhancement-14
- **Priority**: P2
- **Size**: XS
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: 注文詳細モーダル表示中に背景クリックでモーダルが閉じる。
- **Steps**:
  1. モーダルコンポーネントのイベントハンドラを確認する。
  2. オーバーレイクリック時にモーダルを閉じる処理を追加する。
  3. モバイル・PCの双方で挙動を確認する。
- **Description**: モーダル外をクリックしても閉じられず操作性が低い。一般的なモーダル挙動に合わせる。

### [Chore] 在庫管理画面の適用ボタンアイコンを削除する
- **ID**: UI/UX-Chore-17
- **Priority**: P3
- **Size**: XS
- **Area**: UI/UX
- **Dependencies**: None
- **Goal**: 在庫管理画面の適用ボタンからアイコンが取り除かれ、テキストのみで表示される。
- **Steps**:
  1. 対象ボタンのコンポーネントを特定する。
  2. アイコンウィジェットの記述を削除し、スタイルを調整する。
  3. ボタン表示が崩れないことを確認する。
- **Description**: 適用ボタンのアイコンが不要で視覚的ノイズになっているため、テキストのみの表示にする。

---

## In Progress

---

# 使用法ドキュメント

### 基本原則
- タスクは、Backlog, In Progress, Readyの3つのセクションに分類される
- タスクは、タイトル, ID, Priority, Size, Area, Dependencies, Goal, Steps, Descriptionの各フィールドを持つ
- タスクIDは`{エリア}-{タスクカテゴリ}-{連番}`形式で一意に採番する(連番は全カテゴリで通し番号)
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
