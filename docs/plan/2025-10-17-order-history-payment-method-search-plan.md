# 注文履歴検索 支払い方法フィルタ追加実装計画（2025-10-17）

## 背景

注文履歴ページの検索機能が、現在は「受付コード」「顧客名」「メニュー名」の3つの項目でのみ検索可能である。

利用者が支払い方法（現金、PayPay、その他）で注文履歴を検索できるようにすることで、支払い方法別の集計や確認作業の効率性を向上させる。

## 課題分析

### 現状

- **ファイル**: `lib/features/order/presentation/controllers/order_history_controller.dart`
- **対象メソッド**: `filteredOrders` ゲッター（117～135行目付近）
- **検索ロジック**:
  ```dart
  final bool matchesOrderNumber = order.orderNumber?.toLowerCase().contains(query) ?? false;
  final bool matchesCustomerName = order.customerName?.toLowerCase().contains(query) ?? false;
  final bool matchesItemName = order.items.any(
    (OrderItemViewData item) => item.menuItemName.toLowerCase().contains(query),
  );
  return matchesOrderNumber || matchesCustomerName || matchesItemName;
  ```
- **問題点**:
  - 支払い方法（`paymentMethod`）がマッチング条件に含まれていない
  - 支払い方法は日本語ラベル（「現金」「PayPay」「その他」）で検索されるべきだが、現在はサポートされていない

### 関連データ構造

1. **`OrderHistoryViewData`** に `paymentMethod` フィールドが存在
   - 参照: `lib/features/order/presentation/view_data/order_history_view_data.dart`

2. **支払い方法の日本語変換**:
   - ユーティリティ: `lib/features/shared/utils/payment_method_label.dart`
   - 対応する値: `"現金"`, `"paypay"`, `"その他"`

3. **UI コンポーネント**:
   - `order_history_page.dart` の 234行目で検索フィールドの Hint が定義されている
   - 現在: `"受付コード、顧客名、メニュー名で検索..."`

### 検索フロー

- ユーザーが検索フィールドにテキストを入力
- `controller.setSearchQuery()` が呼ばれ、`state.searchQuery` が更新される
- UI が `state.filteredOrders` を監視し、画面が自動更新される

## 解決方針

1. **検索ロジックの拡張**
   - `filteredOrders` ゲッター内の検索条件に支払い方法マッチングを追加
   - 支払い方法の日本語ラベル（「現金」「PayPay」「その他」）でマッチング

2. **UI ヒントテキストの更新**
   - 検索フィールドの Hint に「支払い方法」を追加
   - ユーザーに検索可能項目を明示

3. **サーチクエリの正規化**
   - 既存の `.toLowerCase()` に合わせて、支払い方法も小文字で比較

## タスク分解

### 1. 支払い方法マッチングロジックの追加

**ファイル**: `lib/features/order/presentation/controllers/order_history_controller.dart`

**修正範囲**: `filteredOrders` ゲッター内の検索条件部分

```dart
// 変更前（117～128行目付近）
// 検索クエリフィルター
if (searchQuery.isNotEmpty) {
  final String query = searchQuery.toLowerCase();
  filtered = filtered.where((OrderHistoryViewData order) {
    final bool matchesOrderNumber = order.orderNumber?.toLowerCase().contains(query) ?? false;
    final bool matchesCustomerName = order.customerName?.toLowerCase().contains(query) ?? false;
    final bool matchesItemName = order.items.any(
      (OrderItemViewData item) => item.menuItemName.toLowerCase().contains(query),
    );
    return matchesOrderNumber || matchesCustomerName || matchesItemName;
  }).toList();
}

// 変更後
// 検索クエリフィルター
if (searchQuery.isNotEmpty) {
  final String query = searchQuery.toLowerCase();
  filtered = filtered.where((OrderHistoryViewData order) {
    final bool matchesOrderNumber = order.orderNumber?.toLowerCase().contains(query) ?? false;
    final bool matchesCustomerName = order.customerName?.toLowerCase().contains(query) ?? false;
    final bool matchesItemName = order.items.any(
      (OrderItemViewData item) => item.menuItemName.toLowerCase().contains(query),
    );
    // 支払い方法マッチングを追加
    final String paymentLabel = _paymentMethodLabel(order.paymentMethod).toLowerCase();
    final bool matchesPaymentMethod = paymentLabel.contains(query);
    
    return matchesOrderNumber || matchesCustomerName || matchesItemName || matchesPaymentMethod;
  }).toList();
}
```

### 2. ヘルパーメソッド `_paymentMethodLabel` の追加

**追加位置**: `OrderHistoryController` クラス内、`_ensureUserId()` メソッド直前など

```dart
/// 支払い方法を日本語ラベルに変換する。
String _paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return "現金";
    case PaymentMethod.paypay:
      return "PayPay";
    case PaymentMethod.other:
      return "その他";
  }
}
```

**注**: 既存の `lib/features/shared/utils/payment_method_label.dart` を再利用する場合は、そのインポートを追加してそのまま利用可能。ただし、コントローラー内のローカルメソッドとして記述する方が、メモリ利用とテストの独立性を高める。

### 3. UI ヒントテキストの更新

**ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**修正範囲**: 234行目付近の `YataSearchField` の `hintText`

```dart
// 変更前
YataSearchField(
  controller: _searchController,
  hintText: "受付コード、顧客名、メニュー名で検索...",
  onChanged: controller.setSearchQuery,
),

// 変更後
YataSearchField(
  controller: _searchController,
  hintText: "受付コード、顧客名、メニュー名、支払い方法で検索...",
  onChanged: controller.setSearchQuery,
),
```

### 4. インポート確認

- `OrderHistoryController` が `PaymentMethod` enum をインポートしているか確認
  - 既存の `order_history_controller.dart` に確認: `import "../../models/order_model.dart";` が存在するか
  - なければ `import "../../../../core/constants/enums.dart";` を追加

### 5. 静的解析・フォーマッティング

- `flutter analyze` を実行し、エラーがないことを確認
- `dart format` を実行し、コード形式を整える

### 6. ユニットテスト追加（推奨）

**ファイル**: `test/features/order/presentation/controllers/order_history_controller_test.dart`

テスト例:
```dart
test('filteredOrders should match payment method', () {
  // Given
  final OrderHistoryViewData orderWithCash = OrderHistoryViewData(
    id: '1',
    orderNumber: '#1001',
    customerName: 'John',
    paymentMethod: PaymentMethod.cash,
    items: [],
    totalAmount: 1000,
    status: OrderStatus.completed.value,
    orderedAt: DateTime.now(),
  );
  
  final state = OrderHistoryState(
    orders: [orderWithCash],
  );
  
  // When
  final state2 = state.copyWith(searchQuery: '現金');
  
  // Then
  expect(state2.filteredOrders, contains(orderWithCash));
});
```

## 検証計画

### UI 検証チェックリスト
- [ ] 注文履歴ページを起動
- [ ] 検索フィールドのヒントテキストに「支払い方法」が表示されている
- [ ] 「現金」と入力すると、支払い方法が現金の注文のみが表示される
- [ ] 「PayPay」と入力すると、支払い方法が PayPay の注文のみが表示される
- [ ] 「その他」と入力すると、支払い方法が「その他」の注文のみが表示される
- [ ] 大文字・小文字が混在したクエリでも動作する（例: 「現金」「PAYPAY」等）
- [ ] 複数条件での検索が動作する（例: 「中山 現金」で「中山」かつ支払い方法「現金」）

### コード検証チェックリスト
- [ ] `flutter analyze` にエラーがない
- [ ] `dart format` で形式が統一されている
- [ ] インポートが適切に追加されている
- [ ] 既存の検索ロジック（注文番号、顧客名、メニュー名）が機能している

## 成果物

- `lib/features/order/presentation/controllers/order_history_controller.dart` の修正版
- `lib/features/order/presentation/pages/order_history_page.dart` の修正版
- （推奨）`test/features/order/presentation/controllers/order_history_controller_test.dart` の更新版

## リスク・注意事項

- **検索ロジックの複雑化**: 複数の OR 条件により、検索結果の予測可能性が若干低下する可能性がある
  - ⇒ UI ヒントで明示し、テストをしっかり実施することで軽減
- **ローカルフィルタリング**: サーバー側ではなくクライアント側でフィルタリングされるため、データが大規模化した場合はサーバー側での実装を検討
- **大文字小文字の正規化**: `toLowerCase()` を使用しているため、言語によっては予期しない結果になる可能性がある
  - ⇒ 現在のアプリが日本語環境なので問題なし

## 関連タスク

- **ID**: Order-Enhancement-29
- **Priority**: P2
- **Size**: S
- **Goal**: 注文履歴ページの検索フィールドで支払い方法による検索が可能になる
- **関連機能**: 注文検索・フィルタリング、支払い方法管理

## スケジュール目安

- コード修正: 20～30分
- UI 更新: 5分
- テスト・検証: 20～30分
- **合計**: 1時間程度

## 参考資料

- **PaymentMethod enum**: `lib/core/constants/enums.dart`
- **支払い方法ラベル**: `lib/features/shared/utils/payment_method_label.dart`
- **検索実装例**: `lib/features/order/presentation/controllers/order_history_controller.dart` の既存検索ロジック
- **UI コンポーネント**: `lib/features/order/presentation/pages/order_history_page.dart` の `YataSearchField`

