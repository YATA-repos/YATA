part of "order_management_controller.dart";

mixin CheckoutController on _OrderManagementControllerBase {
  /// 支払い方法を更新する。
  @override
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "update_payment_method",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{
        "requested_method": method.name,
        "current_method": state.currentPaymentMethod.name,
      },
      message: "注文管理 支払い方法更新を開始",
    );

    if (state.isCheckoutInProgress || state.isLoading) {
      logSession.cancelled(message: "処理実行中のため支払い方法を更新できません", reason: "busy_state");
      return;
    }
    if (method == state.currentPaymentMethod) {
      logSession.cancelled(message: "支払い方法が既に選択済みのため変更なし", reason: "no_change");
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(message: "支払い方法の更新に失敗（ユーザー未認証）", reason: "missing_user");
      return;
    }

    final PaymentMethod previous = state.currentPaymentMethod;

    String? cartId = state.cartId;
    cartId ??= await _ensureCart(userId);
    if (cartId == null) {
      state = state.copyWith(
        currentPaymentMethod: previous,
        errorMessage: "カート情報を取得できませんでした。再度お試しください。",
      );
      logSession.failed(message: "支払い方法の更新に失敗（カート未取得）", reason: "cart_unavailable");
      return;
    }
    logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

    state = state.copyWith(currentPaymentMethod: method, clearErrorMessage: true);

    try {
      await _cartManagementService.updateCartPaymentMethod(cartId, method, userId);
      logSession.succeeded(
        message: "支払い方法を更新しました",
        metadata: <String, dynamic>{"applied_method": method.name},
      );
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(currentPaymentMethod: previous, errorMessage: message);
      logSession.failed(
        message: "支払い方法の更新でエラーが発生",
        reason: "update_payment_failed",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// カートを会計処理する。
  @override
  Future<CheckoutActionResult> checkout() async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "checkout",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{
        "cart_item_count": state.cartItems.length,
        "discount_amount": state.discountAmount,
        "payment_method": state.currentPaymentMethod.name,
      },
      message: "注文管理 会計処理を開始",
    );

    if (state.isCheckoutInProgress) {
      logSession.cancelled(message: "会計処理がすでに進行中のため新たな処理を開始しません", reason: "checkout_in_progress");
      return CheckoutActionResult.failure(message: "会計処理中です。");
    }

    if (state.cartItems.isEmpty) {
      logSession.cancelled(message: "カートが空のため会計処理を実行しません", reason: "empty_cart");
      return CheckoutActionResult.emptyCart(message: "カートに商品がありません。");
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(message: "会計処理に失敗（ユーザー未認証）", reason: "missing_user");
      return CheckoutActionResult.authenticationFailed(message: "ユーザー情報を取得できませんでした。再度ログインしてください。");
    }

    state = state.copyWith(isCheckoutInProgress: true, clearErrorMessage: true);

    try {
      String? cartId = state.cartId;
      cartId ??= await _ensureCart(userId);
      if (cartId == null) {
        state = state.copyWith(isCheckoutInProgress: false);
        logSession.failed(message: "会計処理に失敗（カート未取得）", reason: "cart_unavailable");
        return CheckoutActionResult.missingCart(message: "カート情報の取得に失敗しました。");
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      final OrderCheckoutRequest request = OrderCheckoutRequest(
        paymentMethod: state.currentPaymentMethod,
        discountAmount: state.discountAmount,
        notes: state.orderNotes.isEmpty ? null : state.orderNotes,
      );

    final OrderCheckoutResult result =
      await _orderManagementService.checkoutCart(cartId, request, userId);

      if (!result.isSuccess || result.isStockInsufficient) {
        const String message = "在庫が不足している商品があります。数量を調整して再度お試しください。";
        state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
        logSession.failed(
          message: "会計処理に失敗（在庫不足）",
          reason: "stock_insufficient",
          metadata: <String, dynamic>{"order_id": result.order.id, "insufficient": true},
        );
        return CheckoutActionResult.stockInsufficient(result.order, message: message);
      }

      final Order? newCart = result.newCart;
      if (newCart == null) {
        const String message = "新しいカートの初期化に失敗しました。";
        state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
        logSession.failed(
          message: "会計処理に失敗（カート初期化）",
          reason: "new_cart_init_failed",
          metadata: <String, dynamic>{"order_id": result.order.id},
        );
        return CheckoutActionResult.failure(order: result.order, message: message);
      }

      state = state.copyWith(
        isCheckoutInProgress: false,
        cartItems: const <CartItemViewData>[],
        cartId: newCart.id,
        orderNumber: newCart.orderNumber,
        discountAmount: newCart.discountAmount,
        currentPaymentMethod: newCart.paymentMethod,
        clearHighlightedItemId: true,
        clearErrorMessage: true,
        orderNotes: "",
      );

      await loadInitialData(reset: true);

      logSession.succeeded(
        message: "会計処理が完了しました",
        metadata: <String, dynamic>{
          "order_id": result.order.id,
          "order_number": result.order.orderNumber,
          "next_cart_id": newCart.id,
        },
      );

      return CheckoutActionResult.success(result.order);
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(isCheckoutInProgress: false, errorMessage: message);
      logSession.failed(
        message: "会計処理で例外が発生",
        reason: "checkout_exception",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
      return CheckoutActionResult.failure(message: message);
    }
  }

  /// 注文メモを更新する。
  @override
  void updateOrderNotes(String notes) {
    final String previous = state.orderNotes;
    _traceSyncSection<void>(
      "updateOrderNotes",
      () {
        if (notes == previous) {
          _logPerfLazy(() => "updateOrderNotes.skip length=${notes.length}");
          return;
        }
        state = state.copyWith(orderNotes: notes, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{
        "previousLength": previous.length,
        "nextLength": notes.length,
      },
      finishArguments: () => <String, dynamic>{"changed": previous != state.orderNotes},
      logThreshold: const Duration(milliseconds: 1),
    );
  }
}
