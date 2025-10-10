// Removed LoggerComponent mixin; use local tag
import "../../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../../core/contracts/repositories/order/order_repository_contracts.dart";
import "../../dto/order_dto.dart";
import "../../models/order_model.dart";

/// 注文金額計算サービス
class OrderCalculationService {
  OrderCalculationService({
    required log_contract.LoggerContract logger,
    required OrderItemRepositoryContract<OrderItem> orderItemRepository,
    double initialTaxRate = 0.08,
  }) : _logger = logger,
       _orderItemRepository = orderItemRepository,
       _taxRate = initialTaxRate;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final OrderItemRepositoryContract<OrderItem> _orderItemRepository;
  double _taxRate;

  double get taxRate => _taxRate;

  void setBaseTaxRate(double value) {
    final double clamped = value.clamp(0, 1).toDouble();
    if ((_taxRate - clamped).abs() < 0.0001) {
      return;
    }
    _taxRate = clamped;
    log.d("Base tax rate updated: $_taxRate", tag: loggerComponent);
  }

  String get loggerComponent => "OrderCalculationService";

  /// 注文の金額を計算
  Future<OrderCalculationResult> calculateOrderTotal(
    String orderId, {
    int discountAmount = 0,
    List<OrderItem>? preloadedItems,
  }) async {
    log.d(
      "Calculating order total for order: $orderId, discount: $discountAmount",
      tag: loggerComponent,
    );

    try {
      final List<OrderItem> orderItems =
          preloadedItems ?? await _orderItemRepository.findByOrderId(orderId);

      log.d("Retrieved ${orderItems.length} items for calculation", tag: loggerComponent);

      // 小計の計算
      final int subtotal = orderItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);

      final double taxRate = _taxRate;
      final int taxAmount = (subtotal * taxRate).round();

      // 合計金額の計算
      final int totalAmount = subtotal + taxAmount - discountAmount;

      log.d(
        "Order total calculated: subtotal=$subtotal, tax=$taxAmount, total=$totalAmount",
        tag: loggerComponent,
      );

      return OrderCalculationResult(
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount > 0 ? totalAmount : 0, // マイナスにならないように
      );
    } catch (e, stackTrace) {
      log.e("Failed to calculate order total", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// カートの金額を計算（注文計算と同じロジック）
  Future<OrderCalculationResult> calculateCartTotal(
    String cartId, {
    int discountAmount = 0,
    List<OrderItem>? preloadedItems,
  }) async {
    log.d("Calculating cart total with discount: $discountAmount", tag: loggerComponent);
    return calculateOrderTotal(
      cartId,
      discountAmount: discountAmount,
      preloadedItems: preloadedItems,
    );
  }

  /// カートの合計金額を更新（DBに保存）
  Future<int> updateCartTotal(String cartId, {List<OrderItem>? preloadedItems}) async {
    log.d("Updating cart total in database", tag: loggerComponent);

    try {
      final List<OrderItem> cartItems =
          preloadedItems ?? await _orderItemRepository.findByOrderId(cartId);
      final int totalAmount = cartItems.fold(0, (int sum, OrderItem item) => sum + item.subtotal);

      log.d("Cart total updated: $totalAmount", tag: loggerComponent);
      return totalAmount;
    } catch (e, stackTrace) {
      log.e("Failed to update cart total", tag: loggerComponent, error: e, st: stackTrace);
      rethrow;
    }
  }

  /// アイテムの小計を計算
  int calculateItemSubtotal(int unitPrice, int quantity) {
    final int subtotal = unitPrice * quantity;
    log.d(
      "Item subtotal calculated: unitPrice=$unitPrice, quantity=$quantity, subtotal=$subtotal",
      tag: loggerComponent,
    );
    return subtotal;
  }

  /// 税額を計算
  int calculateTaxAmount(int subtotal, {double? taxRate}) {
    final double rate = taxRate ?? _taxRate;
    final int taxAmount = (subtotal * rate).round();
    log.d(
      "Tax amount calculated: subtotal=$subtotal, rate=$taxRate, tax=$taxAmount",
      tag: loggerComponent,
    );
    return taxAmount;
  }
}
