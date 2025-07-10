import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../../inventory/models/inventory_model.dart";
import "../../inventory/repositories/material_repository.dart";
import "../../inventory/repositories/recipe_repository.dart";
import "../../menu/models/menu_model.dart";
import "../../menu/repositories/menu_item_repository.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../repositories/order_item_repository.dart";
import "../repositories/order_repository.dart";

class OrderService with LoggerMixin {
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

  @override
  String get loggerComponent => "OrderService";
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
    logInfo("Started cart checkout process");

    try {
      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        logError("Cart access denied or cart not found");
        throw Exception("Cart $cartId not found or access denied");
      }

      if (cart.status != OrderStatus.preparing) {
        logError("Cart is not in preparing status");
        throw Exception("Cart is not in preparing status");
      }

      // カート内アイテムの取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
      if (cartItems.isEmpty) {
        logError("Cannot checkout empty cart");
        throw Exception("Cart is empty");
      }

      logDebug("Cart contains ${cartItems.length} items for checkout");

      // 在庫確認
      logDebug("Starting stock validation for checkout");
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
        logWarning("Checkout failed: insufficient stock for some items");
        return (cart, false);
      }

      logDebug("Stock validation passed for all items");

      // 材料消費の実行
      logDebug("Consuming materials for order");
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

      logInfo("Cart checkout completed successfully: totalAmount=${calculation.totalAmount}");
      return (updatedOrder, true);
    } catch (e, stackTrace) {
      logError("Cart checkout failed", e, stackTrace);
      rethrow;
    }
  }

  /// 注文をキャンセル（在庫復元含む）
  Future<(Order?, bool)> cancelOrder(String orderId, String reason, String userId) async {
    logInfo("Started order cancellation process");

    try {
      // 注文の存在確認
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        logError("Order access denied or order not found");
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.status == OrderStatus.canceled) {
        logWarning("Order already canceled");
        return (order, false); // 既にキャンセル済み
      }

      if (order.status == OrderStatus.completed) {
        logError("Cannot cancel completed order");
        throw Exception("Cannot cancel completed order");
      }

      logDebug("Order cancellation validated: status=${order.status.name}");

      // 材料在庫を復元（まだ調理開始前の場合のみ）
      if (order.startedPreparingAt == null) {
        logDebug("Restoring materials for canceled order");
        final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);
        await _restoreMaterialsFromOrder(orderItems, userId);
        logDebug("Materials restored successfully");
      } else {
        logInfo("Order already started preparation: materials not restored");
      }

      // 注文をキャンセル状態に更新
      final String newNotes = "${order.notes ?? ""} [CANCELED: $reason]".trim();
      final Order? canceledOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "status": OrderStatus.canceled.value,
        "notes": newNotes,
      });

      logInfo("Order canceled successfully");
      return (canceledOrder, true);
    } catch (e, stackTrace) {
      logError("Order cancellation failed", e, stackTrace);
      rethrow;
    }
  }

  /// 注文履歴を取得（ページネーション付き）
  Future<Map<String, dynamic>> getOrderHistory(OrderSearchRequest request, String userId) async {
    logInfo("Started retrieving order history");

    try {
      // すべての注文を取得（基本的なフィルタリング）
      final List<Order> allOrders = await _orderRepository.findByDateRange(
        DateTime.now().subtract(const Duration(days: 365)), // 過去1年間
        DateTime.now(),
        userId,
      );

      logDebug("Retrieved ${allOrders.length} orders from repository");

      List<Order> orders = allOrders;
      final int totalCount = allOrders.length;

      // 手動で日付フィルタリング（リポジトリでサポートされていない場合）
      if (request.dateFrom != null || request.dateTo != null) {
        logDebug("Applying date range filter");
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
        logDebug("Date filter applied: ${orders.length} orders remaining");
      }

      // メニューアイテム名での検索（必要に応じて）
      if (request.menuItemName != null) {
        logDebug("Applying menu item name filter");
        final List<Order> filteredOrders = <Order>[];
        for (final Order order in orders) {
          final List<OrderItem> items = await _orderItemRepository.findByOrderId(order.id!);
          bool hasMatchingItem = false;

          for (final OrderItem item in items) {
            final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
            if (menuItem != null &&
                request.menuItemName!.toLowerCase().contains(menuItem.name.toLowerCase())) {
              hasMatchingItem = true;
              break;
            }
          }

          if (hasMatchingItem) {
            filteredOrders.add(order);
          }
        }
        orders = filteredOrders;
        logDebug("Menu item filter applied: ${orders.length} orders remaining");
      }

      logInfo("Order history retrieval completed: ${orders.length} orders found");

      return <String, dynamic>{
        "orders": orders,
        "total_count": totalCount,
        "page": request.page,
        "limit": request.limit,
        "total_pages": (totalCount + request.limit - 1) ~/ request.limit,
      };
    } catch (e, stackTrace) {
      logError("Failed to retrieve order history", e, stackTrace);
      rethrow;
    }
  }

  /// 注文詳細を取得
  Future<Order?> getOrderDetails(String orderId, String userId) async {
    logDebug("Retrieving order details");

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        logWarning("Order access denied or order not found");
        return null;
      }

      logDebug("Order details retrieved successfully");
      return order;
    } catch (e, stackTrace) {
      logError("Failed to retrieve order details", e, stackTrace);
      rethrow;
    }
  }

  /// 注文と注文明細を一括取得
  Future<Map<String, dynamic>?> getOrderWithItems(String orderId, String userId) async {
    logDebug("Retrieving order with items");

    try {
      final Order? order = await getOrderDetails(orderId, userId);
      if (order == null) {
        logWarning("Order not found for order with items retrieval");
        return null;
      }

      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

      logDebug("Retrieved ${orderItems.length} order items");

      // メニューアイテム情報も含める
      final List<Map<String, dynamic>> itemsWithMenu = <Map<String, dynamic>>[];
      for (final OrderItem item in orderItems) {
        final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
        itemsWithMenu.add(<String, dynamic>{"order_item": item, "menu_item": menuItem});
      }

      logDebug("Order with items retrieval completed successfully");

      return <String, dynamic>{
        "order": order,
        "items": itemsWithMenu,
        "total_items": orderItems.length,
      };
    } catch (e, stackTrace) {
      logError("Failed to retrieve order with items", e, stackTrace);
      rethrow;
    }
  }

  /// メニューアイテムの在庫充足を確認
  Future<bool> _checkMenuItemStock(String menuItemId, int quantity, String userId) async {
    // レシピを取得
    final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(menuItemId, userId);

    for (final Recipe recipe in recipes) {
      if (recipe.isOptional) {
        continue;
      }

      // 必要な材料量を計算
      final double requiredAmount = recipe.requiredAmount * quantity;

      // 材料の在庫を確認
      final Material? material = await _materialRepository.getById(recipe.materialId);
      if (material == null || material.currentStock < requiredAmount) {
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
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(
        item.menuItemId,
        userId,
      );
      for (final Recipe recipe in recipes) {
        if (!recipe.isOptional) {
          final double requiredAmount = recipe.requiredAmount * item.quantity;
          materialConsumption[recipe.materialId] =
              (materialConsumption[recipe.materialId] ?? 0.0) + requiredAmount;
        }
      }
    }

    // 材料在庫を消費
    for (final MapEntry<String, double> entry in materialConsumption.entries) {
      final String materialId = entry.key;
      final double consumedAmount = entry.value;

      final Material? material = await _materialRepository.getById(materialId);
      if (material != null) {
        final double newStock = material.currentStock - consumedAmount;
        await _materialRepository.updateStockAmount(materialId, newStock, userId);
      }
    }
  }

  /// 注文キャンセル時の材料在庫復元
  Future<void> _restoreMaterialsFromOrder(List<OrderItem> orderItems, String userId) async {
    final Map<String, double> materialRestoration = <String, double>{};

    // 復元する材料量を集計
    for (final OrderItem item in orderItems) {
      final List<Recipe> recipes = await _recipeRepository.findByMenuItemId(
        item.menuItemId,
        userId,
      );
      for (final Recipe recipe in recipes) {
        if (!recipe.isOptional) {
          final double restoredAmount = recipe.requiredAmount * item.quantity;
          materialRestoration[recipe.materialId] =
              (materialRestoration[recipe.materialId] ?? 0.0) + restoredAmount;
        }
      }
    }

    // 材料在庫を復元
    for (final MapEntry<String, double> entry in materialRestoration.entries) {
      final String materialId = entry.key;
      final double restoredAmount = entry.value;

      final Material? material = await _materialRepository.getById(materialId);
      if (material != null) {
        final double newStock = material.currentStock + restoredAmount;
        await _materialRepository.updateStockAmount(materialId, newStock, userId);
      }
    }
  }
}
