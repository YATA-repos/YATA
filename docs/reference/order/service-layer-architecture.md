# Order Service Layer Architecture

最終更新日: 2025-10-08

## 概要
Order 機能のサービス層は、プレゼンテーション層とリポジトリ層の仲介を担う 3 つの中心サービスで構成されています。

```
UI (Controllers / Widgets)
        │
        ▼
OrderManagementService  ──┬─ Checkout / History / Status
        │                  ├─ Realtime (orders, order_items)
        │                  └─ CartManagementService 協調
        ▼
CartManagementService  ────┬─ カートCRUD / メニュー同期
        │                  └─ OrderInventoryIntegrationService を通じた在庫照会
        ▼
OrderInventoryIntegrationService ── 材料在庫確認・消費・復元
```

## 各サービスの責務
| サービス名 | 主な責務 | 主要依存関係 |
|------------|----------|---------------|
| `OrderManagementService` | 注文チェックアウト、履歴取得、ステータス更新、リアルタイム監視（`orders`/`order_items`） | Order / OrderItem / Menu リポジトリ、`OrderCalculationService`, `OrderInventoryIntegrationService`, `CartManagementService`, `RealtimeManager`
| `CartManagementService` | カートの生成・更新、メニュー項目キャッシュ、カート内バリデーション | Order / OrderItem / Menu リポジトリ、`OrderCalculationService`, `OrderInventoryIntegrationService`
| `OrderInventoryIntegrationService` | メニュー在庫検証、材料消費、キャンセル時の材料復元 | Material / Recipe リポジトリ

### リアルタイム統合
- `OrderManagementService` が `RealtimeServiceContractMixin` を実装し、`orders` と `order_items` テーブルを直接監視します。
- UI 層からは `OrderManagementService.enableRealtimeFeatures()` を呼び出すことで監視を開始できます。`OrderService` ファサードは削除済みです。
- Subscription ID は `order_management_service` + ユーザー ID で生成され、`RealtimeManager` の健全性チェックも `OrderManagementService` が提供します。

### 在庫連携
- 旧 `OrderStockService` は `OrderInventoryIntegrationService` にリネームされ、在庫関連のログタグ・メトリクスも新名称に更新されています。
- カート確定時 (`checkoutCart`) は、在庫検証 → 材料消費を `OrderInventoryIntegrationService` に一括委譲します。
- 注文キャンセル時には同サービスが材料在庫を復元し、Inventory ドメインとの境界を一本化しました。

## プロバイダ構成 (Riverpod)
| Provider | 戻り値 | メモ |
|----------|--------|------|
| `orderManagementServiceProvider` | `OrderManagementService` | `RealtimeManager` と `Ref` を注入し、リアルタイム機能が有効化可能。 |
| `cartManagementServiceProvider` | `CartManagementService` | `orderInventoryIntegrationServiceProvider` を通じて在庫連携する。 |
| `orderInventoryIntegrationServiceProvider` | `OrderInventoryIntegrationService` | Material / Recipe リポジトリを使用。旧 `orderStockServiceProvider` は廃止。 |

## シーケンス: checkoutCart
1. `OrderManagementService.checkoutCart`
   1. バリデーション → カート取得
   2. 明細リスト取得 (`OrderItemRepository`)
   3. 在庫検証 (`OrderInventoryIntegrationService.validateCartStock`)
   4. 材料消費 (`OrderInventoryIntegrationService.consumeMaterialsForOrder`)
   5. 注文更新と合計計算 (`OrderCalculationService`)
   6. 新カートの初期化 (`CartManagementService`)
2. UI は成功時に新カート ID と注文情報を受け取り再描画する。

## 変更履歴
- 2025-10-08: OrderService を廃止し、リアルタイム機能を OrderManagementService へ統合。`OrderInventoryIntegrationService` を導入。
