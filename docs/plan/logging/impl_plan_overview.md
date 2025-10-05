# Logger DI 移行 実装オーバービュー

最終更新: 2025-10-05

## 1. 現状サマリー

- 互換 API (`core/logging/compat.dart`) を参照しているファイル: 21 件
- 主な影響範囲: Auth / Analytics / Inventory / Menu / Order 各 feature のサービス・リポジトリ・コントローラ層
- Infra 層では既に `InfraLoggerAdapter` が存在し、`loggerProvider` で Riverpod DI が可能な状態

## 2. 対象ファイル一覧

| カテゴリ | ファイル | 備考 |
| --- | --- | --- |
| Auth Service | `lib/features/auth/services/auth_service.dart` | 認証フロー全体でエラー/状態ログを発行 |
| Auth Repository | `lib/features/auth/repositories/auth_repository.dart` | Supabase 認証呼び出しのログ |
| Auth Desktop OAuth | `lib/features/auth/repositories/desktop_oauth_redirect_server.dart` | ローカル http サーバのログ |
| Auth Controller | `lib/features/auth/presentation/controllers/auth_controller.dart` | UI コントローラでログを出力 |
| Auth Providers | `lib/features/auth/presentation/providers/auth_providers.dart` | 現在 compat 経由でグローバル参照 |
| Analytics Service | `lib/features/analytics/services/analytics_service.dart` | 分析ジョブのログ |
| Menu Service | `lib/features/menu/services/menu_service.dart` | メニュー CRUD ログ |
| Inventory Services | `lib/features/inventory/services/{inventory_service,material_management_service,stock_operation_service,stock_level_service?,usage_analysis_service?,order_stock_service,order_workflow_service,csv_import_service}.dart` | 在庫系サービス全般が対象 |
| Inventory Repository | `lib/features/inventory/services/order_stock_service.dart` | ※ features/inventory 側の注文在庫調整 |
| Order Services | `lib/features/order/services/{order_service,order_management_service,order_calculation_service,cart_management_service,kitchen_operation_service,kitchen_analysis_service,order_stock_service}.dart` | 注文・キッチン関連サービス |
| Order Repository | `lib/features/order/repositories/order_repository.dart` | 注文リポジトリでログ |

> 注: `inventory/services/stock_level_service.dart` と `usage_analysis_service.dart` は直接 compat import を持っていませんでした。上表は確認対象として列挙しています。

## 3. 優先度と段階

1. **Service層**: `menu_service`, `inventory_service`, `order_service` など主要サービスから着手し、ロガー DI を適用する。
2. **Repository層**: `order_repository`, `auth_repository` などインフラとの境界を扱う箇所を DI に統一。
3. **Presentation層**: コントローラ/プロバイダでのロガー要求へ移行し、UI には直接注入しない方針。
4. **テスト整備**: ロガー override サンプルを `test/support/logging/` 配下に作成。

## 4. 次のアクション

- `loggerProvider` を features 層で注入するための Riverpod プロバイダ改修。
- 各サービス/リポジトリのコンストラクタに `LoggerContract` を追加。
- `compat.dart` への依存を削除・Deprecated 化。
- `FakeLogger` の実装とユニットテスト追加。
