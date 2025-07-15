import "dart:async";

/// StreamSubscriptionを管理するミックスイン
///
/// 複数のStreamSubscriptionを管理し、disposeで一括破棄を行います。
mixin StreamManagerMixin {
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  /// StreamSubscriptionを管理リストに追加
  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  /// 全てのStreamSubscriptionを破棄
  void disposeStreams() {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// 特定のStreamSubscriptionを破棄
  void cancelSubscription(StreamSubscription<dynamic> subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }
}

/// StreamControllerを管理するミックスイン
///
/// 複数のStreamControllerを管理し、disposeで一括破棄を行います。
mixin StreamControllerManagerMixin {
  final List<StreamController<dynamic>> _controllers = <StreamController<dynamic>>[];

  /// StreamControllerを管理リストに追加
  void addController(StreamController<dynamic> controller) {
    _controllers.add(controller);
  }

  /// 全てのStreamControllerを破棄
  void disposeControllers() {
    for (final StreamController<dynamic> controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  /// 特定のStreamControllerを破棄
  void closeController(StreamController<dynamic> controller) {
    if (!controller.isClosed) {
      controller.close();
    }
    _controllers.remove(controller);
  }
}

/// 包括的なリソース管理ミックスイン
///
/// StreamSubscriptionとStreamControllerの両方を管理します。
mixin ResourceManagerMixin implements StreamManagerMixin, StreamControllerManagerMixin {
  @override
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  @override
  final List<StreamController<dynamic>> _controllers = <StreamController<dynamic>>[];

  @override
  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  @override
  void disposeStreams() {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void cancelSubscription(StreamSubscription<dynamic> subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }

  @override
  void addController(StreamController<dynamic> controller) {
    _controllers.add(controller);
  }

  @override
  void disposeControllers() {
    for (final StreamController<dynamic> controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  @override
  void closeController(StreamController<dynamic> controller) {
    if (!controller.isClosed) {
      controller.close();
    }
    _controllers.remove(controller);
  }

  /// 全てのリソースを破棄
  void disposeAll() {
    disposeStreams();
    disposeControllers();
  }
}
