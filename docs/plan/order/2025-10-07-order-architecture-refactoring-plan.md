# 2025-10-07 Orderサービス構造改善計画

## 1. 目的と背景
- `lib/features/order/` 配下は平均ファイルサイズ 386 行、サービス 10 件と他 feature よりも複雑。
- Facade 層の冗長化、巨大コントローラ/ページ、依存関係の重複が保守性と開発速度を阻害。
- `docs/survey/order_survey/` 一式および `docs/draft/order/order_bugfix_3_investigation.md` で指摘された課題を踏まえ、段階的な改善計画を策定する。

## 2. スコープ
- Order 機能のサービス層・プレゼンテーション層のリファクタリング。
- テスト・ドキュメント整備、ならびに在庫連携処理の責務整理。
- 新機能追加は対象外だが、既知バグ (Order-Bugfix-3) の再発防止策を含む品質確保を目的に含む。

## 3. 成功指標 (KPI)
| 指標 | 現状 | 目標 (Phase 完了時) |
|------|------|------------------|
| 平均ファイルサイズ (Order) | 386 行 | 280 行 以下 |
| `order_management_controller.dart` 行数 | 1,680 行 | 400 行 以下 |
| Facade サービス数 | 3 | 0 |
| クリティカルバグ再発率 (3 ヶ月移動平均) | 2 件/四半期 | 0 件 |

## 4. 現状の主要課題
1. **過剰な階層化**: Cart/Kitchen Facade は単純委譲、OrderService は Management と重複。
2. **巨大コントローラ/ページ**: `order_management_controller.dart` (1,680 行)、`order_management_page.dart` (1,031 行)、`order_history_page.dart` (926 行)。
3. **依存関係の重複**: `OrderCalculationService` と `OrderStockService` への注入が 3 箇所以上で重複。
4. **在庫連携ロジックの重複**: `order/services/order_stock_service.dart` と `inventory/services/order_stock_service.dart` で名称・責務が曖昧。
  - 2025-10-08 時点: Order 側サービスは `order_inventory_integration_service.dart` へ改名済み。

## 5. 改善イニシアチブ

### Phase 1 (Week 1): Facade 層の削除
- **目的**: 冗長な Facade を排除し、DI/責務を明瞭化。
- **タスク**:
  - ✅ `cart_service.dart` と `kitchen_service.dart` の削除、呼び出し元を Management Service に差し替え。
  - ✅ `order_management_controller.dart` などでのプロバイダ参照更新。
  - ✅ 影響範囲のユニットテスト更新。
- **成果物**: Facade サービスが存在しない状態、テスト緑。
- **リスク/対応**: 呼び出し差し替え漏れ → `grep` による確認 + テスト。

### Phase 2 (Week 1-3): コントローラ分割
- **目的**: 責務単位でロジックを分離し可読性とテスト容易性を改善。
- **タスク**:
  - ✅ `order_management_state.dart` (State/Model) を新設。
  - ✅ `MenuFilterController`、`CartOperationController`、`CheckoutController` 等へロジック分割。
  - ✅ 既存テストの再配置と不足シナリオ追加 (カート更新、バリデーション)。
- **成果物**: 400 行以下のコントローラ複数 + 更新済みテスト。
- **リスク/対応**: 状態共有の破綻 → Riverpod Provider 設計レビュー、スモークテスト実施。

### Phase 3 (Week 3-5): UI 分割と再利用性向上
- **目的**: 巨大ページの解体と UI コンポーネントの再利用促進。
- **実施状況 (2025-10-07)**:
  - ✅ `order_management_page.dart` を 1,033 行 → 218 行へ縮小し、`widgets/` 配下に `menu_selection_section.dart` / `current_order_section.dart` / `order_page_error_banner.dart` を新設。
  - ✅ コントローラ依存をコールバック API 化し、部品単体でのテスト容易性を確保。
  - ✅ `order_management_sections_test.dart` を追加し、検索フィルタ・会計フローなど主要 UI のインタラクションを Widget Test で担保。
  - 🔍 `_images/mocks/order_management_page.png` と比較し UI 差異レビューを完了 (レイアウト差異なし)。
- **次アクション**:
  - ゴールデンテスト更新を Phase 3 レトロスペクティブで合意済みの UI checklist に基づき後続対応。
- **成果物**: メインページ <600 行、ウィジェットごとのテストが存在。
- **リスク/対応**: デザイン破綻 → デザイナー/PO による UI チェックリストで検証。

### Phase 4 (Week 5-8): サービス統合と命名整理
- **目的**: OrderService の統合、在庫連携サービスの責務明確化。
- **タスク**:
  - `OrderService` のリアルタイム機能を `OrderManagementService` へ移管。
  - `order_stock_service.dart` を `order_inventory_integration_service.dart` へ改名し inventory との境界を整理。
  - Supabase Realtime 購読の統合テストを作成。
- **成果物**: 統合後のサービス図 (`docs/reference/order/service-layer-architecture.md`) 更新。
- **リスク/対応**: Realtime 停止 → feature flag で段階的に切り替え、監視ログ強化。

### Phase 5 (Week 8-12): Management 層モジュール化 (拡張)
- **目的**: Cart/Order/Kitchen の責務をサブパッケージに再編成し長期的拡張性を確保。
- **タスク**:
  - `services/cart/`, `services/order/`, `services/kitchen/`, `services/shared/` 構造へ移行。
  - 共通ユーティリティ (`order_validation_utils.dart`) を shared へ集約。
  - DX 観点のドキュメント更新と社内 Tech Talk 実施。
- **成果物**: 新ディレクトリ構造 + ガイドライン + 90 分のナレッジ共有セッション。
- **リスク/対応**: 大規模変更 → feature flag / release branch 運用、並行開発チームと週次シンク。

### 継続的アクティビティ
- 毎 Phase 完了時に `docs/plan/order/` にフォローアップレポートを追加。
- `docs/survey/order_survey/service-dependency-diagram.md` を改善後バージョンへ更新。
- 計測指標の再サンプリング (Phase 3, Phase 5 完了時)。

## 6. 実行ロードマップ (概算)
| 週 | 主要マイルストーン | オーナー | チェックポイント |
|----|----------------------|----------|------------------|
| Week 1 | Facade 削除完了 (Phase 1) | Backend | PR レビュー + 動作確認 |
| Week 2 | コントローラ分割着手 | Backend | 新コントローラ骨子レビュー |
| Week 3 | コントローラ分割完了・テスト緑 (Phase 2) | Backend/QA | Regression テストレポート |
| Week 4 | UI 分割設計レビュー | Frontend | UI Wireframe 承認 |
| Week 5 | UI 分割完了 (Phase 3) | Frontend | ゴールデンテスト結果 |
| Week 6 | Realtime 統合 PR | Backend | Supabase QA 環境検証 |
| Week 8 | Phase 4 完了 | Backend | 新サービス図リリース |
| Week 9-12 | Management 再編成 (Phase 5) | Backend/Architecture | DX 評価アンケート |

## 7. 品質保証 & 計測
- `flutter test --coverage` を CI に追加し、Order 関連カバレッジをバッジ化。
- リリースブランチで Supabase のエラーログ、アプリ内例外ログ `_logs/app-*.log` を監視。
- UI はゴールデンテスト + 手動探索テスト (ケース一覧は QA チーム管理の TestRail に登録)。
- 主要 KPI は Phase 完了ごとに `docs/analysis/order/` へレポート化。

## 8. リスクと緩和策
| リスク | 影響 | 緩和策 |
|--------|------|--------|
| Realtime 統合で注文通知が停止 | 高 | フィーチャーフラグ + ロールバック手順文書化 |
| 並行開発とのコンフリクト | 中 | 週間シンク、`feature/order-refactor` ブランチ運用 |
| テスト不足によるバグ混入 | 高 | Phase 0 でのテスト整備、Phase 毎に QA チェックリスト消化 |
| 学習コスト増大 | 中 | 設計レビュー記録、Tech Talk、Slack Q&A チャンネル |

## 9. コミュニケーション・承認フロー
- 週次ステータス: 金曜 15:00、進捗 + リスク共有。
- レビュー: 各 Phase 終了時に PO/QA/Tech Lead の承認必須。
- ドキュメント更新: `docs/reference/order/` の更新が必要な場合は PR に含める。

## 10. フォローアップと再調査
- Phase 3 完了後に `docs/survey/order_survey/2025-refactoring-analysis.md` をベースに再計測し、比較レポートを `docs/survey/order_survey/2025-refactoring-delta.md` として追加。
- Phase 5 実施判断は Phase 3 完了後の ROI 評価ミーティングで決定。
- KPI 未達の場合は追加調査 (重点: 在庫連携、リアルタイム遅延) を別途立案。

## 11. 参照資料
- `docs/survey/order_survey/2025-refactoring-analysis.md`
- `docs/survey/order_survey/EXECUTIVE_SUMMARY.md`
- `docs/survey/order_survey/service-dependency-diagram.md`
- `docs/draft/order/order_bugfix_3_investigation.md`
- 本計画に付随して更新する成果物は `docs/plan/order/` 配下に追加する。
