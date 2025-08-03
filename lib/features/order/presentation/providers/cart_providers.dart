import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/utils/provider_logger.dart";
import "../../../../shared/models/cart_models.dart";
import "../../../../shared/providers/common_providers.dart";
import "../../../auth/models/user_profile.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../../menu/models/menu_model.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";
import "../../services/cart_service.dart";
import "../../services/order_service.dart";

part "cart_providers.g.dart";

/// CartService プロバイダー
/// 既存のカート管理サービスをRiverpodで利用可能にする
@riverpod
CartService cartService(Ref ref) => CartService(ref: ref);

/// アクティブなカートプロバイダー
/// ユーザーのアクティブなカート（下書き注文）を取得/作成
@riverpod
Future<Order?> activeCart(Ref ref, String userId) async {
  final CartService service = ref.watch(cartServiceProvider);
  return service.getOrCreateActiveCart(userId);
}

/// カート状態管理プロバイダー
/// アプリケーション全体のカート状態を管理
@riverpod
class Cart extends _$Cart with ProviderLoggerMixin {
  @override
  String get providerComponent => "Cart";
  @override
  CartState build() => const CartState();

  /// メニューアイテムをカートに追加
  /// 既存アイテムがある場合は数量を増加
  /// CartServiceを使用してバックエンドと同期
  Future<void> addMenuItem(
    MenuItem menuItem, {
    int quantity = 1,
    Map<String, String>? options,
    String? specialRequest,
  }) async {
    logDebug("カートへのアイテム追加を開始: ${menuItem.name} (quantity: $quantity)");
    
    try {
      // ローカルカート状態を即座に更新（UI応答性のため）
      final CartItem cartItem = CartItem.fromMenuItem(
        menuItem,
        quantity: quantity,
      ).copyWith(selectedOptions: options, specialRequest: specialRequest);
      state = state.addItem(cartItem);

      // バックエンドサービスとの同期
      final UserProfile? currentUser = ref.read(currentUserProvider);
      final String? userId = ref.read(currentUserIdProvider);
      if (currentUser != null && userId != null) {
        logDebug("バックエンドとの同期処理を開始");
        final Order? activeCartOrder = await ref.read(activeCartProvider(userId).future);
        if (activeCartOrder != null) {
          final CartService cartService = ref.read(cartServiceProvider);
          final CartItemRequest request = CartItemRequest(
            menuItemId: menuItem.id!,
            quantity: quantity,
            selectedOptions: options,
            specialRequest: specialRequest,
          );

          final (OrderItem? orderItem, bool success) = await cartService.addItemToCart(
            activeCartOrder.id!,
            request,
            userId,
          );

          if (!success) {
            // バックエンド失敗時はローカル状態をロールバック
            state = state.removeItem(menuItem.id!, options: options);
            final String errorMsg = "在庫が不足しています";
            logCartOperationFailed("addMenuItem", Exception(errorMsg));
            throw Exception(errorMsg);
          }
        }
      }

      // 成功メッセージを表示
      ref.read(successMessageProvider.notifier).setMessage("${menuItem.name}をカートに追加しました");
      logInfo("カートへのアイテム追加が完了: ${menuItem.name}");
    } catch (e, stackTrace) {
      // エラーハンドリング
      logCartOperationFailed("addMenuItem", e, stackTrace);
      ref.read(globalErrorProvider.notifier).setError("カートへの追加に失敗しました: ${e.toString()}");
    }
  }

  /// カートアイテムを追加
  void addItem(CartItem item) {
    state = state.addItem(item);
  }

  /// アイテムをカートから削除
  /// CartServiceを使用してバックエンドと同期
  Future<void> removeItem(String menuItemId, {Map<String, String>? options}) async {
    try {
      // 削除対象のアイテムを特定
      final CartItem? itemToRemove = state.items.cast<CartItem?>().firstWhere(
        (CartItem? item) =>
            item?.menuItemId == menuItemId && (options == null || item?.selectedOptions == options),
        orElse: () => null,
      );

      if (itemToRemove == null) {
        throw Exception("削除対象のアイテムが見つかりません");
      }

      // ローカル状態を即座に更新（UI応答性のため）
      final CartState previousState = state;
      state = state.removeItem(menuItemId, options: options);

      // バックエンドサービスとの同期
      final UserProfile? currentUser = ref.read(currentUserProvider);
      final String? userId = ref.read(currentUserIdProvider);
      if (currentUser != null && userId != null) {
        final Order? activeCartOrder = await ref.read(activeCartProvider(userId).future);
        if (activeCartOrder != null) {
          final CartService cartService = ref.read(cartServiceProvider);

          // OrderItemのIDを推定（実際の実装では適切なマッピングが必要）
          final String orderItemId =
              "${itemToRemove.menuItemId}_${itemToRemove.hashCode}";

          final bool success = await cartService.removeItemFromCart(
            activeCartOrder.id!,
            orderItemId,
            userId,
          );

          if (!success) {
            // バックエンド失敗時はローカル状態をロールバック
            state = previousState;
            throw Exception("アイテムの削除に失敗しました");
          }
        }
      }

      // 成功メッセージを表示
      ref.read(successMessageProvider.notifier).setMessage("アイテムを削除しました");
    } catch (e) {
      // エラーハンドリング
      ref.read(globalErrorProvider.notifier).setError("アイテムの削除に失敗しました: ${e.toString()}");
    }
  }

  /// アイテムの数量を更新
  /// CartServiceを使用してバックエンドと同期
  Future<void> updateQuantity(
    String menuItemId,
    int quantity, {
    Map<String, String>? options,
  }) async {
    try {
      // 数量が0以下の場合は削除処理を呼び出し
      if (quantity <= 0) {
        await removeItem(menuItemId, options: options);
        return;
      }

      // 更新対象のアイテムを特定
      final CartItem? itemToUpdate = state.items.cast<CartItem?>().firstWhere(
        (CartItem? item) =>
            item?.menuItemId == menuItemId && (options == null || item?.selectedOptions == options),
        orElse: () => null,
      );

      if (itemToUpdate == null) {
        throw Exception("更新対象のアイテムが見つかりません");
      }

      // ローカル状態を即座に更新（UI応答性のため）
      final CartState previousState = state;
      state = state.updateItemQuantity(menuItemId, quantity, options: options);

      // バックエンドサービスとの同期
      final UserProfile? currentUser = ref.read(currentUserProvider);
      final String? userId = ref.read(currentUserIdProvider);
      if (currentUser != null && userId != null) {
        final Order? activeCartOrder = await ref.read(activeCartProvider(userId).future);
        if (activeCartOrder != null) {
          final CartService cartService = ref.read(cartServiceProvider);

          // OrderItemのIDを推定（実際の実装では適切なマッピングが必要）
          final String orderItemId =
              "${itemToUpdate.menuItemId}_${itemToUpdate.hashCode}";

          final (OrderItem? orderItem, bool success) = await cartService.updateCartItemQuantity(
            activeCartOrder.id!,
            orderItemId,
            quantity,
            userId,
          );

          if (!success) {
            // バックエンド失敗時はローカル状態をロールバック
            state = previousState;
            throw Exception("数量の更新に失敗しました");
          }
        }
      }

      // 成功メッセージを表示
      ref.read(successMessageProvider.notifier).setMessage("数量を更新しました");
    } catch (e) {
      // エラーハンドリング
      ref.read(globalErrorProvider.notifier).setError("数量の更新に失敗しました: ${e.toString()}");
    }
  }

  /// アイテム数量を1増加
  Future<void> incrementQuantity(String menuItemId, {Map<String, String>? options}) async {
    final CartItem? currentItem = state.items.cast<CartItem?>().firstWhere(
      (CartItem? item) =>
          item?.menuItemId == menuItemId && (options == null || item?.selectedOptions == options),
      orElse: () => null,
    );

    if (currentItem != null) {
      await updateQuantity(menuItemId, currentItem.quantity + 1, options: options);
    }
  }

  /// アイテム数量を1減少（最小0）
  Future<void> decrementQuantity(String menuItemId, {Map<String, String>? options}) async {
    final CartItem? currentItem = state.items.cast<CartItem?>().firstWhere(
      (CartItem? item) =>
          item?.menuItemId == menuItemId && (options == null || item?.selectedOptions == options),
      orElse: () => null,
    );

    if (currentItem != null) {
      await updateQuantity(menuItemId, currentItem.quantity - 1, options: options);
    }
  }

  /// カートをクリア
  /// CartServiceを使用してバックエンドと同期
  Future<void> clear({String? cartId}) async {
    try {
      // ローカル状態を即座に更新（UI応答性のため）
      final CartState previousState = state;
      state = state.clear();

      // バックエンドサービスとの同期
      final UserProfile? currentUser = ref.read(currentUserProvider);
      final String? userId = ref.read(currentUserIdProvider);
      if (currentUser != null && userId != null && cartId != null) {
        final CartService cartService = ref.read(cartServiceProvider);

        final bool success = await cartService.clearCart(cartId, userId);

        if (!success) {
          // バックエンド失敗時はローカル状態をロールバック
          state = previousState;
          throw Exception("カートのクリアに失敗しました");
        }
      }

      // 成功メッセージを表示
      ref.read(successMessageProvider.notifier).setMessage("カートをクリアしました");
    } catch (e) {
      // エラーハンドリング
      ref.read(globalErrorProvider.notifier).setError("カートのクリアに失敗しました: ${e.toString()}");
    }
  }

  /// 割引を適用
  void applyDiscount(int discountAmount) {
    state = state.applyDiscount(discountAmount);

    ref.read(successMessageProvider.notifier).setMessage("割引を適用しました");
  }

  /// 備考を追加
  void addNotes(String notes) {
    state = state.addNotes(notes);
  }

  /// チェックアウト処理
  /// 既存のカート（preparing状態のOrder）をチェックアウト
  Future<String?> checkout({
    String? cartId,
    String? customerName,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? notes,
  }) async {
    try {
      // ローディング開始
      ref.read(globalLoadingProvider.notifier).startLoading();

      // 認証されたユーザーを取得
      final UserProfile? currentUser = ref.read(currentUserProvider);
      final String? userId = ref.read(currentUserIdProvider);
      if (currentUser == null || userId == null) {
        throw Exception("ユーザーが認証されていません");
      }

      // カートが空の場合はエラー
      if (state.isEmpty) {
        throw Exception("カートにアイテムがありません");
      }

      // カートIDが提供されていない場合はエラー
      if (cartId == null) {
        throw Exception("カートIDが必要です");
      }

      // OrderServiceを使用してチェックアウト
      final OrderService orderService = OrderService(ref: ref);

      // チェックアウトリクエストを作成
      final OrderCheckoutRequest checkoutRequest = OrderCheckoutRequest(
        paymentMethod: paymentMethod,
        customerName: customerName,
        discountAmount: state.discountAmount,
        notes: notes ?? state.notes,
      );

      // チェックアウト実行
      final (Order? order, bool success) = await orderService.checkoutCart(
        cartId,
        checkoutRequest,
        userId,
      );

      if (success && order != null) {
        // カートをクリア（バックエンド同期なし、既にチェックアウト済みのため）
        state = state.clear();

        // 成功メッセージ
        ref.read(successMessageProvider.notifier).setMessage("注文が正常に作成されました");

        return order.id;
      } else {
        throw Exception("チェックアウトに失敗しました");
      }
    } catch (e) {
      // エラーハンドリング
      ref.read(globalErrorProvider.notifier).setError("注文の作成に失敗しました: ${e.toString()}");
      return null;
    } finally {
      // ローディング停止
      ref.read(globalLoadingProvider.notifier).stopLoading();
    }
  }
}

/// カートアイテム数プロバイダー
/// ヘッダーバッジなどで使用
@riverpod
int cartItemCount(Ref ref) {
  final CartState cart = ref.watch(cartProvider);
  return cart.itemCount;
}

/// カート合計金額プロバイダー
/// UI表示用のフォーマット済み文字列
@riverpod
String cartTotalFormatted(Ref ref) {
  final CartState cart = ref.watch(cartProvider);
  return cart.formattedFinalAmount;
}

/// カートが空かどうかプロバイダー
@riverpod
bool isCartEmpty(Ref ref) {
  final CartState cart = ref.watch(cartProvider);
  return cart.isEmpty;
}

/// 特定のメニューアイテムがカートに含まれているかプロバイダー
@riverpod
bool isMenuItemInCart(Ref ref, String menuItemId, {Map<String, String>? options}) {
  final CartState cart = ref.watch(cartProvider);
  return cart.items.any(
    (CartItem item) =>
        item.menuItemId == menuItemId && (options == null || item.selectedOptions == options),
  );
}

/// カート内の特定アイテムの数量プロバイダー
@riverpod
int menuItemQuantityInCart(Ref ref, String menuItemId, {Map<String, String>? options}) {
  final CartState cart = ref.watch(cartProvider);

  try {
    final CartItem item = cart.items.firstWhere(
      (CartItem item) =>
          item.menuItemId == menuItemId && (options == null || item.selectedOptions == options),
    );
    return item.quantity;
  } catch (e) {
    return 0;
  }
}

/// カートアイテムリストプロバイダー
/// カート画面での表示用
@riverpod
List<CartItem> cartItems(Ref ref) {
  final CartState cart = ref.watch(cartProvider);
  return cart.items;
}

/// カート割引情報プロバイダー
@riverpod
class CartDiscount extends _$CartDiscount {
  @override
  int build() => 0;

  /// 割引額を設定
  void setDiscount(int amount) {
    state = amount;
    // カートに割引を適用
    ref.read(cartProvider.notifier).applyDiscount(amount);
  }

  /// 割引をクリア
  void clearDiscount() {
    state = 0;
    ref.read(cartProvider.notifier).applyDiscount(0);
  }

  /// パーセンテージで割引を適用
  void applyPercentageDiscount(double percentage) {
    final CartState cart = ref.read(cartProvider);
    final int discountAmount = (cart.totalAmount * percentage / 100).round();
    setDiscount(discountAmount);
  }
}

/// カート備考プロバイダー
@riverpod
class CartNotes extends _$CartNotes {
  @override
  String build() => "";

  /// 備考を更新
  void updateNotes(String notes) {
    state = notes;
    ref.read(cartProvider.notifier).addNotes(notes);
  }

  /// 備考をクリア
  void clearNotes() {
    state = "";
    ref.read(cartProvider.notifier).addNotes("");
  }
}

/// チェックアウト状態プロバイダー
/// チェックアウト進行中の状態を管理
@riverpod
class CheckoutState extends _$CheckoutState {
  @override
  bool build() => false;

  /// チェックアウト開始
  void startCheckout() {
    state = true;
  }

  /// チェックアウト完了
  void completeCheckout() {
    state = false;
  }

  /// チェックアウト処理実行
  Future<String?> processCheckout({
    String? cartId,
    String? customerName,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? notes,
  }) async {
    try {
      startCheckout();

      final String? orderId = await ref
          .read(cartProvider.notifier)
          .checkout(
            cartId: cartId,
            customerName: customerName,
            paymentMethod: paymentMethod,
            notes: notes,
          );

      return orderId;
    } finally {
      completeCheckout();
    }
  }
}
