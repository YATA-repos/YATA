# 支払い方法「PayPay」切り替え実装計画

- **作成日**: 2025-10-09
- **担当**: TBD
- **対象リリース**: 2025年10月後半想定 (注文管理改善スプリント)
- **背景**: 店舗要望によりキャッシュレス決済の主軸がクレジットカードから「PayPay」へ移行したため、アプリ内表示と注文データの既定値を変更する。

## 1. 背景と目的

現状、`PaymentMethod` 列挙体および関連UIでは "現金"・"カード"・"その他" を提供している。現場の運用ではカード決済が廃止され、代わりに QR 決済 (PayPay) を主軸とするため、アプリの表示と保存される値を "PayPay" に差し替える必要がある。また、既存データおよび Supabase スキーマに保存されている `payment_method = 'card'` を矛盾なく移行する必要がある。

## 2. 変更スコープ

### 2.1 プレゼンテーション/UI 層
- `lib/features/shared/utils/payment_method_label.dart`: ラベル変換関数の更新 ("カード" → "PayPay").
- `OrderPaymentMethodSelector` (`lib/features/order/presentation/widgets/order_payment_method_selector.dart`): チップ表示は `PaymentMethod.values` 依存のため、列挙体更新のみで表示が変わる。ただしヘルパーテキスト等にハードコードがないか要確認。
- 注文履歴カードやダイアログ表示 (`order_history_page.dart` など) のラベルがヘルパー経由で出力されることを確認済み。個別文言があれば合わせて置換。 

### 2.2 ドメイン/サービス層
- `lib/core/constants/enums.dart`: `PaymentMethod.card` → `PaymentMethod.paypay` へリネームし、`.value` を `"paypay"` に更新。コメントも QR 決済に合わせて修正。
- `OrderDto` (`lib/features/order/dto/order_dto.dart`): JSON 変換処理で `PaymentMethod.value` を使用しているため新値に追従させる。旧 `"card"` を取得した際の後方互換処理 (旧データ救済) を追加。
- サービス層 (`cart_management_service.dart`, `order_management_service.dart`) で `paymentMethod.value` を外部送信している箇所は `.value` の変更で自動更新されるが、ログや監査用メッセージに固定文言がないかをチェック。

### 2.3 テスト/検証
- `test/features/order/presentation/pages/order_management/order_management_sections_test.dart` など `PaymentMethod.card` を参照するテストの修正。
- JSON デコード/エンコードのスナップショットがある場合は更新。`order_model.g.dart` の再生成を行うため、関連テストが影響する。

### 2.4 データベース/バックエンド
- Supabase `public.orders.payment_method` カラム (text)。現状値 `card` を `paypay` に更新するデータマイグレーションを追加。
- 参照テーブルやビュー (`analytics` スキーマ等) が `card` を前提にしていないか確認。特にエクスポート用ビューで `CASE` 文などがないか差分確認。
- 将来 `ENUM` 変換を検討するが今回は text フィールドのままとし、チェック制約がある場合 (存在未確認) は ALTER 文で候補を修正する。

## 3. 実装ステップ

1. **列挙体とラベルの更新**
   - `PaymentMethod.card` を `PaymentMethod.paypay` にリネーム (値は `"paypay"` に変更)。
   - コメント/ドキュメントを PayPay 向けに調整。
   - `paymentMethodLabel` の `switch` を更新し、`"PayPay"` を返すよう修正。

2. **移行期の互換ロジック追加**
   - `OrderDto.fromJson` 等のデシリアライズで、`json["payment_method"] == "card"` の場合は `PaymentMethod.paypay` にフォールバック。
   - 将来的に削除できるよう TODO と削除予定バージョンをコメントとして添える。

3. **関連ファイルの更新と自動生成**
   - `order_model.dart`/`.g.dart`、`cart_management_service.dart` などで `card` 参照を検索し、必要箇所のみ修正。
   - `dart run build_runner build --delete-conflicting-outputs` を実行し、シリアライズコードを再生成。

4. **テスト更新**
   - テストコードの定数・期待値を `PaymentMethod.paypay` / `"paypay"` に置換。
   - UI ゴールデン/スナップショットがある場合は差分を確認・更新。

5. **データベースマイグレーション**
   - Supabase 用に新規ファイル `supabase/migrations/20251009_payment_method_paypay.sql` (仮) を追加。
   - 既存データを更新する静的 SQL を記述 (詳細は 4章参照)。
   - チェック制約が存在する場合は修正。存在しない場合でもコメントに調査結果を残す。

6. **リリース前検証**
   - 注文作成/更新フロー、CSV エクスポート、在庫連動 (必要な場合) を Staging 環境で確認。
   - 旧アプリバージョンとの互換性 (データ表示が崩れないか) をスポットチェック。

## 4. データベース変更詳細

### 4.1 マイグレーション方針
- **対象テーブル**: `public.orders` (および `public.order_items` 等で `payment_method` を保持している場合は同様に対応する。現在のスキーマからは `orders` のみ確認できているため、他テーブルがあればマイグレーション時に追記)。
- **変更内容**:
  1. データ更新: `UPDATE public.orders SET payment_method = 'paypay' WHERE payment_method = 'card';`
  2. チェック制約/ドメイン更新 (存在する場合のみ):
     ```sql
     ALTER TABLE public.orders
       DROP CONSTRAINT IF EXISTS orders_payment_method_check,
       ADD CONSTRAINT orders_payment_method_check
         CHECK (payment_method IN ('cash', 'paypay', 'other'));
     ```
  3. 監査ログ・トリガーがある場合は `card` → `paypay` の変換を追加。
- **ダウンマイグレーション**: 逆変換 (`paypay` → `card`) を記述し、過去バージョンへのロールバックを可能にする。

### 4.2 適用手順
1. ローカルでマイグレーション SQL を適用し、`payment_method` 値のユニーク一覧を確認 (`SELECT DISTINCT payment_method FROM public.orders;`)。
2. Staging Supabase でマイグレーション実行 → アプリ最新ビルドで確認。
3. 本番適用は営業時間外に実施し、所要時間は即時 (単純 UPDATE のため)。
4. 実行ログと結果 (`row_count`) を Notion/Runbook へ残す。

## 5. テスト計画

| 領域 | テスト内容 | 実施方法 |
|------|-------------|-----------|
| 単体 | `paymentMethodLabel`、`OrderDto` のデコード互換性 | `dart test` target を限定実行 |
| ウィジェット | `OrderPaymentMethodSelector` の表示文言と選択状態 | 既存ウィジェットテストを更新、必要ならゴールデン追加 |
| E2E/結合 | 注文登録フローで "PayPay" を選択し Supabase へ `paypay` が保存されるか | Staging 実機テスト |
| データ移行 | 既存レコードが UPDATE 後 "PayPay" 表記になるか | SQL でサンプリング確認 |

## 6. ロールアウトとリスク

- **ロールアウト**: マイグレーション → バックエンド/API デプロイ (必要に応じ) → アプリリリースの順に段階的に実施。互換ロジックで旧アプリでも `card` を `PayPay` と表示できるため、リリース順は柔軟。
- **リスク/懸念点**:
  - 旧データが `card` のまま残存 → マイグレーション後も旧バージョンアプリが送信する場合に備え、アプリ側デコードで `card` を受け入れるフォールバックを一定期間維持。
  - 連携システム (外部 CSV、会計連携) が `card` を前提としている可能性 → ステークホルダーに通知し、必要であればマッピングテーブルを提供。
  - 受け入れテスト不足 → Staging で複数注文ケース (現金/PayPay/その他) を作成し、CSV 出力やダッシュボード表示を確認。

## 7. 作業項目・目安工数

| タスク | 担当 | 見積 |
|--------|------|------|
| コード修正 & ビルドランナー再生成 | フロントエンド担当 | 0.5 日 |
| テスト更新と実行 | フロントエンド担当 | 0.5 日 |
| Supabase マイグレーション作成・検証 | バックエンド担当 | 0.5 日 |
| Staging 検証 & QA | QA | 0.5 日 |

## 8. フォローアップ

- 一定期間 (2 週間目安) 後に `OrderDto` の `card` フォールバックを削除するチケットを作成。
- PayPay 以外の他キャッシュレス手段追加のニーズを探索し、将来的に汎用的な設定化 (店舗ごとに支払い方法を Supabase で管理) する構想を整理する。
