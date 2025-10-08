# 注文会計フロー再設計 実装計画（2025-09-28）

本計画は `docs/draft/order_bugfix_3_investigation.md` の提案（セクション5）をベースに、Order-Bugfix-3 を解決するための具体的な実行ステップを定義する。

- 対象タスク: Order-Bugfix-3
- 関連タスク: Order-Bugfix-1（注文番号採番）※ステータス更新時に副作用があるため連携必須
- 対象コード: `lib/features/order/presentation/pages/order_management_page.dart` / `controllers/order_management_controller.dart` / `services/order/order_management_service.dart` / `services/cart/cart_management_service.dart` / `repositories/order_repository.dart`

## 目的

- 会計操作で正式注文が確定し、履歴・在庫・分析に正しいデータが流れるようにする。
- 会計完了後に UI のカートと選択状態がリセットされ、次の注文が空の状態で開始できるようにする。
- フローの再現テストや手動チェックリストを用意し、退行を防止する。

## スコープ

### 含む

1. UI からバックエンドの `checkoutCart` を呼び出す導線追加と例外ハンドリング。
2. `OrderManagementService.checkoutCart` の注文確定処理（ステータス遷移・注文番号反映・新規カート生成/取得）再設計。
3. カート・UI 状態を会計完了後に初期化する仕組み（`autoDispose` 化や `refresh()` パターン）導入。
4. 「会計 → 履歴表示 → 新規注文」の E2E シナリオ検証手順・テスト整備。

### 含まない

- 支払い方法 UI 追加 (Order-Feature-1) などの機能拡張。
- 注文番号採番ロジックそのものの実装（Order-Bugfix-1 側で実施想定）。
- 既存のリアルタイム購読ロジックの大幅改修。

## フェーズ構成

### Phase 1: UI からのチェックアウト導線整備

- [ ] `OrderManagementController` に `checkout()` メソッドを追加し、`OrderManagementService.checkoutCart` を呼び出す。
- [ ] `order_management_page.dart` の会計ボタンを `controller.checkout()` に差し替え、処理中インジケーターとエラートーストを実装。
- [ ] 成功時に履歴ページへ遷移し、失敗時は現在のページに留まる UX を定義。

### Phase 2: 会計済み注文のステータス設計

- [ ] `OrderManagementService.checkoutCart` で `generateNextOrderNumber()` の返却値を取得し、`order_number` を更新。
- [ ] チェックアウト完了時のステータスを `OrderStatus.confirmed`（または `completed`）へ変更し、`ordered_at` を確定値で保存。
- [ ] 完了後に `CartManagementService.getOrCreateActiveCart` で新規カートを生成し、その ID を UI 側へ返却できるよう拡張。
- [ ] `OrderRepository.findActiveDraftByUser()` の条件を見直し、`preparing` かつ `total_amount = 0` 等の判定を追加する案を検証。

### Phase 3: 状態管理のライフサイクル改善

- [ ] `orderManagementControllerProvider` を `autoDispose` 化、または `GoRouter` 遷移戻り時に `refresh()` するガードを実装。
- [ ] 会計成功後に `state` を `OrderManagementState.initial()` ベースでリセットし、新しいカート情報を再取得。
- [ ] `loadInitialData()` を再入可能にし、`cartId` 不整合時のハードリセット動作を追加。

### Phase 4: 検証とテスト

- [ ] 会計成功シナリオ（正常系）: カートにアイテム追加 → 会計 → 履歴確認 → 新規注文開始 の手順をドキュメント化。
- [ ] 会計失敗シナリオ（在庫不足/バリデーション失敗）で UI がエラーを表示し、カート状態が保持されることを確認。
- [ ] `OrderManagementController` のユニットテストを追加し、`checkout()` が成功/失敗時に状態を正しく更新することを検証。
- [ ] `OrderManagementService.checkoutCart` の統合テスト（モックリポジトリ使用）でステータス遷移と新規カート生成を確認。

## 受け入れ条件（Acceptance Criteria）

- 会計ボタン押下時にバックエンドのチェックアウトが実行され、成功後は新規注文として空のカート画面に戻れる。
- 注文履歴で会計した注文が `confirmed/completed` ステータスで表示され、注文番号が付与されている。
- 連続注文時に前回のカート内容が残留しない。
- 主要パス（成功/在庫不足）で UI がエラーハンドリングを行い、操作が継続可能である。
- 新旧コードに対する `flutter analyze` / `flutter test` がグリーンである。

## タスク分解チェックリスト

- [ ] UI ボタンのイベント差し替えとローディング状態実装
- [ ] `OrderManagementController.checkout()` の追加と状態遷移
- [ ] `OrderManagementService` へのパラメータ・戻り値拡張
- [ ] 注文ステータス更新と注文番号反映
- [ ] 新規カート生成（`CartManagementService` 改修）
- [ ] Provider ライフサイクル調整（`autoDispose` or `refresh`）
- [ ] テスト & 手動検証手順ドキュメント更新

## リスクと緩和策

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| 既存データが `preparing` のまま残り、新条件でカート取得できなくなる | 既存ユーザーの注文が参照できなくなる | マイグレーションスクリプトで過去の注文を `confirmed` に更新する / フォールバック条件を用意 |
| `autoDispose` 化によりリアルタイム購読が頻繁に再起動する | パフォーマンス劣化 | `keepAlive()` で必要なときのみ維持し、不要時は破棄する設計を検討 |
| チェックアウト失敗時の UI 劣化（多重押下・二重送信） | ダブルチャージのリスク | ボタンを処理中は無効化し、結果後に再度有効化 |
| 依存タスク（Order-Bugfix-1）が未完 | 注文番号が空のまま | フラグで `order_number` をオプション扱いとし、利用場面でフォールバック表示を保持 |

## 依存関係

- Order-Bugfix-1: 注文番号採番が完了していることが望ましい。
- Supabase スキーマ変更が必要な場合（ステータス列、既存データ移行）はインフラチームと調整する。

## 検証計画

1. 単体テスト (`flutter test`) を追加・更新し、CI で自動実行。
2. 手動チェックリストを `docs/reference/order-checkout-checklist.md`（新規）として整備予定。
3. ステージング環境で POS ロールを使った手動検証を実施し、ログ監視でエラーが無いことを確認。

## 次のアクション

- [ ] 本計画のレビューを実施し、承認後に Order-Bugfix-3 実装ブランチを作成。
- [ ] 依存タスク（Order-Bugfix-1）の進捗を確認。
- [ ] 実装開始前に `order_management_controller` の現状テストカバレッジを計測。
