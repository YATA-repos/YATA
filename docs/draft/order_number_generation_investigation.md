# 注文番号採番ロジック調査メモ

## 調査目的
- 現状の注文番号 (`order_number`) がどこで生成・採番されているかを把握し、採番タイミングと生成方式を整理する。

## 採番処理の所在と内容
- 採番ロジックは `lib/features/order/repositories/order_repository.dart:244` の `OrderRepository.generateNextOrderNumber()` に実装されている。
- 主な処理フロー:
  1. `DateTime.now()` を取得し、`yyyyMMdd` 形式のプレフィックス（例: `20241002`）を生成。
  2. 当日の開始 (`00:00:00.000`) と終了 (`23:59:59.999`) で注文検索用の日時範囲を組み立て。
  3. Supabase へのクエリパラメータとして `ordered_at` の範囲フィルタを作成し、当日分の注文を全件取得。
  4. 取得件数に 1 を加算した値を連番として利用し、ゼロ埋め 3 桁（例: `001`）に整形。
  5. `"<日付プレフィックス>-<連番>"` 形式（例: `20241002-003`）で文字列を返却。
- 連番は「当日登録済みの件数 + 1」で決まるため、同時アクセス時は Supabase 側の一意制約等がない限り競合する可能性がある。

## 採番タイミングと利用箇所
- 採番の呼び出し元は `lib/features/order/services/order_management_service.dart:106` の `OrderManagementService.checkoutCart()`。
  - カート確定処理の中で `_orderRepository.generateNextOrderNumber()` を呼び出し、取得した値を `orderNumber` 変数に保持。
  - `updateById` 実行時に `order_number` フィールドへ設定し、`ordered_at` の確定やステータス更新とまとめて保存している。
  - 保存後に金額再計算 (`_orderCalculationService.calculateOrderTotal`) を行い、最終的な注文オブジェクトを返却。
- 他のサービスやリポジトリから `generateNextOrderNumber()` を呼ぶ箇所は現状確認できなかった。

## カート状態との関係
- `OrderRepository.findActiveDraftByUser()` (`lib/features/order/repositories/order_repository.dart:15`) では `order_number IS NULL` を検索条件に含めており、注文番号が未採番であることをカート判定の一要素として利用している。
- そのため、チェックアウト完了前は `order_number` が `NULL` のまま保持され、採番確定タイミングはチェックアウト処理一択となっている。

## 追加メモ
- 連番計算がアプリ側のカウント依存であるため、同一日内の高頻度注文や並列処理時に重複が発生し得る。必要に応じて Supabase 側の一意性制約やトランザクション制御の有無を確認すると良い。
- タイムゾーンは `DateTime.now()` に依存しており、店舗ロケーションのタイムゾーン設定が未考慮の場合は日付境界がずれる可能性がある。
