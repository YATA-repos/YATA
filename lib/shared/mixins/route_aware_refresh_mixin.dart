import "dart:async";

import "package:flutter/widgets.dart";

import "../../app/router/app_router.dart";
import "../../infra/logging/logger.dart";

/// GoRouter + RouteObserver の通知を利用して画面復帰時に自動リフレッシュを行うための mixin。
@visibleForTesting
RouteObserver<PageRoute<dynamic>>? debugRouteObserverOverride;

/// GoRouter + RouteObserver の通知を利用して画面復帰時に自動リフレッシュを行うための mixin。
mixin RouteAwareRefreshMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  bool _isSubscribed = false;
  bool _isRefreshing = false;
  PageRoute<dynamic>? _route;

  RouteObserver<PageRoute<dynamic>> get _observer =>
      debugRouteObserverOverride ?? AppRouter.routeObserver;

  /// 初回表示時にも自動リフレッシュを実行するかどうか。
  ///
  /// 既存の initState 内で初期ロードを完了している画面では、
  /// オーバーライドして `false` を返すことで二重ロードを抑制できる。
  bool get shouldRefreshOnPush => true;

  /// 画面の Route に登録されているかどうかを返す。
  bool get isSubscribed => _isSubscribed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ModalRoute<dynamic>? modalRoute = ModalRoute.of(context);
    if (modalRoute is! PageRoute<dynamic>) {
      return;
    }

    if (!identical(modalRoute, _route)) {
      if (_isSubscribed && _route != null) {
        _observer.unsubscribe(this);
        _isSubscribed = false;
      }

      _route = modalRoute;
      _observer.subscribe(this, modalRoute);
      _isSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _observer.unsubscribe(this);
      _isSubscribed = false;
    }
    super.dispose();
  }

  /// 画面が再表示されたタイミングで実行する非同期処理を実装する。
  Future<void> onRouteReentered();

  @override
  void didPush() {
    if (!shouldRefreshOnPush) {
      return;
    }
    unawaited(_refreshSafely("didPush"));
  }

  @override
  void didPopNext() {
    unawaited(_refreshSafely("didPopNext"));
  }

  @override
  void didPushNext() {}

  @override
  void didPop() {}

  Future<void> _refreshSafely(String trigger) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    try {
      await onRouteReentered();
    } catch (error, stackTrace) {
      e(
        "RouteAwareRefreshMixin refresh failed",
        error: error,
        st: stackTrace,
        tag: "RouteAwareRefresh",
        fields: <String, Object?>{"trigger": trigger, "state": runtimeType.toString()},
      );
    } finally {
      _isRefreshing = false;
    }
  }
}
