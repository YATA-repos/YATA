# 注文番号の生成タイミング調査

## 概要
- 調査対象: 注文番号 (`order_number`) がいつ、どの処理で採番されるか。
- 結論: カートを正式な注文に確定する際に、`OrderManagementService.checkoutCart` が `OrderRepository.generateNextOrderNumber` を呼び出し、`<YYYYMMDDThhmmss+0900>-<Base62 乱数11桁>` 形式の識別子を発番している。

## 採番フロー
1. `CartManagementService` で作成される下書き注文（カート）は `order_number` が `null` の状態で保存される。
2. ユーザーがチェックアウトを実行すると、`OrderManagementService.checkoutCart` が以下を順序通りに実行する。
   - 入力検証・在庫検証。
   - 在庫消費処理（`OrderStockService.consumeMaterialsForOrder`）。
   - 採番処理: `final String orderNumber = await _orderRepository.generateNextOrderNumber();`
   - 注文更新: `order_number` を含む複数フィールドを `updateById` で更新し、`is_cart` を `false` に変更。
   - 金額再計算と後続処理。
3. これにより、正式注文のみが `order_number` を持つ状態となる。

参照: `lib/features/order/services/order_management_service.dart` L80-L140 付近。

## 採番ロジックの詳細 (`OrderRepository.generateNextOrderNumber`)
- 実装場所: `lib/features/order/repositories/order_repository.dart` L250 付近。
- ロジック概要:
  1. `OrderIdentifierGenerator`（`lib/shared/utils/order_identifier_generator.dart`）を利用して、JST(UTC+9) のタイムスタンプ文字列 `YYYYMMDDThhmmss+0900` と Base62 乱数 11 桁を生成。
  2. 合成した文字列（例: `20250930T154512+0900-ABC123xyz90`）が既存レコードと衝突していないか `_delegate.find` で確認し、衝突時は最大 5 回まで再生成。
  3. 全ての試行で衝突した場合は例外をスローし、ログへ詳細を出力。

```text
例) 2025年9月30日 15:45:12 (JST) に生成 → "20250930T154512+0900-ABC123xyz90"
```

## タイミングと前提条件
- 採番は**チェックアウト完了直前**（在庫消費後、金額再計算前）に実行される。
- カート（下書き）状態では `order_number` は空のまま。
- 採番結果は `updateById` のペイロード内で保存されるため、DB への書き込みが成功した時点で注文番号が確定する。

- Base62 乱数は `Random.secure()` を利用しており、理論上の衝突確率は低いがゼロではないため、Supabase 側でも `order_number` の一意インデックスを付与して衝突検知を行う想定。
- 衝突が検出された場合は自動で再試行し、最大試行回数を超えると例外が発生する。実運用ではログ監視で再生成の頻度を確認すること。
- `generateNextOrderNumber` は `OrderRepository` のみが提供し、現在のコードベースでは `OrderManagementService.checkoutCart` 以外から呼び出されていない。

## まとめ
- 採番のタイミング: カートから正式注文への変換時。
- 採番の責務: `OrderRepository.generateNextOrderNumber` が JST タイムスタンプ + Base62 乱数の複合フォーマットを生成。
- 採番後の保存: `OrderManagementService.checkoutCart` の `updateById` 呼び出しで `order_number` を永続化。
