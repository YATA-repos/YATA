# 注文管理パフォーマンス改善 実装計画

## 概要

`docs/draft/order/2025-10-02-order-management-performance-investigation.md` の調査結果に基づき、注文管理画面 (`OrderManagementPage`) の体感速度と応答性を引き上げるための実装計画をまとめる。現行実装ではメニュー一覧・カート連携・注文メモ更新の各所で無駄な再描画と再計算が発生しており、以下の改善で UI スレッド負荷を大幅に削減することが狙いである。

## 改善対象と期待効果

- **メニュー一覧の仮想化描画**: `SingleChildScrollView` + `Wrap` を廃し、ビルド件数を必要最小限にすることで初期描画およびスクロール時のフレーム落ちを抑える。
- **カート参照の高速化**: カート情報の逐次探索 (O(M×N)) を解消し、各メニューカードのビルド負荷を O(1) にする。
- **フィルタ済みメニューのソート最適化**: 状態更新時に一度だけソートを実施し、リビルド毎の全件ソートを排除する。
- **注文メモ更新のデバウンス / 局所更新**: 1 文字入力ごとに全画面リビルドされる問題を解消し、入力応答を改善する。
- **カート更新後の差分反映** (拡張): 毎操作での `_refreshCart` 全再取得を避け、差分反映と非同期再同期に分離して操作遅延を軽減する。

## フェーズ構成

1. **Phase 1: UI レイヤ即効改善**
   - メニュー一覧の仮想化描画
   - カート参照の高速化
2. **Phase 2: State 管理最適化**
   - フィルタ済みメニューのソート最適化
   - 注文メモ更新のデバウンス / 局所更新
3. **Phase 3: データ取得フロー改善 (任意)**
   - カート更新後の差分反映と再同期設計

各フェーズ完了ごとにベンチマーク (フレームタイム計測 / DevTools `Performance` トレース) を取得し、改善効果を確認する。

## 詳細タスク

### A. メニュー一覧の仮想化描画 (Phase 1)

- **対象ファイル**: `lib/features/order/presentation/pages/order_management_page.dart`
- **主な変更ポイント**:
  1. `RawScrollbar` 直下の `SingleChildScrollView` + `Wrap` (323行付近) を `GridView.builder` へ置き換え、`SliverGridDelegateWithFixedCrossAxisCount` でカラム数を制御する。
  2. `LayoutBuilder` で算出している `crossAxisCount` / `itemWidth` を `GridView.builder` 用に再構成し、`childAspectRatio` を明示する。
  3. 各アイテムに `ValueKey(item.id)` を付与し、スクロール中のリビルドを安定させる。
  4. スクロールコントローラ (`_scrollController`) を `GridView.builder` に渡し、スクロール位置の維持を確認する。
  5. UI スモークテスト / Golden テスト (存在する場合) を更新する。
- **完了条件**:
  - メニュー件数 500 件のモックデータで 1 フレームあたりのビルド数が 10× 以下に減少することを DevTools で確認。
  - スクロール応答が 60fps 近傍で安定すること。

### B. カート参照の高速化 (Phase 1)

- **対象ファイル**: `lib/features/order/presentation/controllers/order_management_controller.dart`
- **主な変更ポイント**:
  1. `OrderManagementState` に `Map<String, CartItemViewData>` (例: `cartItemByMenuId`) を追加し、`cartItems` 更新時に再生成する。
  2. `state.isInCart` / `quantityFor` を `map.containsKey` / `map[id]?.quantity` に置き換え、`OrderManagementPage` のループでの線形探索を排除する。
  3. `_refreshCart` および `copyWith` で `cartItemByMenuId` を維持するよう拡張する。
  4. 既存テスト (存在する場合) を更新。新規に `OrderManagementState` の `isInCart`/`quantityFor` 相当のユニットテストを追加する。
- **完了条件**:
  - メニュー 200 件・カート 50 件のケースで `build` 時間がプロファイル上 30% 以上短縮されること。
  - `OrderManagementPage` のロジックが `cartItems` の順序変更の影響を受けないことを確認する。

### C. フィルタ済みメニューのソート最適化 (Phase 2)

- **対象ファイル**: `lib/features/order/presentation/controllers/order_management_controller.dart`
- **主な変更ポイント**:
  1. `_refreshCart` および初期ロードで `menuItems` を `displayOrder` 昇順に整列した状態で保持し、`List<MenuItemViewData>` を `UnmodifiableListView` 化する。
  2. `filteredMenuItems` ゲッターでの `toList` + `sort` をやめ、`where` 後に直接 `List.from` (必要な場合のみ) で返す形に変更する。必要に応じて簡易キャッシュ (`_FilteredMenuCache`) を導入。
  3. カテゴリ・検索条件変更時にキャッシュをリセットする仕組みを追加する。
  4. 合わせて `OrderManagementController` のユニットテスト (カテゴリ・検索変更) を追加し、順序が維持されることを保証する。
- **完了条件**:
  - DevTools でフィルタ操作時の CPU プロファイルから `sort` 呼び出しが消えること。
  - 検索語変更時のリビルド時間が 20% 以上減少すること。

### D. 注文メモ更新のデバウンス / 局所更新 (Phase 2)

- **対象ファイル**: `lib/features/order/presentation/pages/order_management_page.dart`, `lib/features/order/presentation/controllers/order_management_controller.dart`
- **主な変更ポイント**:
  1. `_CurrentOrderSection` で `TextEditingController` を維持しつつ、`onChanged` をローカル `ValueNotifier<String>` に接続する。
  2. `Timer` ベースのデバウンス (300ms 目安) で `controller.updateOrderNotes` を呼び出すか、`onEditingComplete/onSubmitted` でのみ更新を投げる。
  3. `OrderManagementState` とは別に `StateProvider<String>` (Riverpod) を導入し、`notes` 部分のみリビルドを限定する案も比較検討。フェーズ開始前に方針決定。
  4. 入力取り消し時の挙動を QA で確認するためのテストケースを追加する。
- **完了条件**:
  - 入力中にメニュー一覧が再ビルドされないことを Flutter Inspector `Rebuild Rainbow` で確認。
  - 注文メモ保存タイミングが既存仕様と整合する (保存ボタン押下時に最新メモが反映される)。

### E. カート更新後の差分反映 (Phase 3 / 拡張)

- **対象ファイル**: `lib/features/order/presentation/controllers/order_management_controller.dart`, `lib/features/order/domain/services/*`
- **主な変更ポイント**:
  1. アイテム追加・数量変更・削除メソッドで `_refreshCart` を即時呼び出す代わりに、ローカル状態を差分更新するヘルパー (`_applyCartMutation`) を実装する。
  2. 差分更新後にバックグラウンドで `getOrderWithItems` を非同期実行し、結果に差異があれば `state` を再同期する。
  3. 差分適用時に `cartItemByMenuId` キャッシュを同時更新する。
  4. ネットワーク失敗時のフォールバック (再同期 / エラートースト) を設計する。
- **完了条件**:
  - アイテム操作直後に UI が即時反映されること。
  - 差分同期と完全同期で表示不一致が発生しないことを自動テストで担保する。

## テスト計画

- **ユニットテスト**: `OrderManagementController` のフィルタ・カート更新ロジック、`cartItemByMenuId` の整合性、注文メモデバウンスの挙動。
- **ウィジェットテスト**: メニュー一覧の仮想化が期待通りの `childCount` になるか、注文メモ欄更新時に `YataMenuItemTile` が再ビルドされないかを確認。
- **パフォーマンステスト**: `flutter drive` + ゴールデンシナリオでフレームタイムと CPU 使用率を収集し、調査文書の課題が改善しているか比較。

## リスクとフォローアップ

- **スクロール挙動変更**: `GridView.builder` 化によりデザインやマウスホイール感度が変化する可能性 → QA で操作性を確認し、必要なら `ScrollConfiguration` を調整。
- **State 管理の複雑化**: マップキャッシュ導入で `copyWith` が肥大化する → プライベートコンストラクタ/ファクトリで初期化ロジックを共通化する。
- **差分同期の一貫性**: Phase 3 の導入で API 応答遅延と UI の不整合が発生し得る → 運用開始前に長時間セッション試験を実施。

## スケジュール目安

| フェーズ | 期間 | 主な成果物 |
|----------|------|------------|
| Phase 1  | 3日  | 仮想化リスト、カート参照最適化、関連テスト |
| Phase 2  | 3-4日 | ソート最適化、注文メモ局所更新、テスト整備 |
| Phase 3* | 4-5日 | 差分同期実装、リカバリハンドリング、パフォーマンス検証 |

> *Phase 3 は拡張扱い。Phase 1-2 完了後の計測結果をもとに実施判断を行う。

## 変更履歴

| 日付 | 変更内容 | 作成者 |
|------|----------|--------|
| 2025-10-02 | 初版作成 | Codex |

---

本計画は実装中の知見に応じて更新される可能性がある。
