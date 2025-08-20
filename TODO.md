# TODO

---

## Backlog

### [Routing] 初期ルート/home切替と/menuエイリアス化、/menu-management移設

- **Priority**: P1
- **Size**: M
- **Area**: Routing
- **Dependencies**: [Feature] POSメニュー選択画面の実装
- **Goal**: 初期ルートを`/home`へ切替し、`/menu`を`/home`のエイリアスとして扱う。既存のメニュー管理画面は`/menu-management`へ移設する
- **Steps**:
  1. `lib/app/routes.dart`の`initialLocation`を`/home`へ変更
  2. `/home`ルートを追加しメニュー選択画面へ紐付け、`/menu`を同一画面のエイリアス化
  3. 既存`/menu`（MenuManagementScreen）を`/menu-management`へ移設
  4. ナビゲーションリンク・ガード・エラーページの遷移先を再確認
  5. 主要導線のリグレッション確認
- **Description**: 実装計画（Option B）に基づくルーティング切替。破壊的変更のため移設とリンク更新を同時に行う

### [Feature] POSメニュー選択画面の実装（/home, /menu alias）

- **Priority**: P1
- **Size**: L
- **Area**: UI/UX
- **Dependencies**: None（共通UI・DTOは実装済み）
- **Goal**: 左カタログ/右注文サマリー構成のメニュー選択画面を新設し、注文ドラフト/会計導線を提供する
- **Steps**:
  1. `features/menu/presentation/screens/menu_selection_screen.dart`新設
  2. 商品検索/グリッド/フィルタのUI実装（Provider連動）
  3. 注文サマリー（InfoBadge, 小計/税/合計, 会計/クリア）実装
  4. `product_controller`/`order_draft`のProvider実装とサービスへの接続
  5. 画面遷移・戻り導線の確認
- **Description**: 仕様書のUIスニペットに準拠してPOS用途のメイン画面を構築する



### [Enhancement] 注文履歴の仕様差分反映（±1日ナッジャ/表示設定/エクスポート/ページネーション）

- **Priority**: P1
- **Size**: M
- **Area**: UI/UX
- **Dependencies**: None（共通DTO・UIは実装済み）
- **Goal**: `OrderHistoryScreen`に仕様差分を反映し、UI→Service接続を完了させる
- **Steps**:
  1. 日付±1日ナッジャボタンと左右キー操作を追加
  2. 表示設定ダイアログ（列表示ON/OFF）の実装
  3. エクスポート導線を`OrderService.exportCsv`へ接続
  4. ページネーション/ソートを`OrderService.list(PageReq)`へ接続
  5. ローディング/エラー/リトライのUX整備
- **Description**: temp.md v0.2の差分を忠実に反映し、機能の完成度を高める

### [Enhancement] 在庫管理のCSV入出力導線/ページネーション/StatusPill統合

- **Priority**: P1
- **Size**: M
- **Area**: UI/UX, Core
- **Dependencies**: None（共通DTO・UIは実装済み）
- **Goal**: 在庫画面にCSVインポート/エクスポート、ページング、状態表示を統合する
- **Steps**:
  1. AppBarツールバーにupload/download/refreshを追加
  2. `csv_import_service`ラッパー経由で`InventoryService.importCsv/exportCsv`へ接続
  3. 行の状態表示を`StatusPill`へ統一
  4. ページネーションを`InventoryService.list(PageReq)`へ接続
  5. Snackbarで取込件数/失敗ログURLを通知
- **Description**: 仕様I/Oに沿った実用的な在庫運用導線を整備する

### [Enhancement] 売上分析 Granularity/KPI 接続（チャートはプレースホルダ維持）

- **Priority**: P2
- **Size**: M
- **Area**: UI/UX
- **Dependencies**: None（共通DTOは実装済み）
- **Goal**: `daily|weekly|monthly`の粒度切替とKPI取得をProvider/Serviceに接続する
- **Steps**:
  1. Providerへ`granularity`を追加し、フィルタ適用時に各APIを同一DateRangeで呼出
  2. `AnalyticsService.getKpis/getDailySalesSeries/getCategorySales`を型合わせ
  3. KPIカード表示の確定（チャートはplaceholder継続）
  4. ローディング/エラー処理の整備
- **Description**: 仕様I/Oの確定値に準拠し、分析画面の基礎機能を完成させる

### [Chore] DoD検証と最終微調整

- **Priority**: P2
- **Size**: S
- **Area**: QA
- **Dependencies**: 上記全タスク
- **Goal**: DoD準拠の確認と視覚差異/UXの最終調整を行う
- **Steps**:
  1. 4画面の視覚差異・操作導線の確認
  2. ページネーション/ソート/フィルタ/CSV入出力の一連動作確認
  3. ログ/リトライ導線の確認と不足箇所の補完
  4. 影響範囲のドキュメント反映（必要最小限）
- **Description**: 実装計画のDoDに基づき、品質の底上げと完成度の最終チェックを実施

### [Documentation] 開発原則・理念ドキュメントの整備

- **Priority**: P2
- **Size**: M
- **Area**: Documentation
- **Dependencies**: None
- **Goal**: フィーチャーベース・サービスレイヤーアーキテクチャの設計思想とUIデザイン原則を含む開発理念ドキュメントを作成し、新規開発者が理解できる状態にする
- **Steps**:
  1. 現在のアーキテクチャ設計思想を整理・文書化
  2. フィーチャーベース・サービスレイヤーアーキテクチャの設計原則を記述
  3. UIデザイン原則とコンポーネント設計指針を策定
  4. プロジェクトの開発理念とベストプラクティスを明文化
  5. 新規開発者向けのオンボーディングガイドとして整備
- **Description**: フィーチャーベース・サービスレイヤーアーキテクチャの設計思想とUIデザイン原則を含む開発理念ドキュメントの作成。lintルールとは分離し、設計哲学に焦点を当てる

### [Refactor] base_repository.dart設計課題の解決

- **Priority**: P1
- **Size**: L
- **Area**: Core
- **Dependencies**: None
- **Goal**: base_repository.dartの19箇所の設計検討事項（`// *`コメント）と14箇所の疑問点（`// ?`コメント）を解決し、Repository層の設計を確定させる
- **Steps**:
  1. 設計検討事項19箇所の内容と影響範囲を調査
  2. 疑問点14箇所の技術的妥当性を検証
  3. 各項目の解決方向性を決定（事前定義、エラーハンドリング詳細化等）
  4. 優先度付けと段階的実装計画の策定
  5. 高優先度項目から順次実装・検証
  6. Repository層のベストプラクティス文書化
- **Description**: base_repository.dartに散在する設計検討事項と疑問点を体系的に解決。Repository層の設計を確定させ、今後の開発における一貫性を確保する。主要な検討項目は事前定義の必要性、エラーハンドリングの詳細化、クエリメソッドの最適化など

### [Enhancement] TODO.mdタスク管理コマンドの実装

- **Priority**: P2
- **Size**: M
- **Area**: DevOps
- **Dependencies**: None
- **Goal**: Claude CodeとGitHub Copilot用のTODO.mdタスク管理コマンド（追加・お任せ実装・指定実装）を作成し、開発効率を向上させる
- **Steps**:
- 1. /todo-add-auto コマンドの実装（現在のコードベースから自動的にタスクを追加）
  2. /todo-add コマンドの実装（対話式タスク追加）
  3. /todo-auto コマンドの実装（Ready→In Progress→完了の自動化）
  4. /todo-do コマンドの実装（タイトル検索ベースの指定実装）
  5. 各コマンドのテストと動作確認
- **Description**: TODO.mdの運用を効率化するため、AIエージェント用のスラッシュコマンドを実装。タスクの追加、自動選択実装、指定実装の3つの機能を提供し、開発ワークフローを改善する

### [Refactor] 基本UIコンポーネントのレビューと改善

- **Priority**: P2
- **Size**: L
- **Area**: UI/UX
- **Dependencies**: None
- **Steps**:
  1. shared/widgets配下の全コンポーネントの棚卸しと使用状況調査
  2. 各コンポーネントのアクセシビリティ要件をチェック
  3. デザインシステムとの一貫性を確認・評価
  4. 使用頻度の低いコンポーネントの統合・削除を検討
  5. パフォーマンス問題の特定と最適化
  6. 改善点の実装とテストケース追加
- **Description**: shared/widgets配下のコンポーネントの一貫性、ユーザビリティ、アクセシビリティの見直しと改善

### [Feature] エクスポート機能の実装

- **Priority**: P2
- **Size**: M
- **Area**: Core
- **Dependencies**: None
- **Steps**:
  1. csvパッケージ導入
  2. ローカルファイル保存機能（file_picker使用）
  3. Web版ダウンロード機能対応
  4. Excel形式エクスポート（excel パッケージ使用）
  5. PDF形式エクスポート（pdf パッケージ使用）
  6. エクスポート履歴管理機能
- **Description**: 在庫データと注文履歴の実際のファイルエクスポート機能。CSV、Excel、PDF形式をサポート

### [Feature] 本格的チャート機能の実装

- **Priority**: P2
- **Size**: L
- **Area**: UI/UX
- **Dependencies**: fl_chart パッケージ導入
- **Steps**:
  1. fl_chartパッケージの導入と設定
  2. 既存ChartPlaceholderの置き換え設計
  3. 折れ線チャート（売上推移）の実装
  4. 円グラフ（商品別売上比率）の実装
  5. 棒グラフ（商品別販売数）の実装
  6. 面グラフ（時間帯別売上）の実装
  7. インタラクティブ機能（ズーム、フィルター）の追加
  8. レスポンシブ対応とアニメーション実装
- **Description**: AnalyticsServiceと連携した本格的なチャート機能。fl_chartを使用したインタラクティブなデータ可視化

### [Enhancement] stream_manager_mixinのメモリリーク対策強化

- **Priority**: P2
- **Size**: S
- **Area**: Core
- **Dependencies**: None
- **Goal**: StreamSubscriptionとStreamControllerの適切な管理を保証し、メモリリークリスクを完全に排除する
- **Steps**:
  1. stream_manager_mixin.dartの現在の実装を詳細調査
  2. 使用箇所でのdispose処理の適切性を確認
  3. メモリリーク検出のためのテストケース作成
  4. 必要に応じて追加のセーフガード機能を実装
  5. 使用ガイドラインの文書化
- **Description**: lib/core/utils/stream_manager_mixin.dartでのStreamSubscriptionとStreamControllerの管理は適切に実装されているが、使用箇所での適切なdisposeがメモリリーク防止に重要。さらなる安全性向上のための対策を実施

### [Performance] Phase 3: オフライン機能の最適化

- **Priority**: P2
- **Size**: L
- **Area**: Core
- **Dependencies**: オフライン機能の基本実装完了
- **Goal**: オフライン機能におけるパフォーマンス最適化を実装し、オフライン⇔オンライン切り替え時の効率性を向上させる
- **Steps**:
  1. lib/data/local/offline_queue/にオフライン機能を実装
  2. オフライン時のキャッシュ戦略最適化
  3. 同期処理のバッチ最適化
  4. オフライン時のメモリ管理改善
  5. オンライン復帰時の差分同期最適化
  6. オフライン機能のパフォーマンス監視実装
- **Description**: オフライン機能の基本実装が完了次第、パフォーマンス最適化を適用。オフライン⇔オンライン切り替え時のスムーズな動作とリソース効率の向上を実現する

### [Performance] 他機能への最適化展開

- **Priority**: P2
- **Size**: L
- **Area**: Core
- **Dependencies**: パフォーマンス最適化実装の検証とテスト
- **Goal**: Phase 1・2で実装された最適化手法を、注文・メニュー・分析機能に適用し、アプリ全体のパフォーマンスを向上させる
- **Steps**:
  1. 注文管理機能のプロバイダー最適化（keepAlive削除、重複データ取得解消）
  2. メニュー管理機能のUIレイヤー最適化
  3. 分析機能のバッチ処理とキャッシュ戦略適用
  4. 各機能でのconst constructor適用
  5. 統合リアルタイム監視システムへの統合
  6. 機能別パフォーマンス指標の設定と監視
- **Description**: 在庫管理機能で実証されたパフォーマンス最適化手法を、注文・メニュー・分析の各機能に体系的に適用。アプリケーション全体の一貫したパフォーマンス向上を実現する

### [Enhancement] パフォーマンス監視とアナリティクス強化

- **Priority**: P3
- **Size**: M
- **Area**: Analytics
- **Dependencies**: パフォーマンス最適化実装の検証とテスト
- **Goal**: より詳細なパフォーマンス分析機能を実装し、ユーザー体験とシステム効率の継続的改善を実現する
- **Steps**:
  1. ユーザー操作レベルでのパフォーマンス追跡
  2. 機能別・画面別の詳細パフォーマンス分析
  3. リアルタイムパフォーマンス監視ダッシュボード
  4. パフォーマンス異常検知とアラート機能
  5. ユーザー体験指標（UX metrics）の測定
  6. パフォーマンス改善提案の自動生成
- **Description**: パフォーマンス最適化を一過性の取り組みではなく、継続的改善プロセスとして確立。詳細な監視とアナリティクスにより、データドリブンなパフォーマンス改善を実現する

---

## Ready

### [Bugfix] routes.dartのコンパイルエラー修正

- **Priority**: P0
- **Size**: M
- **Area**: Core
- **Dependencies**: None
- **Goal**: 削除されたスクリーンファイルへの参照を現在存在するスクリーンファイルに置き換えてコンパイルエラーを解消する
- **Steps**:
  1. 削除されたスクリーンファイルのインポート文を削除（8ファイル）
  2. 現在存在するスクリーン（InventoryDemoScreen、MenuSelectionDemoScreen、OrderHistoryDemoScreen）のインポートを追加
  3. ルート定義を現在存在するスクリーンクラスに置き換え
  4. 削除されたクラスへの参照を修正（OrderDetailScreenメソッド呼び出し等）
  5. flutter analyzeでエラー解消を確認
- **Description**: lib/app/routes.dartで発生している16個のコンパイルエラーを修正。削除されたanalyticsScreen、loginScreen、dashboardScreenなどの参照を現在のスクリーン構成に合わせて修正する

### [Refactor] base_repository.dartのTODOコメント解決

- **Priority**: P1
- **Size**: L
- **Area**: Core
- **Dependencies**: None
- **Goal**: base_repository.dartに存在する14個のTODOコメントを解決し、Repository層の設計を確定させる
- **Steps**:
  1. エラーハンドリングの詳細化（12箇所のTODOコメント）
  2. 存在チェック用の効率的なメソッド調査・実装（2箇所のTODOコメント）
  3. 各修正内容の動作確認とテスト
  4. Repository層のベストプラクティス文書化
  5. 修正完了後のコードレビュー実施
- **Description**: base_repository.dartの設計検討事項を体系的に解決。主にエラーハンドリングの詳細化とクエリメソッドの最適化を行い、Repository層の一貫性を確保する

### [Style] lintルール違反の修正

- **Priority**: P2
- **Size**: L
- **Area**: Core
- **Dependencies**: None
- **Goal**: 1188個のlintルール違反を修正し、コード品質の統一性を確保する
- **Steps**:
  1. prefer_double_quotes違反の修正（シングルクォート→ダブルクォート）
  2. prefer_relative_imports違反の修正（絶対インポート→相対インポート）
  3. その他のlintルール違反の段階的修正
  4. flutter analyzeでの違反数削減確認
  5. CIでのlintチェック通過確認
- **Description**: プロジェクト全体のコード品質向上のため、large量のlintルール違反を段階的に修正。特にクォート形式とインポート形式の統一化を優先的に実施する


---

## In Progress


---

# 使用法ドキュメント

### 基本原則
- タスクは、Backlog, In Progress, Readyの3つのセクションに分類される
- タスクは、タイトル, Priority, Size, Area, Dependencies, Goal, Steps, Descriptionの各フィールドを持つ
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
2. Steps,Goal以外の各フィールドの記述
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
