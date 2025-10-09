part of "order_management_controller.dart";

mixin CartOperationController on _OrderManagementControllerBase {
  /// メニューをカートへ追加する。
  @override
  void addMenuItem(String menuItemId) => unawaited(_addMenuItem(menuItemId));

  Future<void> _addMenuItem(String menuItemId) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "add_menu_item",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"menu_item_id": menuItemId},
      message: "注文管理 カート追加を開始",
    );

    await _traceAsyncSection<void>("addMenuItem", () async {
      if (state.isCheckoutInProgress) {
        _logPerfLazy(() => "addMenuItem.skip checkoutInProgress item=$menuItemId");
        logSession.cancelled(message: "会計処理中のためカート追加を中断", reason: "checkout_in_progress");
        return;
      }
      final String? userId = _ensureUserId();
      if (userId == null) {
        logSession.failed(message: "カート追加に失敗（ユーザー未認証）", reason: "missing_user");
        return;
      }

      final MenuItemViewData? menuItem = _menuItemCache[menuItemId] ?? _findMenuItem(menuItemId);
      if (menuItem == null) {
        state = state.copyWith(errorMessage: "選択したメニューが見つかりませんでした。");
        logSession.failed(message: "カート追加に失敗（メニュー未検出）", reason: "menu_item_not_found");
        return;
      }

      final String? cartId = await _ensureCart(userId);
      if (cartId == null) {
        logSession.failed(message: "カート追加に失敗（カート未取得）", reason: "cart_unavailable");
        return;
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      try {
        state = state.copyWith(clearErrorMessage: true);
        final CartMutationResult result = await _traceAsyncSection<CartMutationResult>(
          "addMenuItem.addItemToCart",
          () => _cartManagementService.addItemToCart(
            cartId,
            CartItemRequest(menuItemId: menuItemId, quantity: 1),
            userId,
          ),
          startArguments: () => <String, dynamic>{"cartId": cartId, "menuItemId": menuItemId},
          logThreshold: const Duration(milliseconds: 4),
        );
        _applyCartMutationResult(result);
        final String highlightTarget = result.highlightMenuItemId ?? menuItemId;
        _triggerHighlight(highlightTarget);

        logSession.succeeded(
          message: "カートにメニューを追加しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": result.kind.name,
            "stock_warning": result.hasStockIssue,
          },
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(errorMessage: message);
        logSession.failed(
          message: "カート追加でエラーが発生",
          reason: "add_item_failed",
          metadata: <String, dynamic>{"error_message": message},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "addMenuItem.error item=$menuItemId message=$message");
      }
    }, startArguments: () => <String, dynamic>{"menuItemId": menuItemId});
  }

  /// カート内アイテムの数量を更新する。
  @override
  void updateItemQuantity(String menuItemId, int quantity) =>
      unawaited(_updateItemQuantity(menuItemId, quantity));

  Future<void> _updateItemQuantity(String menuItemId, int quantity) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "update_item_quantity",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"menu_item_id": menuItemId, "requested_quantity": quantity},
      message: "注文管理 カート数量更新を開始",
    );

    await _traceAsyncSection<void>(
      "updateItemQuantity",
      () async {
        if (state.isCheckoutInProgress) {
          _logPerfLazy(
            () => "updateItemQuantity.skip checkoutInProgress item=$menuItemId quantity=$quantity",
          );
          logSession.cancelled(message: "会計処理中のため数量更新を中断", reason: "checkout_in_progress");
          return;
        }
        final String? userId = _ensureUserId();
        if (userId == null) {
          logSession.failed(message: "数量更新に失敗（ユーザー未認証）", reason: "missing_user");
          return;
        }

        final String? cartId = state.cartId ?? await _ensureCart(userId);
        if (cartId == null) {
          logSession.failed(message: "数量更新に失敗（カート未取得）", reason: "cart_unavailable");
          return;
        }
        logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

        final CartItemViewData? target = state.cartItemByMenuId[menuItemId];
        final String? orderItemId = target?.orderItemId;

        if (target == null || orderItemId == null) {
          if (quantity > 0) {
            logSession.cancelled(message: "数量更新対象が見つからないため追加処理へフォールバック", reason: "fallback_to_add");
            await _addMenuItem(menuItemId);
          } else {
            logSession.cancelled(message: "削除対象が見つからないためスキップ", reason: "missing_target");
          }
          return;
        }

        try {
          state = state.copyWith(clearErrorMessage: true);
          late final CartMutationResult result;
          if (quantity <= 0) {
            result = await _traceAsyncSection<CartMutationResult>(
              "updateItemQuantity.removeItemFromCart",
              () => _cartManagementService.removeItemFromCart(cartId, orderItemId, userId),
              startArguments: () => <String, dynamic>{"cartId": cartId, "orderItemId": orderItemId},
              logThreshold: const Duration(milliseconds: 4),
            );
          } else {
            result = await _traceAsyncSection<CartMutationResult>(
              "updateItemQuantity.updateCartItemQuantity",
              () => _cartManagementService.updateCartItemQuantity(
                cartId,
                orderItemId,
                quantity,
                userId,
              ),
              startArguments: () => <String, dynamic>{
                "cartId": cartId,
                "orderItemId": orderItemId,
                "quantity": quantity,
              },
              logThreshold: const Duration(milliseconds: 4),
            );
          }
          _applyCartMutationResult(result);

          if (quantity > 0) {
            final String highlightTarget = result.highlightMenuItemId ?? menuItemId;
            _triggerHighlight(highlightTarget);
          } else if (state.highlightedItemId == menuItemId) {
            state = state.copyWith(clearHighlightedItemId: true);
          }

          logSession.succeeded(
            message: quantity > 0 ? "カート数量を更新しました" : "カートからアイテムを削除しました",
            metadata: <String, dynamic>{
              "cart_item_count": state.cartItems.length,
              "mutation_kind": result.kind.name,
              "stock_warning": result.hasStockIssue,
              "requested_quantity": quantity,
            },
          );
        } catch (error, stackTrace) {
          final String message = ErrorHandler.instance.handleError(error);
          state = state.copyWith(errorMessage: message);
          logSession.failed(
            message: "数量更新でエラーが発生",
            reason: "update_quantity_failed",
            metadata: <String, dynamic>{"error_message": message},
            error: error,
            stackTrace: stackTrace,
          );
          _logPerfLazy(
            () => "updateItemQuantity.error item=$menuItemId quantity=$quantity message=$message",
          );
        }
      },
      startArguments: () => <String, dynamic>{"menuItemId": menuItemId, "quantity": quantity},
    );
  }

  /// アイテムをカートから削除する。
  @override
  void removeItem(String menuItemId) => unawaited(_removeItem(menuItemId));

  Future<void> _removeItem(String menuItemId) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "remove_item",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"menu_item_id": menuItemId},
      message: "注文管理 カート削除を開始",
    );

    await _traceAsyncSection<void>("removeItem", () async {
      if (state.isCheckoutInProgress) {
        _logPerfLazy(() => "removeItem.skip checkoutInProgress item=$menuItemId");
        logSession.cancelled(message: "会計処理中のため削除を中断", reason: "checkout_in_progress");
        return;
      }
      final String? userId = _ensureUserId();
      if (userId == null) {
        logSession.failed(message: "カート削除に失敗（ユーザー未認証）", reason: "missing_user");
        return;
      }

      final String? cartId = state.cartId;
      if (cartId == null) {
        logSession.failed(message: "カート削除に失敗（カート未取得）", reason: "cart_unavailable");
        return;
      }
      logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

      final CartItemViewData? target = state.cartItemByMenuId[menuItemId];
      final String? orderItemId = target?.orderItemId;

      if (target == null || orderItemId == null) {
        state = state.copyWith(
          cartItems: state.cartItems
              .where((CartItemViewData item) => item.menuItem.id != menuItemId)
              .toList(growable: false),
          clearHighlightedItemId: state.highlightedItemId == menuItemId,
        );
        logSession.succeeded(
          message: "UI 上のカートからアイテムを除外しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": "local_prune",
          },
        );
        return;
      }

      try {
        state = state.copyWith(clearErrorMessage: true);
        final CartMutationResult result = await _traceAsyncSection<CartMutationResult>(
          "removeItem.cartManagementService",
          () => _cartManagementService.removeItemFromCart(cartId, orderItemId, userId),
          startArguments: () => <String, dynamic>{"cartId": cartId, "orderItemId": orderItemId},
          logThreshold: const Duration(milliseconds: 4),
        );
        _applyCartMutationResult(result);
        if (state.highlightedItemId == menuItemId) {
          state = state.copyWith(clearHighlightedItemId: true);
        }

        logSession.succeeded(
          message: "カートからアイテムを削除しました",
          metadata: <String, dynamic>{
            "cart_item_count": state.cartItems.length,
            "mutation_kind": result.kind.name,
          },
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(errorMessage: message);
        logSession.failed(
          message: "カート削除でエラーが発生",
          reason: "remove_item_failed",
          metadata: <String, dynamic>{"error_message": message},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "removeItem.error item=$menuItemId message=$message");
      }
    }, startArguments: () => <String, dynamic>{"menuItemId": menuItemId});
  }

  /// カートをクリアする。
  @override
  void clearCart() => unawaited(_clearCart());

  Future<void> _clearCart() async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "clear_cart",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"cart_item_count": state.cartItems.length},
      message: "注文管理 カートクリアを開始",
    );

    if (state.isCheckoutInProgress) {
      logSession.cancelled(message: "会計処理中のためカートをクリアできません", reason: "checkout_in_progress");
      return;
    }
    if (state.cartItems.isEmpty) {
      logSession.cancelled(message: "カートが空のためクリア処理を実行しません", reason: "empty_cart");
      return;
    }

    final String? userId = _ensureUserId();
    if (userId == null) {
      logSession.failed(message: "カートクリアに失敗（ユーザー未認証）", reason: "missing_user");
      return;
    }

    final String? cartId = state.cartId;
    if (cartId == null) {
      state = state.copyWith(
        cartItems: <CartItemViewData>[],
        clearHighlightedItemId: true,
        orderNotes: "",
      );
      logSession.succeeded(
        message: "カートID不明のためローカル状態のみリセットしました",
        metadata: <String, dynamic>{"cart_item_count": 0, "mutation_kind": "local_prune"},
      );
      return;
    }
    logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

    try {
      state = state.copyWith(clearErrorMessage: true, orderNotes: "");
      final CartMutationResult result = await _cartManagementService.clearCart(cartId, userId);
      _applyCartMutationResult(result);
      state = state.copyWith(clearHighlightedItemId: true);
      logSession.succeeded(
        message: "カートをクリアしました",
        metadata: <String, dynamic>{
          "cart_item_count": state.cartItems.length,
          "mutation_kind": result.kind.name,
        },
      );
    } catch (error, stackTrace) {
      final String message = ErrorHandler.instance.handleError(error);
      state = state.copyWith(errorMessage: message);
      logSession.failed(
        message: "カートクリアでエラーが発生",
        reason: "clear_cart_failed",
        metadata: <String, dynamic>{"error_message": message},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
