# 注文番号表示コード刷新 実装状況レビュー（2025-09-30 調査）

## 概要
- 調査対象: `docs/plan/2025-09-30-order-display-code-plan.md` で定義されたアプリ側変更。
- 調査日時: 2025-09-30
- 調査者: GitHub Copilot
- 結論: Flutter アプリ側の主要変更はすべて実装済み。Supabase 側の制約・移行スクリプトはリポジトリ内で確認できず、別途確認が必要。

## サマリー

| 項目 | 期待される変更内容 | 調査結果 | 備考 |
| --- | --- | --- | --- |
| 5.1 ユーティリティ | Base36 表示コード生成 API を追加し、ガードと CSPRNG を使用 | ✅ 実装済み | `lib/shared/utils/order_identifier_generator.dart` に `generateDisplayCode` / `generateOrderNumber` を実装。テスト (`test/shared/utils/order_identifier_generator_test.dart`) も Base36 想定。 |
| 5.2 サービス/リポジトリ | カート生成時のコード付与、`is_cart` ベースの取得、チェックアウト時のコード維持、リトライ付き採番 | ✅ 実装済み | - `CartManagementService` が `generateNextOrderNumber` を用意し、欠損時は補填。<br>- `OrderRepository.findActiveDraftByUser` は `order_number IS NULL` ではなく `is_cart` フィールドを利用。<br>- `OrderManagementService.checkoutCart` はコード未設定時のみフォールバック生成。<br>- `OrderRepository.generateNextOrderNumber` は Base36/4文字で最大5回リトライ。対応テストあり。 |
| 5.3 UI 層 | 「受付コード」表示および短いコード向けのラベル・ヒント調整 | ✅ 実装済み | `order_history_page.dart` / `order_status_page.dart` / `order_management_page.dart` で「受付コード」ラベルと検索ヒントを確認。空の場合のフォールバック文言も更新済み。 |
| 5.4 テスト更新 | 新フォーマットに合わせたユニット/サービス層テスト | ✅ 実装済み | 生成ユーティリティ・リポジトリ・サービスに対して Base36 コード前提のテストを追加/更新済み。 |
| 5.5 データ移行 | 既存カートへのコード補填（アプリ側の冪等処理）、Supabase でのバックフィル | ⚠️ 一部未確認 | アプリは `_ensureCartHasDisplayCode` で冪等補填を実装。Supabase 側 SQL やマイグレーションスクリプトは未確認。 |
| 5.6 ドキュメント更新 | 新フォーマット仕様を反映 | ✅ 実装済み | `docs/draft/order_number_generation.md` などに新仕様を記述。ただし運用手順書等の更新は他リポジトリ管理の可能性あり。 |

## 詳細ハイライト

### ユーティリティ層
- `OrderIdentifierGenerator.generateDisplayCode` が Base36 (0-9A-Z) の CSPRNG 乱数を生成し、長さガードを実装。
- `generateOrderNumber` は表示コード生成のラッパーとして 4 文字コードを返す。
- ユニットテストでは `MockRandom` を利用し、出力が正規表現 `^[0-9A-Z]{n}$` に一致することを検証。

### サービス層
- `CartManagementService.getOrCreateActiveCart` と `getActiveCart` は `_ensureCartHasDisplayCode` を通じ、既存カートのコード欠損時も補填。衝突時は最大5回リトライし、`RepositoryException` の UNIQUE 違反を検出して再試行。
- `OrderManagementService.checkoutCart` はカートの `orderNumber` を引き継ぎ、未設定時のみフォールバック生成。警告ログを出力してトラブルシュート可能に。

### リポジトリ層
- `OrderRepository.findActiveDraftByUser` は `is_cart = true` 基準でカートを抽出し、`order_number` の null 判定を使用しない。
- `OrderRepository.generateNextOrderNumber` はユニーク性確認を行いつつ Base36 コードを生成。衝突ログとリトライ実装あり。

### UI 層
- 検索プレースホルダーとカード表示文言が「受付コード」に統一され、短いコード表示を前提にした UI へ更新済み。
- `order_management_page.dart` ではコードが無い場合に「受付コード未設定」表示、既存コードはそのまま表示する分岐あり。

### テスト
- 生成ユーティリティ、リポジトリ、サービス (`order_management_service_test.dart`, `cart_management_service_test.dart`) にて新フォーマットと振る舞いを検証。
- 既存コード保持やコード欠損時のフォールバックなど、計画書で想定されたユースケースをカバー。

### ドキュメント
- `docs/draft/order_number_generation.md` に新フローと仕様を整理済み。計画書との整合性あり。
- 運用手順書や Supabase マイグレーション手順はこのリポジトリでは未掲示。必要に応じて他パス/別レポジトリを確認。

## 未確認事項 / フォローアップ推奨
1. **Supabase 側の UNIQUE 制約およびバックフィル SQL**: リポジトリ内に該当スクリプトが見当たらないため、Supabase プロジェクトまたは IaC リポジトリ側の更新状況を確認する。
2. **ロールバック手順の整備**: アプリ側ログには衝突時の警告があるものの、運用手順書（例: `docs/intent` 配下）にロールバック記述があるか確認が必要。
3. **旧フォーマット混在時の UI 表示**: 実装では未設定のみをハンドリング。旧フォーマット（長い文字列）の表示検証は実機テストで確認推奨。

## 結論
- Flutter アプリ側の実装は計画書に沿って完了している。
- バックエンド（Supabase）と運用ドキュメントの一部はリポジトリ外の可能性があり、関係チームとの整合確認を推奨。
