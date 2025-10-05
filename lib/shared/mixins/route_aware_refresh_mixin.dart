import "dart:async";

import "package:flutter/widgets.dart";

import "../../app/router/app_router.dart";
import "../../infra/logging/logger.dart";

/// GoRouter + RouteObserver の通知を利用して画面復帰時に自動リフレッシュを行うための mixin。
@visibleForTesting
RouteObserver<PageRoute<dynamic>>? debugRouteObserverOverride;

@visibleForTesting
DateTime Function()? debugNowProviderOverride;

/// GoRouter + RouteObserver の通知を利用して画面復帰時に自動リフレッシュを行うための mixin。
mixin RouteAwareRefreshMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  static final Map<Type, DateTime> _lastExitTimestamps = <Type, DateTime>{};

  @visibleForTesting
  static void resetExitTimestampsForTest() {
    _lastExitTimestamps.clear();
  }

  bool _isSubscribed = false;
  bool _isRefreshing = false;
  PageRoute<dynamic>? _route;

  RouteObserver<PageRoute<dynamic>> get _observer =>
      debugRouteObserverOverride ?? AppRouter.routeObserver;

  /// 画面離脱からの経過時間に基づいて自動リフレッシュを抑制するクールダウン時間。
  ///
  /// `null` の場合はクールダウンによる制御を行わない。
  Duration? get refreshCooldown => null;

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
    _recordExitTimestamp();
    super.dispose();
  }

  /// 画面が再表示されたタイミングで実行する非同期処理を実装する。
  Future<void> onRouteReentered();

  @override
  void didPush() {
    _triggerRefresh("didPush");
  }

  @override
  void didPopNext() {
    _triggerRefresh("didPopNext");
  }

  @override
  void didPushNext() {
    _recordExitTimestamp();
  }

  @override
  void didPop() {
    _recordExitTimestamp();
  }

  DateTime _currentTime() {
    final DateTime Function() provider = debugNowProviderOverride ?? DateTime.now;
    return provider();
  }

  Duration? get _timeSinceLastExit {
    final DateTime? lastExit = _lastExitTimestamps[runtimeType];
    if (lastExit == null) {
      return null;
    }
    return _currentTime().difference(lastExit);
  }

  void _recordExitTimestamp() {
    _lastExitTimestamps[runtimeType] = _currentTime();
  }

  void _triggerRefresh(String trigger) {
    final Duration? sinceExit = _timeSinceLastExit;
    if (!_canRefresh(trigger, sinceExit)) {
      return;
    }
    unawaited(_refreshSafely(trigger, sinceExit: sinceExit));
  }

  bool _canRefresh(String trigger, Duration? sinceExit) {
    final Duration? cooldown = refreshCooldown;

    if (cooldown != null && sinceExit != null && sinceExit < cooldown) {
      return false;
    }

    if (trigger == "didPush") {
      if (shouldRefreshOnPush) {
        return true;
      }
      if (cooldown != null && sinceExit != null) {
        return sinceExit >= cooldown;
      }
      return false;
    }

    return true;
  }

  Future<void> _refreshSafely(String trigger, {Duration? sinceExit}) async {
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
        fields: <String, Object?>{
          "trigger": trigger,
          "state": runtimeType.toString(),
          if (sinceExit != null) "sinceExitMs": sinceExit.inMilliseconds,
        },
      );
    } finally {
      _isRefreshing = false;
    }
  }
}
