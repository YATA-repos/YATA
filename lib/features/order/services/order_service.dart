import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../../menu/repositories/menu_item_repository.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";
import "../repositories/order_repository.dart";

/// 注文管理サービス
@loggerComponent
class OrderService with LoggerMixin {
  /// コンストラクタ
  OrderService({
    OrderRepository? orderRepository,
    OrderItemRepository? orderItemRepository,
    MenuItemRepository? menuItemRepository,
    MaterialRepository? materialRepository,
    RecipeRepository? recipeRepository,
  }) : _orderRepository = orderRepository ?? OrderRepository(),
       _orderItemRepository = orderItemRepository ?? OrderItemRepository(),
       _menuItemRepository = menuItemRepository ?? MenuItemRepository(),
       _materialRepository = materialRepository ?? MaterialRepository(),
       _recipeRepository = recipeRepository ?? RecipeRepository();

  final OrderRepository _orderRepository;
  final OrderItemRepository _orderItemRepository;
  final MenuItemRepository _menuItemRepository;
  final MaterialRepository _materialRepository;
  final RecipeRepository _recipeRepository;

  /// カートを確定して正式注文に変換（戻り値: (Order, 成功フラグ)）
  Future<(Order?, bool)> checkoutCart(
    String cartId,
    OrderCheckoutRequest request,
    String userId,
  ) async {
    // カートの存在確認
    final Order? cart = await _orderRepository.getById(cartId);
    if (cart == null || cart.userId != userId) {
      throw Exception("Cart $cartId not found or access denied");
    }

    if (cart.status != OrderStatus.preparing) {
      throw Exception("Cart is not in preparing status");
    }

    // カート内アイテムの取得
    final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
    if (cartItems.isEmpty) {
      throw Exception("Cart is empty");
    }

    // 在庫確認
    final Map<String, bool> stockValidation = <String, bool>{};
    bool allSufficient = true;

    for (final OrderItem item in cartItems) {
      final bool isSufficient = await _checkMenuItemStock(item.menuItemId, item.quantity, userId);
      stockValidation[item.id!] = isSufficient;
      if (!isSufficient) {
        allSufficient = false;
      }
    }

    if (!allSufficient) {
      return (cart, false);
    }

    // 材料消費の実行
    await _consumeMaterialsForOrder(cartItems, userId);

    // 注文の確定
    // 注文番号生成（将来の使用のため）
    await _orderRepository.generateNextOrderNumber(userId);

    final Order? updatedOrder = await _orderRepository.updateById(cartId, <String, dynamic>{
      "payment_method": request.paymentMethod.value,
      "customer_name": request.customerName,
      "discount_amount": request.discountAmount,
      "notes": request.notes,
      "ordered_at": DateTime.now().toIso8601String(),
      "status": OrderStatus.preparing.value,
    });

    // 最終金額を計算して更新
    final OrderCalculationResult calculation = await _calculateOrderTotal(
      cartId,
      discountAmount: request.discountAmount,
    );
    await _orderRepository.updateById(cartId, <String, dynamic>{
      "total_amount": calculation.totalAmount,
    });

    return (updatedOrder, true);
  }

  /// 注文をキャンセル（在庫復元含む）
  Future<(Order?, bool)> cancelOrder(String orderId, String reason, String userId) async {
    // 注文の存在確認
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      throw Exception("Order $orderId not found or access denied");
    }

    if (order.status == OrderStatus.canceled) {
      return (order, false); // 既にキャンセル済み
    }

    if (order.status == OrderStatus.completed) {
      throw Exception("Cannot cancel completed order");
    }

    // 材料在庫を復元（まだ調理開始前の場合のみ）
    if (order.startedPreparingAt == null) {
      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);
      await _restoreMaterialsFromOrder(orderItems, userId);
    }

    // 注文をキャンセル状態に更新
    final String newNotes = "${order.notes ?? ""} [CANCELED: $reason]".trim();
    final Order? canceledOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
      "status": OrderStatus.canceled.value,
      "notes": newNotes,
    });

    return (canceledOrder, true);
  }

  /// 注文履歴を取得（ページネーション付き）
  Future<Map<String, dynamic>> getOrderHistory(OrderSearchRequest request, String userId) async {
    // すべての注文を取得（基本的なフィルタリング）
    final List<Order> allOrders = await _orderRepository.findByDateRange(
      DateTime.now().subtract(const Duration(days: 365)), // 過去1年間
      DateTime.now(),
      userId,
    );

    List<Order> orders = allOrders;
    final int totalCount = allOrders.length;

    // 手動で日付フィルタリング（リポジトリでサポートされていない場合）
    if (request.dateFrom != null || request.dateTo != null) {
      final List<Order> dateFilteredOrders = <Order>[];
      for (final Order order in orders) {
        if (request.dateFrom != null && order.orderedAt.isBefore(request.dateFrom!)) {
          continue;
        }
        if (request.dateTo != null && order.orderedAt.isAfter(request.dateTo!)) {
          continue;
        }
        dateFilteredOrders.add(order);
      }
      orders = dateFilteredOrders;
    }

    // メニューアイテム名での検索（必要に応じて）
    if (request.menuItemName != null) {
      final List<Order> filteredOrders = <Order>[];
      for (final Order order in orders) {
        final List<OrderItem> items = await _orderItemRepository.findByOrderId(order.id!);
        bool hasMatchingItem = false;

        for (final OrderItem item in items) {
          final dynamic menuItem = await _menuItemRepository.getById(item.menuItemId);
          if (menuItem != null &&
              request.menuItemName!.toLowerCase().contains(
                (menuItem.name as String).toLowerCase(),
              )) {
            hasMatchingItem = true;
            break;
          }
        }

        if (hasMatchingItem) {
          filteredOrders.add(order);
        }
      }
      orders = filteredOrders;
    }

    return <String, dynamic>{
      "orders": orders,
      "total_count": totalCount,
      "page": request.page,
      "limit": request.limit,
      "total_pages": (totalCount + request.limit - 1) ~/ request.limit,
    };
  }

  /// 注文詳細を取得
  Future<Order?> getOrderDetails(String orderId, String userId) async {
    final Order? order = await _orderRepository.getById(orderId);
    if (order == null || order.userId != userId) {
      return null;
    }
    return order;
  }

  /// 注文と注文明細を一括取得
  Future<Map<String, dynamic>?> getOrderWithItems(String orderId, String userId) async {
    final Order? order = await getOrderDetails(orderId, userId);
    if (order == null) {
      return null;
    }

    final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

    // メニューアイテム情報も含める
    final List<Map<String, dynamic>> itemsWithMenu = <Map<String, dynamic>>[];
    for (final OrderItem item in orderItems) {
      final dynamic menuItem = await _menuItemRepository.getById(item.menuItemId);
      itemsWithMenu.add(<String, dynamic>{"order_item": item, "menu_item": menuItem});
    }

    return <String, dynamic>{
      "order": order,
      "items": itemsWithMenu,
      "total_items": orderItems.length,
    };
  }

  /// メニューアイテムの在庫充足を確認
  Future<bool> _checkMenuItemStock(String menuItemId, int quantity, String userId) async {
    // レシピを取得
    final List<dynamic> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

    for (final dynamic recipe in recipes) {
      if (recipe.isOptional as bool) {
        continue;
      }

      // 必要な材料量を計算
      final double requiredAmount = (recipe.requiredAmount as double) * quantity;

      // 材料の在庫を確認
      final dynamic material = await _materialRepository.getById(recipe.materialId as String);
      if (material == null || (material.currentStock as double) < requiredAmount) {
        return false;
      }
    }

    return true;
  }

  /// 注文の金額を計算
  Future<OrderCalculationResult> _calculateOrderTotal(
    String orderId, {
    int discountAmount = 0,
  }) async {
    final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

    final int subtotal = orderItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);
    const double taxRate = 0.08;
    final int taxAmount = (subtotal * taxRate).round();
    final int totalAmount = subtotal + taxAmount - discountAmount;

    return OrderCalculationResult(
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount > 0 ? totalAmount : 0,
    );
  }

  /// 注文に対する材料消費を実行
  Future<void> _consumeMaterialsForOrder(List<OrderItem> orderItems, String userId) async {
    final Map<String, double> materialConsumption = <String, double>{};

    // 必要な材料量を集計
    for (final OrderItem item in orderItems) {
      final List<dynamic> recipes = await _recipeRepository.findByMenuItemId(
        item.menuItemId,
        userId,
      );
      for (final dynamic recipe in recipes) {
        if (!(recipe.isOptional as bool)) {
          final double requiredAmount = (recipe.requiredAmount as double) * item.quantity;
          materialConsumption[recipe.materialId as String] =
              (materialConsumption[recipe.materialId as String] ?? 0.0) + requiredAmount;
        }
      }
    }

    // 材料在庫を消費
    for (final MapEntry<String, double> entry in materialConsumption.entries) {
      final String materialId = entry.key;
      final double consumedAmount = entry.value;

      final dynamic material = await _materialRepository.getById(materialId);
      if (material != null) {
        final double newStock = (material.currentStock as double) - consumedAmount;
        await _materialRepository.updateStockAmount(materialId, newStock, userId);
      }
    }
  }

  /// 注文キャンセル時の材料在庫復元
  Future<void> _restoreMaterialsFromOrder(List<OrderItem> orderItems, String userId) async {
    final Map<String, double> materialRestoration = <String, double>{};

    // 復元する材料量を集計
    for (final OrderItem item in orderItems) {
      final List<dynamic> recipes = await _recipeRepository.findByMenuItemId(
        item.menuItemId,
        userId,
      );
      for (final dynamic recipe in recipes) {
        if (!(recipe.isOptional as bool)) {
          final double restoredAmount = (recipe.requiredAmount as double) * item.quantity;
          materialRestoration[recipe.materialId as String] =
              (materialRestoration[recipe.materialId as String] ?? 0.0) + restoredAmount;
        }
      }
    }

    // 材料在庫を復元
    for (final MapEntry<String, double> entry in materialRestoration.entries) {
      final String materialId = entry.key;
      final double restoredAmount = entry.value;

      final dynamic material = await _materialRepository.getById(materialId);
      if (material != null) {
        final double newStock = (material.currentStock as double) + restoredAmount;
        await _materialRepository.updateStockAmount(materialId, newStock, userId);
      }
    }
  }
}
