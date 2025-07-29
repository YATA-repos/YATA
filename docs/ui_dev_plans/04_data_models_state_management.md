# Phase 4: 状態管理・既存モデル統合計画

## 概要

既存の豊富なドメインモデルとサービス層を活用し、Riverpodベースの状態管理システムを実装する。UI専用モデルの新規作成を最小限に抑え、既存実装との効率的な統合を図る。

## 1. 既存実装の活用方針

### 1.1 ✅ 活用可能な既存資産

#### 完全実装済みドメインモデル
- **MenuItem**: 名前、価格、カテゴリ、画像URL、販売可否等
- **MenuCategory**: カテゴリ名、表示順序
- **Order**: 合計金額、ステータス、支払い方法、顧客名等
- **OrderItem**: 注文明細、数量、単価、選択オプション等
- **全てJSON対応**: シリアライゼーション・デシリアライゼーション完備

#### 詳細実装済みサービス層
- **MenuService**: 在庫チェック、検索、可否状態管理等の包括的業務ロジック
- **バリデーション**: InputValidator による入力検証
- **ログ機能**: LoggerMixin による詳細ログ管理
- **例外処理**: 統一された例外ハンドリング

### 1.2 新規作成方針

#### UI層特化の薄いラッパー
既存ドメインモデルの**軽量プロキシ**として、UI特化の拡張メソッドのみ追加

#### 最小限のUI専用モデル
複雑なUI状態管理が必要な場合のみ作成

## 2. 統合アーキテクチャ設計

### 2.1 レイヤー統合

```text
UI Layer (Presentation)
├── Widgets
├── Riverpod Providers ← 新規実装
└── UI Extensions ← 軽量な既存モデル拡張
    ↓ (直接統合)
Business Services Layer (既存)
├── MenuService ← 直接利用
├── OrderService ← 直接利用  
└── Domain Models ← 直接利用
    ↓
Repository Layer (既存)
```

### 2.2 データフロー（簡素化）

```text
Repository → Service → Riverpod Provider → Widget
                ↓
           Domain Model → UI Extension → Widget State
```

## 3. 既存モデル活用型の実装

### 3.1 軽量UI拡張（Extension活用）

#### MenuItem UI拡張
```dart
// shared/extensions/menu_item_extensions.dart
extension MenuItemUIExtensions on MenuItem {
  // UI表示用の価格フォーマット
  String get formattedPrice => '¥${price.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},',
  )}';
  
  // 在庫状況の色
  Color get stockStatusColor {
    if (!isAvailable) return AppColors.outOfStock;
    // MenuServiceを使って在庫チェック（必要に応じて）
    return AppColors.inStock;
  }
  
  // UI表示用の説明文
  String get displayDescription => description ?? '説明なし';
  
  // 推定調理時間の表示
  String get prepTimeDisplay => '約${estimatedPrepTimeMinutes}分';
}
```

#### Order UI拡張
```dart
// shared/extensions/order_extensions.dart
extension OrderUIExtensions on Order {
  // ステータス表示文
  String get statusDisplayText => switch (status) {
    OrderStatus.pending => '受付中',
    OrderStatus.preparing => '調理中', 
    OrderStatus.ready => '完成',
    OrderStatus.delivered => '提供済み',
    OrderStatus.cancelled => 'キャンセル',
  };
  
  // ステータス色
  Color get statusColor => switch (status) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.preparing => AppColors.cooking,
    OrderStatus.ready => AppColors.success,
    OrderStatus.delivered => AppColors.complete,
    OrderStatus.cancelled => AppColors.cancel,
  };
  
  // 経過時間
  Duration get elapsedTime => DateTime.now().difference(orderedAt);
  
  // 表示用合計金額
  String get formattedTotal => '¥${totalAmount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )}';
}
```

### 3.2 UI専用軽量モデル（最小限）

#### カート専用状態
```dart
// shared/models/cart_state.dart
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    @Default(0) int totalAmount,
    @Default(0) int itemCount,
  }) = _CartState;

  // 既存OrderItemからの変換
  factory CartState.fromOrderItems(List<OrderItem> orderItems) {
    final cartItems = orderItems.map(CartItem.fromOrderItem).toList();
    final total = cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    final count = cartItems.fold(0, (sum, item) => sum + item.quantity);
    
    return CartState(
      items: cartItems,
      totalAmount: total,
      itemCount: count,
    );
  }
}

@freezed  
class CartItem with _$CartItem {
  const factory CartItem({
    required String menuItemId,
    required String name,
    required int unitPrice,
    required int quantity,
  }) = _CartItem;
  
  int get totalPrice => unitPrice * quantity;
  
  // 既存OrderItemからの変換
  factory CartItem.fromOrderItem(OrderItem orderItem) {
    return CartItem(
      menuItemId: orderItem.menuItemId,
      name: orderItem.menuItemId, // 実際にはMenuItemから取得
      unitPrice: orderItem.unitPrice,
      quantity: orderItem.quantity,
    );
  }
}
```

## 4. Riverpod統合プロバイダー実装

### 4.1 既存サービス統合

#### Menu関連プロバイダー
```dart
// features/menu/presentation/providers/menu_providers.dart

// 既存サービスの提供
@riverpod
MenuService menuService(MenuServiceRef ref) {
  return MenuService(); // 既存のサービスインスタンス
}

// 既存ドメインモデルを直接使用
@riverpod
Future<List<MenuItem>> menuItems(MenuItemsRef ref, String userId) async {
  final service = ref.watch(menuServiceProvider);
  return service.getMenuItemsByCategory(null, userId); // 既存メソッド直接呼び出し
}

@riverpod
Future<List<MenuCategory>> menuCategories(MenuCategoriesRef ref, String userId) async {
  final service = ref.watch(menuServiceProvider);
  return service.getMenuCategories(userId); // 既存メソッド直接呼び出し
}

@riverpod
Future<List<MenuItem>> searchMenuItems(
  SearchMenuItemsRef ref,
  String keyword,
  String userId,
) async {
  final service = ref.watch(menuServiceProvider);
  return service.searchMenuItems(keyword, userId); // 既存検索ロジック活用
}

// UI状態管理（軽量）
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String build() => 'all';

  void selectCategory(String categoryId) {
    state = categoryId;
  }
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}
```

#### Order/Cart関連プロバイダー
```dart
// features/order/presentation/providers/order_providers.dart

@riverpod
OrderService orderService(OrderServiceRef ref) {
  return OrderService(); // 既存サービス
}

// カート状態管理（UI専用の軽量状態）
@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void addMenuItem(MenuItem menuItem) {
    // MenuItemから直接カートアイテム作成
    final existingIndex = state.items.indexWhere(
      (item) => item.menuItemId == menuItem.id,
    );
    
    if (existingIndex != -1) {
      // 数量増加
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      state = _recalculateCart(updatedItems);
    } else {
      // 新規追加
      final newItem = CartItem(
        menuItemId: menuItem.id!,
        name: menuItem.name,
        unitPrice: menuItem.price,
        quantity: 1,
      );
      state = _recalculateCart([...state.items, newItem]);
    }
  }

  void removeMenuItem(String menuItemId) {
    final updatedItems = state.items
        .where((item) => item.menuItemId != menuItemId)
        .toList();
    state = _recalculateCart(updatedItems);
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeMenuItem(menuItemId);
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.menuItemId == menuItemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = _recalculateCart(updatedItems);
  }

  void clear() {
    state = const CartState();
  }

  // 既存サービスを使用して注文確定
  Future<Order?> checkout(String userId, {String? customerName}) async {
    final service = ref.read(orderServiceProvider);
    
    // CartStateを既存OrderItemに変換
    final orderItems = state.items.map((cartItem) => OrderItem(
      orderId: '', // 後で設定
      menuItemId: cartItem.menuItemId,
      quantity: cartItem.quantity,
      unitPrice: cartItem.unitPrice,
      subtotal: cartItem.totalPrice,
      userId: userId,
    )).toList();

    // 既存サービスで注文作成（実装詳細は既存サービスに依存）
    try {
      // final order = await service.createOrder(orderItems, userId, customerName);
      // clear(); // 成功時にカートクリア
      // return order;
      return null; // 既存サービス実装待ち
    } catch (e) {
      rethrow;
    }
  }

  CartState _recalculateCart(List<CartItem> items) {
    final total = items.fold(0, (sum, item) => sum + item.totalPrice);
    final count = items.fold(0, (sum, item) => sum + item.quantity);
    
    return CartState(
      items: items,
      totalAmount: total,
      itemCount: count,
    );
  }
}

// 既存ドメインモデルを直接使用
@riverpod
Future<List<Order>> activeOrders(ActiveOrdersRef ref, String userId) async {
  final service = ref.read(orderServiceProvider);
  // return service.getActiveOrders(userId); // 既存メソッド（実装詳細に依存）
  return []; // 実装待ち
}
```

### 4.2 キャッシュ戦略・エラーハンドリング

#### 統一エラーハンドリング
```dart
// core/providers/error_providers.dart
@riverpod
class GlobalError extends _$GlobalError {
  @override
  String? build() => null;

  void setError(String error) {
    state = error;
  }

  void clearError() {
    state = null;
  }
}

// 既存例外システムとの統合
extension AppExceptionExtension on Exception {
  String get displayMessage {
    if (this is ValidationException) {
      return (this as ValidationException).message;
    }
    return toString();
  }
}
```

#### キャッシュ設定
```dart
// core/providers/cache_providers.dart
@riverpod
class CacheManager extends _$CacheManager {
  @override
  Duration build() => const Duration(minutes: 5);

  void setCacheDuration(Duration duration) {
    state = duration;
  }
}
```

## 5. 実装タスクとスケジュール（大幅短縮）

### Week 1: サービス統合プロバイダー
- [x] 既存MenuServiceの確認完了
- [ ] Menu関連Riverpodプロバイダー実装
- [ ] Order関連Riverpodプロバイダー実装

### Week 2: UI拡張・軽量モデル
- [ ] MenuItem/Order UI拡張実装
- [ ] CartState等の軽量UI専用モデル実装
- [ ] エラーハンドリング統合

### Week 3: 統合テスト・最適化
- [ ] 既存サービスとの統合テスト
- [ ] パフォーマンス最適化
- [ ] キャッシュ戦略実装

## 6. 工数削減効果

### 大幅短縮された実装範囲
- **削減**: 複雑なUI専用モデル作成（90%削減）
- **削減**: ドメインモデル変換ロジック（70%削減）
- **削減**: サービス層プロキシ作成（100%削減）

### 元計画との比較
- **元計画**: 4週間（新規モデル作成中心）
- **修正計画**: 3週間（既存活用中心）
- **短縮効果**: 25%の工数削減

## 7. 依存関係（最小限）

### 新規追加のみ
```yaml
dependencies:
  freezed_annotation: ^2.4.1  # 軽量モデル用

dev_dependencies:
  freezed: ^2.4.7
  json_serializable: ^6.7.1  # CartState等用
  build_runner: ^2.4.7
```

## 8. 完了条件

### 統合完了条件
- [ ] 既存サービスがRiverpodから利用可能
- [ ] 既存ドメインモデルがUI層で活用可能
- [ ] UI拡張（Extension）が実装済み
- [ ] 軽量UI専用モデルが実装済み

### 品質完了条件
- [ ] 既存バリデーションシステムが統合済み
- [ ] 既存ログシステムが統合済み
- [ ] エラーハンドリングが統一済み
- [ ] 単体テストが作成済み

## 9. 次のPhaseとの連携

### Phase 3（画面実装）での直接利用
```dart
// 既存モデル + UI拡張の直接活用例
class MenuItemCard extends ConsumerWidget {
  final MenuItem menuItem; // 既存ドメインモデルを直接使用
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          Text(menuItem.name), // 既存プロパティ
          Text(menuItem.formattedPrice), // UI拡張メソッド
          Container(
            color: menuItem.stockStatusColor, // UI拡張プロパティ
            child: Text(menuItem.statusDisplayText),
          ),
          ElevatedButton(
            onPressed: () => ref.read(cartProvider.notifier)
                .addMenuItem(menuItem), // 既存モデルを直接渡す
            child: Text('カートに追加'),
          ),
        ],
      ),
    );
  }
}
```

この統合アプローチにより、既存の豊富な実装資産を最大限活用しながら、効率的なUI層実装を実現する。