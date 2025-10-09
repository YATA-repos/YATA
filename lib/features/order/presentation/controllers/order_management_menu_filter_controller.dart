part of "order_management_controller.dart";

mixin MenuFilterController on _OrderManagementControllerBase {
  /// 初期データを読み込む。
  @override
  Future<void> loadInitialData({bool reset = false}) async {
    final UiActionLogSession logSession = UiActionLogSession.begin(
      logger: _logger,
      flow: "order",
      action: "load_initial_data",
      userId: _ref.read(currentUserIdProvider),
      metadata: <String, dynamic>{"reset": reset},
      message: "注文管理 初期データ読み込みを開始",
    );

    await _traceAsyncSection<void>("loadInitialData", () async {
      if (reset) {
        state = OrderManagementState.initial();
      } else {
        state = state.copyWith(isLoading: true, clearErrorMessage: true);
      }

      final AuthService authService = _ref.read(authServiceProvider);

      try {
        await _traceAsyncSection<void>(
          "loadInitialData.sessionWarmup",
          () => authService.ensureSupabaseSessionReady(timeout: const Duration(seconds: 5)),
          finishArguments: () => <String, dynamic>{
            "sessionReady": authService.isSupabaseSessionReady,
          },
          logThreshold: const Duration(milliseconds: 40),
        );
        logSession.addPersistentMetadata(<String, dynamic>{"session_ready": true});
      } on TimeoutException catch (error, stackTrace) {
        _logger.e(
          "Supabase session warm-up timed out before initial load",
          tag: loggerTag,
          error: error,
          st: stackTrace,
        );
        _logPerf("loadInitialData.sessionWarmupTimeout");
        state = state.copyWith(isLoading: false, errorMessage: "認証セッションの準備に時間がかかっています。再度お試しください。");
        logSession.failed(
          reason: "session_warmup_timeout",
          message: "注文管理 初期データ読み込み前にセッションウォームアップがタイムアウト",
          metadata: <String, dynamic>{"timeoutMs": 5000},
        );
        logSession.addPersistentMetadata(<String, dynamic>{"session_ready": false});
        return;
      } catch (error, stackTrace) {
        _logger.e(
          "Supabase session warm-up failed before initial load",
          tag: loggerTag,
          error: error,
          st: stackTrace,
        );
        _logPerf("loadInitialData.sessionWarmupFailed");
        state = state.copyWith(
          isLoading: false,
          errorMessage: "認証セッションの準備に失敗しました。時間をおいて再試行してください。",
        );
        logSession.failed(
          reason: "session_warmup_failed",
          message: "注文管理 初期データ読み込み前にセッションウォームアップに失敗",
          metadata: <String, dynamic>{"error": error.toString()},
        );
        logSession.addPersistentMetadata(<String, dynamic>{"session_ready": false});
        return;
      }

      final String? userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = state.copyWith(isLoading: false, errorMessage: "ユーザー情報を取得できませんでした。再度ログインしてください。");
        _logPerf("loadInitialData.userMissing");
        logSession.failed(
          reason: "missing_user",
          message: "注文管理 初期データ読み込みに失敗（ユーザー情報なし）",
          metadata: <String, dynamic>{"reset": reset},
        );
        return;
      }

      try {
        final List<MenuCategory> categoryModels = await _traceAsyncSection<List<MenuCategory>>(
          "loadInitialData.getMenuCategories",
          _menuService.getMenuCategories,
          startArguments: () => <String, dynamic>{"userId": userId},
        );
        final List<MenuItem> menuItemModels = await _traceAsyncSection<List<MenuItem>>(
          "loadInitialData.getMenuItemsByCategory",
          () => _menuService.getMenuItemsByCategory(null),
          startArguments: () => <String, dynamic>{"userId": userId},
        );

        _traceSyncSection<void>(
          "loadInitialData.updateMenuCache",
          () => _updateMenuCache(menuItemModels),
          startArguments: () => <String, dynamic>{"items": menuItemModels.length},
          logThreshold: const Duration(milliseconds: 2),
        );

        final List<MenuCategoryViewData> categoryView =
            _traceSyncSection<List<MenuCategoryViewData>>(
              "loadInitialData.buildCategoryView",
              () => _buildCategoryView(categoryModels),
              startArguments: () => <String, dynamic>{"categories": categoryModels.length},
              logThreshold: const Duration(milliseconds: 2),
            );

        final Order? cart = await _traceAsyncSection<Order?>(
          "loadInitialData.getActiveCart",
          () => _cartManagementService.getActiveCart(userId),
          startArguments: () => <String, dynamic>{"userId": userId},
        );

        String? cartId = cart?.id;
        _CartSnapshot snapshot = const _CartSnapshot(items: <CartItemViewData>[]);
        if (cartId != null) {
          snapshot = await _traceAsyncSection<_CartSnapshot>(
            "loadInitialData.loadCartSnapshot",
            () => _loadCartSnapshot(cartId!, userId),
            startArguments: () => <String, dynamic>{"cartId": cartId},
          );
          cartId = snapshot.cartId ?? cartId;
        }
        logSession.addPersistentMetadata(<String, dynamic>{"cart_id": cartId});

        int menuCount = 0;
        final List<MenuItemViewData> synchronisedMenu = _traceSyncSection<List<MenuItemViewData>>(
          "loadInitialData.synchroniseMenu",
          () {
            final List<MenuItemViewData> list = _menuItemCache.values.toList()
              ..sort(
                (MenuItemViewData a, MenuItemViewData b) =>
                    a.displayOrder.compareTo(b.displayOrder),
              );
            menuCount = list.length;
            return list;
          },
          startArguments: () => <String, dynamic>{"cacheSize": _menuItemCache.length},
          finishArguments: () => <String, dynamic>{"menuCount": menuCount},
          logThreshold: const Duration(milliseconds: 2),
        );

        final int safeIndex = categoryView.isEmpty
            ? 0
            : state.selectedCategoryIndex.clamp(0, categoryView.length - 1);

        state = state.copyWith(
          categories: categoryView,
          menuItems: synchronisedMenu,
          cartItems: snapshot.items,
          currentPaymentMethod:
              snapshot.paymentMethod ?? cart?.paymentMethod ?? state.currentPaymentMethod,
          cartId: cartId,
          orderNumber: snapshot.orderNumber ?? cart?.orderNumber,
          discountAmount: snapshot.discountAmount ?? cart?.discountAmount ?? 0,
          orderNotes: snapshot.orderNotes ?? cart?.notes ?? state.orderNotes,
          selectedCategoryIndex: safeIndex,
          isLoading: false,
          clearErrorMessage: true,
        );

        logSession.succeeded(
          message: "注文管理 初期データ読み込みが完了",
          metadata: <String, dynamic>{
            "category_count": categoryView.length,
            "menu_item_count": synchronisedMenu.length,
            "cart_item_count": snapshot.items.length,
            "has_active_cart": cartId != null,
          },
        );

        _logPerfLazy(
          () =>
              "loadInitialData.completed categories=${categoryView.length} menu=${synchronisedMenu.length} cartItems=${snapshot.items.length}",
        );
      } catch (error, stackTrace) {
        final String message = ErrorHandler.instance.handleError(error);
        state = state.copyWith(isLoading: false, errorMessage: message);
        logSession.failed(
          message: "注文管理 初期データ読み込みでエラー発生",
          reason: "load_initial_data_failed",
          metadata: <String, dynamic>{"reset": reset},
          error: error,
          stackTrace: stackTrace,
        );
        _logPerfLazy(() => "loadInitialData.error message=$message");
      }
    }, startArguments: () => <String, dynamic>{"reset": reset});
  }

  /// データを再読み込みする。
  @override
  void refresh() {
    if (state.isCheckoutInProgress) {
      return;
    }
    unawaited(loadInitialData());
  }

  /// カテゴリを選択する。
  @override
  void selectCategory(int index) {
    final int previousIndex = state.selectedCategoryIndex;
    _traceSyncSection<void>(
      "selectCategory",
      () {
        if (index == previousIndex) {
          _logPerfLazy(() => "selectCategory.skip index=$index");
          return;
        }
        state = state.copyWith(selectedCategoryIndex: index, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{"from": previousIndex, "to": index},
      finishArguments: () => <String, dynamic>{
        "changed": previousIndex != state.selectedCategoryIndex,
      },
      logThreshold: const Duration(milliseconds: 1),
    );
  }

  /// 検索キーワードを更新する。
  @override
  void updateSearchQuery(String query) {
    final String previous = state.searchQuery;
    _traceSyncSection<void>(
      "updateSearchQuery",
      () {
        if (query == previous) {
          _logPerfLazy(() => "updateSearchQuery.skip length=${query.length}");
          return;
        }
        state = state.copyWith(searchQuery: query, clearErrorMessage: true);
      },
      startArguments: () => <String, dynamic>{
        "previousLength": previous.length,
        "nextLength": query.length,
      },
      finishArguments: () => <String, dynamic>{"changed": previous != state.searchQuery},
      logThreshold: const Duration(milliseconds: 1),
    );
  }
}
