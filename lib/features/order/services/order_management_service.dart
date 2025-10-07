import "../../../core/constants/enums.dart";
import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/contracts/repositories/menu/menu_repository_contracts.dart";
import "../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../../../core/validation/input_validator.dart";
import "../../../infra/logging/context_utils.dart" as log_ctx;
import "../../../infra/logging/logging.dart" show LogFieldsBuilder;
import "../../menu/models/menu_model.dart";
import "../dto/order_dto.dart";
import "../models/order_model.dart";
import "../shared/order_status_mapper.dart";
import "cart_management_service.dart";
import "models/cart_snapshot.dart";
import "order_calculation_service.dart";
import "order_stock_service.dart";

/// 注文管理サービス（基本CRUD・チェックアウト・キャンセル・履歴）
class OrderManagementService {
  OrderManagementService({
    required log_contract.LoggerContract logger,
    required OrderRepositoryContract<Order> orderRepository,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    required MenuItemRepositoryContract<MenuItem> menuItemRepository,
    required OrderCalculationService orderCalculationService,
    required OrderStockService orderStockService,
    required CartManagementService cartManagementService,
  }) : _logger = logger,
       _orderRepository = orderRepository,
       _orderItemRepository = orderItemRepository,
       _menuItemRepository = menuItemRepository,
       _orderCalculationService = orderCalculationService,
       _orderStockService = orderStockService,
       _cartManagementService = cartManagementService;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final OrderRepositoryContract<Order> _orderRepository;
  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  final MenuItemRepositoryContract<MenuItem> _menuItemRepository;
  final OrderCalculationService _orderCalculationService;
  final OrderStockService _orderStockService;
  final CartManagementService _cartManagementService;

  String get loggerComponent => "OrderManagementService";

  /// カートを確定して正式注文に変換（戻り値: (Order, 成功フラグ)）
  Future<OrderCheckoutResult> checkoutCart(
    String cartId,
    OrderCheckoutRequest request,
    String userId,
  ) => log_ctx.traceAsync<OrderCheckoutResult>(
    "order.checkout",
    (log_ctx.LogTrace trace) async {
      final Stopwatch sw = Stopwatch()..start();
      final String? requestId = trace.context[log_ctx.LogContextKeys.requestId] as String?;
      LogFieldsBuilder buildCheckoutFields({String? orderId}) => _buildCheckoutFields(
        cartId: cartId,
        userId: userId,
        orderId: orderId,
      ).withFlow(flowId: trace.flowId, requestId: requestId);

      log.i(
        "Started cart checkout process",
        tag: loggerComponent,
        fields: buildCheckoutFields().started().addMetadata(<String, dynamic>{
          "payment_method": request.paymentMethod.value,
          "discount_amount": request.discountAmount,
        }).build(),
      );

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
          log.e(
            "Validation failed for checkout: ${errorMessages.join(', ')}",
            tag: loggerComponent,
            fields: buildCheckoutFields()
                .failed(reason: "validation_error", durationMs: sw.elapsedMilliseconds)
                .addMetadataEntry("validation_errors", errorMessages)
                .build(),
          );
          throw ValidationException(errorMessages);
        }

        // カートの存在確認
        final Order? cart = await _orderRepository.getById(cartId);
        if (cart == null || cart.userId != userId) {
          log.e(
            "Cart access denied or cart not found",
            tag: loggerComponent,
            fields: buildCheckoutFields()
                .failed(reason: "cart_not_found", durationMs: sw.elapsedMilliseconds)
                .build(),
          );
          throw Exception("Cart $cartId not found or access denied");
        }

        if (OrderStatusMapper.normalize(cart.status) != OrderStatus.inProgress) {
          log.e(
            "Cart is not in preparing status",
            tag: loggerComponent,
            fields: buildCheckoutFields(orderId: cart.id)
                .failed(reason: "invalid_status", durationMs: sw.elapsedMilliseconds)
                .addMetadataEntry("current_status", cart.status.name)
                .build(),
          );
          throw Exception("Cart is not in preparing status");
        }

        // カート内アイテムの取得
        final List<OrderItem> cartItems = await _orderItemRepository.findByOrderId(cartId);
        if (cartItems.isEmpty) {
          log.e(
            "Cannot checkout empty cart",
            tag: loggerComponent,
            fields: buildCheckoutFields(
              orderId: cart.id,
            ).failed(reason: "empty_cart", durationMs: sw.elapsedMilliseconds).build(),
          );
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
          if (sw.isRunning) {
            sw.stop();
          }
          final List<String> insufficientItems = stockValidation.entries
              .where((MapEntry<String, bool> e) => !e.value)
              .map((MapEntry<String, bool> e) => e.key)
              .toList();
          log.w(
            "Checkout failed: insufficient stock for some items",
            tag: loggerComponent,
            fields: buildCheckoutFields(orderId: cart.id)
                .failed(reason: "stock_insufficient", durationMs: sw.elapsedMilliseconds)
                .addMetadataEntry("insufficient_items", insufficientItems)
                .build(),
          );
          return OrderCheckoutResult.stockInsufficient(order: cart);
        }

        log.d("Stock validation passed for all items", tag: loggerComponent);

        // 材料消費の実行
        log.d("Consuming materials for order", tag: loggerComponent);
        await _orderStockService.consumeMaterialsForOrder(cartItems);

        // 注文番号はカート生成時のコードを原則維持し、未設定時のみ生成する
        String orderNumber = cart.orderNumber ?? "";
        if (orderNumber.trim().isEmpty) {
          orderNumber = await _orderRepository.generateNextOrderNumber();
          log.w(
            "Cart had no display code during checkout; generated fallback",
            tag: loggerComponent,
            fields: buildCheckoutFields(
              orderId: cart.id,
            ).addMetadata(<String, dynamic>{"order_number": orderNumber}).build(),
          );
        }
        final DateTime now = DateTime.now();

        final Order? confirmedOrder = await _orderRepository.updateById(cartId, <String, dynamic>{
          "payment_method": request.paymentMethod.value,
          "customer_name": request.customerName,
          "discount_amount": request.discountAmount,
          "notes": request.notes,
          "ordered_at": now.toIso8601String(),
          "status": OrderStatus.inProgress.value,
          "order_number": orderNumber,
          "updated_at": now.toIso8601String(),
          "is_cart": false,
        });

        if (confirmedOrder == null) {
          log.e(
            "Failed to update order during checkout",
            tag: loggerComponent,
            fields: buildCheckoutFields(
              orderId: cart.id,
            ).failed(reason: "update_failed", durationMs: sw.elapsedMilliseconds).build(),
          );
          throw Exception("Failed to confirm order during checkout");
        }

        // 最終金額を計算して更新
        final OrderCalculationResult calculation = await _orderCalculationService
            .calculateOrderTotal(
              cartId,
              discountAmount: request.discountAmount,
              preloadedItems: cartItems,
            );
        final Order? recalculatedOrder = await _orderRepository.updateById(
          cartId,
          <String, dynamic>{"total_amount": calculation.totalAmount},
        );

        final Order finalizedOrder = recalculatedOrder ?? confirmedOrder;

        final Order? nextCart = await _cartManagementService.getOrCreateActiveCart(userId);

        if (sw.isRunning) {
          sw.stop();
        }
        log.i(
          "Cart checkout completed successfully: totalAmount=${calculation.totalAmount}",
          tag: loggerComponent,
          fields: buildCheckoutFields(orderId: finalizedOrder.id)
              .succeeded(durationMs: sw.elapsedMilliseconds)
              .addMetadata(<String, dynamic>{
                "total_amount": calculation.totalAmount,
                "discount_amount": request.discountAmount,
                "order_number": finalizedOrder.orderNumber,
              })
              .build(),
        );
        return OrderCheckoutResult.success(order: finalizedOrder, newCart: nextCart);
      } catch (e, stackTrace) {
        if (sw.isRunning) {
          sw.stop();
        }
        log.e(
          "Cart checkout failed",
          tag: loggerComponent,
          error: e,
          st: stackTrace,
          fields: buildCheckoutFields()
              .failed(reason: e.runtimeType.toString(), durationMs: sw.elapsedMilliseconds)
              .addMetadataEntry("message", e.toString())
              .build(),
        );
        rethrow;
      }
    },
    attributes: <String, Object?>{
      log_ctx.LogContextKeys.source: loggerComponent,
      log_ctx.LogContextKeys.operation: "order.checkout",
      log_ctx.LogContextKeys.userId: userId,
    },
  );

  /// 注文をキャンセル（在庫復元含む）
  Future<(Order?, bool)> cancelOrder(String orderId, String reason, String userId) async {
    final Stopwatch sw = Stopwatch()..start();
    LogFieldsBuilder cancelFields() => _buildCancellationFields(orderId: orderId, userId: userId);

    log.i(
      "Started order cancellation process",
      tag: loggerComponent,
      fields: cancelFields().started().addMetadataEntry("reason", reason).build(),
    );

    try {
      // 注文の存在確認
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e(
          "Order access denied or order not found",
          tag: loggerComponent,
          fields: cancelFields()
              .failed(reason: "order_not_found", durationMs: sw.elapsedMilliseconds)
              .build(),
        );
        throw Exception("Order $orderId not found or access denied");
      }

      if (OrderStatusMapper.normalize(order.status) == OrderStatus.cancelled) {
        if (sw.isRunning) {
          sw.stop();
        }
        log.w(
          "Order already canceled",
          tag: loggerComponent,
          fields: cancelFields().cancelled(reason: "already_cancelled").build(),
        );
        return (order, false); // 既にキャンセル済み
      }

      if (OrderStatusMapper.normalize(order.status) == OrderStatus.completed) {
        log.e(
          "Cannot cancel completed order",
          tag: loggerComponent,
          fields: cancelFields()
              .failed(reason: "completed_order", durationMs: sw.elapsedMilliseconds)
              .build(),
        );
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

      if (sw.isRunning) {
        sw.stop();
      }
      log.i(
        "Order canceled successfully",
        tag: loggerComponent,
        fields: cancelFields()
            .succeeded(durationMs: sw.elapsedMilliseconds)
            .addMetadataEntry("notes_updated", order.notes != newNotes)
            .build(),
      );
      return (canceledOrder, true);
    } catch (e, stackTrace) {
      if (sw.isRunning) {
        sw.stop();
      }
      log.e(
        "Order cancellation failed",
        tag: loggerComponent,
        error: e,
        st: stackTrace,
        fields: cancelFields()
            .failed(reason: e.runtimeType.toString(), durationMs: sw.elapsedMilliseconds)
            .addMetadataEntry("message", e.toString())
            .build(),
      );
      rethrow;
    }
  }

  LogFieldsBuilder _buildCheckoutFields({
    required String cartId,
    required String userId,
    String? orderId,
  }) => LogFieldsBuilder.operation("order.checkout")
      .withActor(userId: userId)
      .withResource(type: orderId == null ? "cart" : "order", id: orderId ?? cartId)
      .addMetadata(<String, dynamic>{"cart_id": cartId, if (orderId != null) "order_id": orderId});

  LogFieldsBuilder _buildCancellationFields({required String orderId, required String userId}) =>
      LogFieldsBuilder.operation("order.cancel")
          .withActor(userId: userId)
          .withResource(type: "order", id: orderId)
          .addMetadata(<String, dynamic>{"order_id": orderId});

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

      List<Order> orders = allOrders.where((Order order) => !order.isCart).toList();
      final int totalCount = orders.length;

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
      final CartSnapshotData? snapshot = await _cartManagementService.loadCartSnapshot(
        orderId,
        userId,
      );

      if (snapshot == null) {
        log.w("Order not found for order with items retrieval", tag: loggerComponent);
        return null;
      }

      final Map<String, MenuItem> menuIndex = <String, MenuItem>{
        for (final MenuItem menu in snapshot.menuItems)
          if (menu.id != null) menu.id!: menu,
      };

      final List<Map<String, dynamic>> itemsWithMenu = snapshot.orderItems
          .map(
            (OrderItem item) => <String, dynamic>{
              "order_item": item,
              "menu_item": menuIndex[item.menuItemId],
            },
          )
          .toList(growable: false);

      log.d(
        "Order with items retrieval completed successfully",
        tag: loggerComponent,
        fields: <String, Object?>{"items": snapshot.orderItems.length},
      );

      return <String, dynamic>{
        "order": snapshot.order,
        "items": itemsWithMenu,
        "total_items": snapshot.orderItems.length,
      };
    } catch (e, stackTrace) {
      log.e("Failed to retrieve order with items", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 指定ステータスの注文を取得する。
  Future<Map<OrderStatus, List<Order>>> getOrdersByStatuses(
    List<OrderStatus> statuses,
    String userId, {
    int limit = 50,
  }) async {
    log.d(
      "Fetching orders by statuses",
      tag: loggerComponent,
      fields: <String, dynamic>{"statuses": statuses.map((OrderStatus s) => s.name).toList()},
    );

    if (statuses.isEmpty) {
      return <OrderStatus, List<Order>>{};
    }

    try {
      final List<OrderStatus> normalizedStatuses = OrderStatusMapper.normalizeList(statuses);
      final List<Order> orders = await _orderRepository.findByStatusList(normalizedStatuses);
      final Map<OrderStatus, List<Order>> grouped = <OrderStatus, List<Order>>{
        for (final OrderStatus status in normalizedStatuses) status: <Order>[],
      };

      for (final Order order in orders) {
        if (order.userId != userId) {
          continue;
        }
        if (order.isCart) {
          continue;
        }
        final OrderStatus normalizedStatus = OrderStatusMapper.normalize(order.status);
        if (!grouped.containsKey(normalizedStatus)) {
          continue;
        }
        grouped[normalizedStatus]!.add(order);
      }

      final Map<OrderStatus, List<Order>> limited = <OrderStatus, List<Order>>{};
      for (final OrderStatus status in grouped.keys) {
        final List<Order> list = grouped[status] ?? <Order>[];
        limited[status] = list.take(limit).toList();
      }

      return limited;
    } catch (e, stackTrace) {
      log.e("Failed to fetch orders by statuses", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// 注文ステータスを更新する。
  Future<Order?> updateOrderStatus(String orderId, OrderStatus newStatus, String userId) async {
    log.i(
      "Updating order status",
      tag: loggerComponent,
      fields: <String, dynamic>{"orderId": orderId, "newStatus": newStatus.name},
    );

    final OrderStatus targetStatus = OrderStatusMapper.normalize(newStatus);
    if (targetStatus != OrderStatus.inProgress && targetStatus != OrderStatus.completed) {
      log.e("Unsupported status update requested", tag: loggerComponent);
      throw OrderException.invalidOrderStatus(newStatus.value, "in_progress/completed only");
    }

    try {
      final Order? order = await _orderRepository.getById(orderId);
      if (order == null || order.userId != userId) {
        log.e("Order access denied or not found", tag: loggerComponent);
        throw OrderException.orderNotFound(orderId);
      }

      if (OrderStatusMapper.normalize(order.status) == targetStatus) {
        log.d("Order already in requested status", tag: loggerComponent);
        return order;
      }

      if (targetStatus == OrderStatus.completed) {
        final OrderStatus currentStatus = OrderStatusMapper.normalize(order.status);
        if (currentStatus == OrderStatus.cancelled) {
          log.e("Cannot complete canceled/refunded order", tag: loggerComponent);
          throw OrderException.invalidOrderStatus(order.status.value, targetStatus.value);
        }

        final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
          "status": OrderStatus.completed.value,
          "completed_at": DateTime.now().toIso8601String(),
        });

        log.i("Order marked as completed", tag: loggerComponent);
        return updatedOrder;
      }

      // targetStatus == OrderStatus.inProgress
      final Order? updatedOrder = await _orderRepository.updateById(orderId, <String, dynamic>{
        "status": OrderStatus.inProgress.value,
        "completed_at": null,
      });

      log.i("Order reverted to in_progress", tag: loggerComponent);
      return updatedOrder;
    } catch (e, stackTrace) {
      log.e("Failed to update order status", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }
}
