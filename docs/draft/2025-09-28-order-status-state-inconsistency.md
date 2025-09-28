# 注文ステータス表示の現状調査メモ

- 日付: 2025-09-28
- 対象トピック: Order History / Order Status の表示ステータス不整合
- 作成者: GitHub Copilot

## 1. 背景

注文履歴画面では `OrderStatus` の表示名をそのまま利用しており、注文状況画面ではセクション名をハードコードしているため、
"準備中 / 確認済み / 完了" と "準備中 / 提供済み" という異なる用語が同時に利用されている。加えて、バックエンド側の遷移設計が
`confirmed → preparing → completed` を想定しているのに対し、前段の UI では `confirmed` を扱っていない。現行実装がどのように
ステータスを扱っているかを整理する。

## 2. 調査対象コード

- ステータス定義: `lib/core/constants/enums.dart`
- 注文履歴 UI / ロジック:
  - `lib/features/order/presentation/pages/order_history_page.dart`
  - `lib/features/order/presentation/controllers/order_history_controller.dart`
- 注文状況 UI / ロジック:
  - `lib/features/order/presentation/pages/order_status_page.dart`
  - `lib/features/order/presentation/controllers/order_status_controller.dart`
- サービス層のステータス操作:
  - `lib/features/order/services/order_management_service.dart`
  - `lib/features/order/services/order_service.dart`
  - `lib/features/order/services/kitchen_operation_service.dart`

## 3. ステータス定義の整理

`lib/core/constants/enums.dart` の `OrderStatus` 定義 (L204-L293) を基に、現状参照されているステータスを整理した。

| Enum 値 | `value` | `displayName` | 備考 |
| --- | --- | --- | --- |
| `pending` | `"pending"` | 待機中 | UI からの直接参照無し (今後の導線検討)。 |
| `confirmed` | `"confirmed"` | 確認済み | `checkoutCart` 完了直後の状態。注文履歴には出るが注文状況には出ない。 |
| `preparing` | `"preparing"` | 準備中 | カート状態およびキッチン進行中の注文を表す。注文状況の "準備中" セクションで使用。 |
| `ready` | `"ready"` | 準備完了 | 現状 UI では未使用。キッチン関連サービスで `readyAt` を更新するのみ。 |
| `delivered` | `"delivered"` | 配達済み | enum には存在するがフロントから参照されていない。 |
| `completed` | `"completed"` | 完了 | 注文履歴では「完了」。注文状況では「提供済み」として表示。 |
| `cancelled` | `"canceled"` | キャンセル | 注文履歴のフィルタ対象。 |
| `refunded` | `"refunded"` | 返金済み | 注文履歴のフィルタ対象。 |

## 4. 画面ごとの挙動

### 4.1 注文履歴 (`order_history_page.dart`)

- `OrderHistoryViewData.status` の値をそのまま `_OrderStatusBadge` に渡し、`OrderStatus.displayName` を表示。
- ステータスフィルタ (`OrderHistoryState.selectedStatusFilter`) は `completed / cancelled / refunded` のみを対象としており、
  `confirmed` や `preparing` は「全て」扱い。
- その結果、履歴一覧には「準備中」「確認済み」「完了」など enum の表示名が混在する。

### 4.2 注文状況 (`order_status_page.dart`)

- UI セクション名をハードコードで `"準備中"` / `"提供済み"` と定義。
- コントローラ (`OrderStatusController.loadOrders`) は `OrderService.getOrdersByStatuses` に `preparing` と `completed` のみを指定。
- 完了ボタン (`提供済みにする`) は `updateOrderStatus(order.id, OrderStatus.completed, …)` を呼び出し、トーストも "提供済み" を使用。
- `OrderStatus.completed.displayName` が「完了」であるため、履歴画面とは用語が一致していない。

## 5. サービス層のステータス遷移

- `OrderManagementService.checkoutCart` (`order_management_service.dart` L108-L167):
  - バリデーション後、注文の `status` を `OrderStatus.confirmed` に更新。
  - そのまま `OrderHistoryController` では「確認済み」と表示されるが、`OrderStatusController` の取得対象外。
- `OrderManagementService.updateOrderStatus` (L362-L413):
  - `preparing` と `completed` への更新のみサポート。
  - `completed` へ遷移する際に `completed_at` を更新。`delivered` 等は未使用。
- `KitchenOperationService` 系:
  - アクティブ注文は `OrderStatus.preparing` のみを対象としたユースケースが中心。
  - `deliverOrder` で `status = completed` に設定しているが、UI とは紐付いていない (現時点では呼び出し元不明)。

## 6. 不整合ポイント

1. **翻訳の揺らぎ**: `OrderStatus.completed` は `displayName = "完了"` だが、注文状況ページでは「提供済み」と表記している。
2. **ステータス粒度の差異**: 履歴は全ステータスを扱う一方、状況ページは `preparing` / `completed` の二段階に縮約している。
3. **`confirmed` の孤立**: Checkout 直後の注文は `confirmed` のままで、状況ページに表示されない。`preparing` へ遷移させる導線が UI / サービスともに未設計。
4. **未使用ステータスの存在**: `ready` や `delivered` の enum が定義されているが、前段の画面では利用されておらず、概念が宙に浮いている。

## 7. 影響とリスク

- オペレーション上、「提供済み」と「完了」の混在によりスタッフ間での用語齟齬が発生する恐れ。
- `confirmed` 状態の注文が状況画面に現れないため、会計直後の注文がキッチンボードに表示されず見落とすリスクがある。
- 今後 `delivered` などを導入する場合、既存 UI との用語整合を取らないとさらなる混乱を招く。

## 8. 今後の検討案

- `OrderStatus` の日本語表記を単一ソースで管理するユーティリティ化、もしくは UI 側のハードコードを排除。
- Checkout 後に `confirmed → preparing` へ遷移させるトリガーを追加し、キッチン画面と履歴の表示整合を図る。
- `completed` と `delivered` の役割を定義し直し、必要であれば注文状況画面のセクション構成を再検討 (例: 確認待ち / 調理中 / 提供準備完了 / 提供済み)。
- 未使用ステータス (`ready`, `delivered`) の扱い方針を決め、不要であれば enum から除外するか 🚧 の注記を追加する。
