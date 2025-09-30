# 注文番号採番ロジック調査メモ

## 調査目的
- 現状の注文番号 (`order_number`) がどこで生成・採番されているかを把握し、採番タイミングと生成方式を整理する。

## 採番処理の所在と内容
- 採番ロジックは `lib/features/order/repositories/order_repository.dart` の `OrderRepository.generateNextOrderNumber()` に実装されている。
- 主な処理フロー:
  1. `OrderIdentifierGenerator` が `DateTime.now()` を JST(UTC+9) に正規化し、`YYYYMMDDThhmmss+0900` 形式のタイムスタンプ文字列を生成。
  2. 同ジェネレーターが `Random.secure()` で Base62 アルファベット（0-9, A-Z, a-z）から 11 文字の乱数スラッグを作成。
  3. `"<タイムスタンプ>-<スラッグ>"` を候補値として合成し、Supabase に `order_number = 候補値` の照会を発行。衝突した場合は最大 5 回まで再生成。
  4. ユニークな値が得られた時点で返却。最大試行回数を超えた場合は例外を送出してログに残す。

## 採番タイミングと利用箇所
- 採番の呼び出し元は `lib/features/order/services/order_management_service.dart` の `OrderManagementService.checkoutCart()`。
  - カート確定処理の中で `_orderRepository.generateNextOrderNumber()` を呼び出し、取得した値を `orderNumber` 変数に保持。
  - `updateById` 実行時に `order_number` フィールドへ設定し、`ordered_at` の確定やステータス更新とまとめて保存している。
  - 保存後に金額再計算 (`_orderCalculationService.calculateOrderTotal`) を行い、最終的な注文オブジェクトを返却。
- 他のサービスやリポジトリから `generateNextOrderNumber()` を呼ぶ箇所は現状確認できなかった。

## カート状態との関係
- `OrderRepository.findActiveDraftByUser()` (`lib/features/order/repositories/order_repository.dart:15`) では `order_number IS NULL` を検索条件に含めており、注文番号が未採番であることをカート判定の一要素として利用している。
- そのため、チェックアウト完了前は `order_number` が `NULL` のまま保持され、採番確定タイミングはチェックアウト処理一択となっている。

## 追加メモ
- 乱数スラッグは暗号論的擬似乱数 `Random.secure()` を利用しているため、理論上の衝突確率は非常に低いが、Supabase 側でもユニークインデックスを設定する前提で運用する。
- タイムゾーンは常に JST 固定で出力されるため、端末のローカルタイムゾーンに依存しない。旧仕様で問題だった日付境界の揺らぎが解消された。
