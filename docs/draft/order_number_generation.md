# 注文番号（受付コード）の生成・付与フロー更新メモ

## 概要
- 対象: 注文番号 (`order_number`)＝受付コードの生成タイミングと責務。
- 現状: カート生成直後に 4 文字の Base36 コード（`^[A-Z0-9]{4}$`）を採番し、正式注文まで同一コードを維持する。

## 採番フロー
1. `CartManagementService.getOrCreateActiveCart`
  - アクティブなカートを取得した際、`order_number` が空なら `_orderRepository.generateNextOrderNumber()` を呼び出し再帰的に補填する。
  - 新規作成時も先にコードを生成して `Order` モデルに設定したうえで `create` を実行。作成後に再確認し、空なら再採番を試みる。
2. `OrderManagementService.checkoutCart`
  - カートの `order_number` をそのまま正式注文へ引き継ぐ。
  - 例外的にコードが未設定だった場合のみフォールバック生成を行い、警告ログを残す。

この結果、カート段階から UI や検索で利用可能な表示コードが確保され、チェックアウト時の再採番は原則発生しない。

## 採番ロジックの詳細 (`OrderRepository.generateNextOrderNumber`)
- 実装: `lib/features/order/repositories/order_repository.dart`
- 処理内容:
  1. `OrderIdentifierGenerator.generateOrderNumber()` が Base36 アルファベット（`0-9A-Z`）の 4 文字コードを生成。内部では CSPRNG (`Random.secure()`) を利用した `generateDisplayCode` を呼び出す。
  2. Supabase 上で同一コードが存在しないか `order_number = candidate` 条件で確認。衝突した場合は最大 5 回まで再試行。
  3. 全試行で衝突した際は例外を投げ、ログに失敗内容を記録。

## タイミングと前提条件
- 採番はカート作成／取得タイミングで行われ、以降の処理では同一コードを使用する。
- `CartManagementService` はコード未割り当ての既存カートを検出した場合に `updateById` で即時補填する。重複エラー（UNIQUE 制約違反）が発生した際は自動で再採番。
- チェックアウト処理では既存コードを維持しつつ、金額計算や在庫処理を実施。
- Supabase 側で `order_number` に UNIQUE 制約（NULL 許容）を設定していることを前提とし、衝突時はアプリ側のリトライで最終的にユニークなコードが確保される。

## まとめ
- 採番タイミング: カート生成／取得時に即時採番、チェックアウト時は再利用。
- フォーマット: `^[A-Z0-9]{4}$`（Base36／4文字、CSPRNG 由来）。
- 責務: 採番ユーティリティは `OrderIdentifierGenerator`、ユニーク確認と再試行は `OrderRepository`、補填のオーケストレーションは `CartManagementService` が担う。
- 運用メモ: UI・検索での表示名称は「受付コード」。旧フォーマットの注文も混在する可能性があるため、検索や表示ロジックは新旧どちらの形式も許容する。
