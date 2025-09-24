import "../../../core/constants/enums.dart";
import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
// Removed LoggerComponent mixin; use local tag
import "../../../core/logging/compat.dart" as log;
import "../../../core/validation/input_validator.dart";
import "../../menu/models/menu_model.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "order_calculation_service.dart";
import "order_stock_service.dart";

/// 注文管理サービス（基本CRUD・チェックアウト・キャンセル・履歴）
class OrderManagementService {
  OrderManagementService({
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required OrderCalculationService orderCalculationService,
    required OrderStockService orderStockService,
  }) : _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _menuItemRepository = menuItemRepository,
       _orderCalculationService = orderCalculationService,
       _orderStockService = orderStockService;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
  final OrderCalculationService _orderCalculationService;
  final OrderStockService _orderStockService;

  String get loggerComponent => "OrderManagementService";

  /// カートを確定して正式注文に変換（戻り値: (Order, 成功フラグ)）
  Future<(Order?, bool)> checkoutCart(
    String cartId,
    OrderCheckoutRequest request,
    String userId,
  ) async {
    log.i("Started cart checkout process", tag: loggerComponent);

    try {
      // 入力検証
      final List<ValidationResult> validationResults = <ValidationResult>[
        InputValidator.validateString(cartId, required: true, fieldName: "カートID"),
        InputValidator.validateString(userId, required: true, fieldName: "ユーザーID"),
        InputValidator.validateString(request.customerName, maxLength: 100, fieldName: "顧客名"),
        InputValidator.validateNumber(request.discountAmount, min: 0, fieldName: "割引金額"),
      ];

      final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
      if (errors.isNotEmpty) {
        final List<String> errorMessages = InputValidator.getErrorMessages(errors);
        log.e("Validation failed for checkout: ${errorMessages.join(', ')}", tag: loggerComponent);
        throw ValidationException(errorMessages);
      }

      // カートの存在確認
      final Order? cart = await _orderRepository.getById(cartId);
      if (cart == null || cart.userId != userId) {
        log.e("Cart access denied or cart not found", tag: loggerComponent);
        throw Exception("Cart $cartId not found or access denied");
      }

      if (cart.status != OrderStatus.preparing) {
        log.e("Cart is not in preparing status", tag: loggerComponent);
        throw Exception("Cart is not in preparing status");
      }

      // カート内アイテムの取得
      final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
      if (cartItems.isEmpty) {
        log.e("Cannot checkout empty cart", tag: loggerComponent);
        throw Exception("Cart is empty");
      }

      log.d("Cart contains ${cartItems.length} items for checkout", tag: loggerComponent);

      // 在庫確認
      log.d("Starting stock validation for checkout", tag: loggerComponent);
      final Map<String, bool> stockValidation = await _orderStockService.validateCartStock(
        cartItems,
      );

      final bool allSufficient = stockValidation.values.every((bool sufficient) => sufficient);

      if (!allSufficient) {
        log.w("Checkout failed: insufficient stock for some items", tag: loggerComponent);
        return (cart, false);
      }

      log.d("Stock validation passed for all items", tag: loggerComponent);

      // 材料消費の実行
      log.d("Consuming materials for order", tag: loggerComponent);
      await _orderStockService.consumeMaterialsForOrder(cartItems);

      // 注文の確定
      // 注文番号生成（将来の使用のため）
      await _orderRepository.generateNextOrderNumber();

      final Order? updatedOrder = await _orderRepository.updateById(cartId, <String, dynamic>{
        "payment_method": request.paymentMethod.value,
        "customer_name": request.customerName,
        "discount_amount": request.discountAmount,
        "notes": request.notes,
        "ordered_at": DateTime.now().toIso8601String(),
        "status": OrderStatus.preparing.value,
      });

      // 最終金額を計算して更新
      final OrderCalculationResult calculation = await _orderCalculationService.calculateOrderTotal(
        cartId,
        discountAmount: request.discountAmount,
      );
      await _orderRepository.updateById(cartId, <String, dynamic>{
        "total_amount": calculation.totalAmount,
      });

      log.i(
        "Cart checkout completed successfully: totalAmount=${calculation.totalAmount}",
        tag: loggerComponent,
      );
      return (updatedOrder, true);
    } catch (e, stackTrace) {
      log.e("Cart checkout failed", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文をキャンセル（在庫復元含む）
  Future<(Order?, bool)> cancelOrder(String orderId, String reason, String userId) async {
    log.i("Started order cancellation process", tag: loggerComponent);

    try {
      // 注文の存在確認
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e("Order access denied or order not found", tag: loggerComponent);
        throw Exception("Order $orderId not found or access denied");
      }

      if (order.status == OrderStatus.cancelled) {
        log.w("Order already canceled", tag: loggerComponent);
        return (order, false); // 既にキャンセル済み
      }

      if (order.status == OrderStatus.completed) {
        log.e("Cannot cancel completed order", tag: loggerComponent);
        throw Exception("Cannot cancel completed order");
      }

      log.d("Order cancellation validated: status=${order.status.name}", tag: loggerComponent);

      // 材料在庫を復元（まだ調理開始前の場合のみ）
      if (order.startedPreparingAt == null) {
        log.d("Restoring materials for canceled order", tag: loggerComponent);
        final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);
        await _orderStockService.restoreMaterialsFromOrder(orderItems);
        log.d("Materials restored successfully", tag: loggerComponent);
      } else {
        log.i("Order already started preparation: materials not restored", tag: loggerComponent);
      }

      // 注文をキャンセル状態に更新
      final String newNotes = "${order.notes ?? ""} [CANCELED: $reason]".trim();
      final Order? canceledOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "status": OrderStatus.cancelled.value,
        "notes": newNotes,
      });

      log.i("Order canceled successfully", tag: loggerComponent);
      return (canceledOrder, true);
    } catch (e, stackTrace) {
      log.e("Order cancellation failed", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文履歴を取得（ページネーション付き）
  Future<Map<String, dynamic>> getOrderHistory(OrderSearchRequest request, String userId) async {
    log.i("Started retrieving order history", tag: loggerComponent);

    try {
      // すべての注文を取得（基本的なフィルタリング）
      final List<Order> allOrders = await _orderRepository.findByDateRange(
        DateTime.now().subtract(const Duration(days: 365)), // 過去1年間
        DateTime.now(),
      );

      log.d("Retrieved ${allOrders.length} orders from repository", tag: loggerComponent);

      List<Order> orders = allOrders;
      final int totalCount = allOrders.length;

      // 手動で日付フィルタリング（リポジトリでサポートされていない場合）
      if (request.dateFrom != null || request.dateTo != null) {
        log.d("Applying date range filter", tag: loggerComponent);
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
        log.d("Date filter applied: ${orders.length} orders remaining", tag: loggerComponent);
      }

      // メニューアイテム名での検索（必要に応じて）
      if (request.menuItemName != null) {
        log.d("Applying menu item name filter", tag: loggerComponent);
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
        log.d("Menu item filter applied: ${orders.length} orders remaining", tag: loggerComponent);
      }

      log.i(
        "Order history retrieval completed: ${orders.length} orders found",
        tag: loggerComponent,
      );

      return <String, dynamic>{
        "orders": orders,
        "total_count": totalCount,
        "page": request.page,
        "limit": request.limit,
        "total_pages": (totalCount + request.limit - 1) ~/ request.limit,
      };
    } catch (e, stackTrace) {
      log.e("Failed to retrieve order history", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文詳細を取得
  Future<Order?> getOrderDetails(String orderId, String userId) async {
    log.d("Retrieving order details", tag: loggerComponent);

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.w("Order access denied or order not found", tag: loggerComponent);
        return null;
      }

      log.d("Order details retrieved successfully", tag: loggerComponent);
      return order;
    } catch (e, stackTrace) {
      log.e("Failed to retrieve order details", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文と注文明細を一括取得
  Future<Map<String, dynamic>?> getOrderWithItems(String orderId, String userId) async {
    log.d("Retrieving order with items", tag: loggerComponent);

    try {
      final Order? order = await getOrderDetails(orderId, userId);
      if (order == null) {
        log.w("Order not found for order with items retrieval", tag: loggerComponent);
        return null;
      }

      final List<OrderItem> orderItems = await _orderItemRepository.findByOrderId(orderId);

      log.d("Retrieved ${orderItems.length} order items", tag: loggerComponent);

      // メニューアイテム情報も含める
      final List<Map<String, dynamic>> itemsWithMenu = <Map<String, dynamic>>[];
      for (final OrderItem item in orderItems) {
        final MenuItem? menuItem = await _menuItemRepository.getById(item.menuItemId);
        itemsWithMenu.add(<String, dynamic>{"order_item": item, "menu_item": menuItem});
      }

      log.d("Order with items retrieval completed successfully", tag: loggerComponent);

      return <String, dynamic>{
        "order": order,
        "items": itemsWithMenu,
        "total_items": orderItems.length,
      };
    } catch (e, stackTrace) {
      log.e("Failed to retrieve order with items", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }
}
