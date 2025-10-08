# 契約/実装 分離リファクタリング — ハンドオーバー（引継ぎ）

## 現状サマリ（一読用）
- アーキテクチャ方針に従い、契約を `lib/core/contracts/` に集約、実装は従来通り `lib/infra/` に配置。
- 主要横断機能（Logging / Realtime / Cache）を契約化し、アダプタを介して既存実装へ委譲。
- Realtime は Inventory/Order/Menu のサービスに横展開済み（契約Mixinで監視開始/停止を共通化）。
- Repository は共通 CRUD 契約（`CrudRepository`）に加え、ドメイン別の拡張契約を定義し、既存実装が implements 済み。
- DI は `lib/app/wiring/provider.dart` で契約型の Provider を公開（logger/realtime/cache/各repository/主要service）。
- 互換のため logger は `lib/core/logging/compat.dart` を追加し、features/core からの `infra/logging` 直接参照を解消。

---

## 経緯・計画（要点）
- 計画ドキュメント: `docs/plan/contracts/2025-09-15-contracts-separation-plan.md:1`
- ドラフト・作業ログ: `docs/draft/contracts/2025-09-15-contracts-separation-notes.md:1`
- 合意事項（抜粋）
  - 一括導入（One-shot migration）で実施
  - 既存 logger トップレベル関数の互換維持（`t/d/i/w/e/f` 等）
  - features → infra 直接依存は原則禁止（core 契約経由へ）
  - `core/constants/query_types.dart` の Supabase 依存は短期容認（改善メモ記載済み）

---

## 完了済み（実装ハイライト）
- 契約の新設（抜粋）
  - 共通 CRUD: `lib/core/contracts/repositories/crud_repository.dart:1`
  - Logging: `lib/core/contracts/logging/{logger,log_sink,log_formatter,pii_masker}.dart:1`
  - Realtime: `lib/core/contracts/realtime/{realtime_manager,connection}.dart:1`
  - Cache: `lib/core/contracts/cache/{cache,cache_strategy,cache_metadata}.dart:1`
  - Batch: `lib/core/contracts/batch/batch_processing_service.dart:1`
  - Repository（ドメイン別拡張）:
    - Inventory: material/material_category/recipe/supplier/material_supplier/stock_adjustment/stock_transaction/purchase/purchase_item
    - Menu: menu_item/menu_category
    - Order: order/order_item
    - Analytics: daily_summary
- 主要アダプタと互換層
  - Logging アダプタ: `lib/infra/logging/logger_adapter.dart:1`（契約 Logger → 既存 logger API）
  - Realtime アダプタ: `lib/infra/realtime/realtime_manager_adapter.dart:1`（契約 → Supabase 実装）
  - Cache アダプタ: `lib/infra/local/cache/{memory_cache_adapter,ttl_cache_adapter}.dart:1`
  - Logger 互換: `lib/core/logging/compat.dart:1`（features/core はここ経由で logger を使用）
- Realtime 横展開（契約Mixin）
  - 共通 Mixin: `lib/core/realtime/realtime_service_mixin.dart:1`
  - Inventory: `lib/features/inventory/services/inventory_service.dart:1`（契約注入 + 監視）
  - Order: `lib/features/order/services/order/order_management_service.dart:1`（契約注入 + 監視）
  - Menu: `lib/features/menu/services/menu_service.dart:1`（契約注入 + 監視）
- Repository の契約適合
  - `lib/infra/repositories/base_repository.dart:1` を `CrudRepository` implements 化
  - 各ドメイン Repository が拡張契約を implements（機能メソッドは従来踏襲）
- DI（Riverpod）整備（契約型で公開）
  - `lib/app/wiring/provider.dart:1` に logger/realtime/cache/各repository の Provider を追加
  - Inventory/Order/Menu のサービスも契約Realtimeを注入する Provider を追加
- core の infra 直参照を互換経由へ移行
  - 例: `lib/core/utils/{error_handler,query_utils}.dart:1`, `lib/core/validation/{input_validator,type_validator}.dart:1`

---

## 未完了・次のステップ
1) サービスの依存を「契約Provider注入」に全面置換（残）
- 目的: features 内の各サービスが repository 具象を `new` せず、契約 Provider から注入する
- 対象候補（例）: 
  - Inventory: `material_management_service.dart`, `stock_level_service.dart`, `usage_analysis_service.dart`, `stock_operation_service.dart`
  - Order: `order_management_service.dart`, `order_inventory_integration_service.dart`
  - Menu: `menu_service.dart`
- 対応方針:
  - `app/wiring/provider.dart:1` に契約型 Provider（例: `Provider<MaterialRepositoryContract>`）を追加
  - サービスのコンストラクタで `ref.read(...)` に置換（必要ならファクトリ/パラメータ追加）

2) features → infra 直接参照の最終洗い出しと除去
- 探索: `rg -n "\binfra/" lib/features`
- 原則: features は core 契約と app の合成（Provider）にのみ依存

3) Realtime 契約の型安全性向上（改善案）
- 現状: `featureName` は文字列、アダプタで enum へマッピング
- 案: core 側へ `FeatureName` 型（sealed class/enum的な表現）を追加し、実装アダプタへ安全に渡す

4) Supabase 依存の縮退（中期）
- 現状: `lib/core/constants/query_types.dart:1` が `supabase_flutter` に依存（短期容認）
- 案: 純粋抽象へ再設計 → `infra` に Adapter 実装（QueryBuilder 変換）
- 参照: `docs/plan/contracts/2025-09-15-contracts-separation-plan.md:1` 改善メモ

5) 検証フェーズ（ステップ6）
- `flutter analyze` による静的解析
- `flutter build` によるビルド確認（主要プラットフォーム）
- 手動回帰（在庫/注文/メニュー）
  - Realtime: INSERT/UPDATE/DELETE の受信ログを確認
  - キャッシュ: メモリ/TTL 経由の read-through/invalidations の挙動確認

---

## 既知の注意点・リスク
- Realtime 機能識別が文字列ベース
  - 未知値のフォールバックがアダプタ側にあるため、命名/変更時は注意（`realtime_manager_adapter.dart:1`）
- DI の二重経路（暫定）
  - 一部サービスが「具象の new」と「契約の注入」を併用中（段階移行のため）。早期に契約注入へ統一する。
- Supabase 依存の core 漏れ
  - 早期に抽象化設計を固めることで、実装置換性を高める（Adapter 方式）

---

## 検証手順（参考）
- 契約配置の確認
  - `tree -L 2 lib/core/contracts`
- features → infra 直参照のスキャン
  - `rg -n "\\binfra/" lib/features`
- 解析/ビルド
  - `flutter analyze`
  - `flutter build apk`（Android）/ `flutter build windows`（Windows）
- 主要ユースケース
  - 材料作成/更新 → 在庫レベルの反映/アラート
  - 注文作成/更新 → キッチン進捗/分析ロジックの反映
  - メニュー可否切替 → 注文画面反映（Realtime）

---

## 参照ファイル
- 設計方針: `docs/standards/architecture.md:1`
- 計画書: `docs/plan/contracts/2025-09-15-contracts-separation-plan.md:1`
- 作業メモ: `docs/draft/contracts/2025-09-15-contracts-separation-notes.md:1`
- DI 集約: `lib/app/wiring/provider.dart:1`
- Logger 互換: `lib/core/logging/compat.dart:1`
- Realtime Mixin: `lib/core/realtime/realtime_service_mixin.dart:1`
- 代表アダプタ: `lib/infra/logging/logger_adapter.dart:1`, `lib/infra/realtime/realtime_manager_adapter.dart:1`, `lib/infra/local/cache/memory_cache_adapter.dart:1`

---

## 次担当者へのメモ
- まずは「サービスの依存注入を契約Providerに統一」から着手すると差分が最小で効果が高いです。
- その後、`flutter analyze` → `build` → 手動回帰の順に検証してください。
- 設計の悩みどころ（Realtime機能名/Query抽象化）は、`docs/plan/...` の改善メモ方針に沿って段階対応でOKです。

