import "dart:async";

/// StreamSubscriptionを管理するミックスイン
///
/// 複数のStreamSubscriptionを管理し、disposeで一括破棄を行います。
/// メモリリーク検出とライフサイクル監視機能付き。
mixin StreamManagerMixin {
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  final List<_SubscriptionInfo> _subscriptionHistory = <_SubscriptionInfo>[];
  int _totalSubscriptionsCreated = 0;
  int _totalSubscriptionsCanceled = 0;

  /// StreamSubscriptionを管理リストに追加
  void addSubscription(
    StreamSubscription<dynamic> subscription, {
    String? debugName,
    String? source,
  }) {
    _subscriptions.add(subscription);
    _totalSubscriptionsCreated++;
    
    final _SubscriptionInfo info = _SubscriptionInfo(
      subscription: subscription,
      createdAt: DateTime.now(),
      debugName: debugName ?? "unnamed_subscription",
      source: source ?? "unknown",
    );
    
    _subscriptionHistory.add(info);
    
    // 履歴が100件を超えたら古いものを削除
    if (_subscriptionHistory.length > 100) {
      _subscriptionHistory.removeAt(0);
    }
  }

  /// 全てのStreamSubscriptionを破棄
  void disposeStreams() {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      subscription.cancel();
      _totalSubscriptionsCanceled++;
    }
    _subscriptions.clear();
  }

  /// 特定のStreamSubscriptionを破棄
  void cancelSubscription(StreamSubscription<dynamic> subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
    _totalSubscriptionsCanceled++;
  }

  /// アクティブなサブスクリプション数を取得
  int get activeSubscriptionCount => _subscriptions.length;

  /// 作成されたサブスクリプションの総数
  int get totalSubscriptionsCreated => _totalSubscriptionsCreated;

  /// キャンセルされたサブスクリプションの総数
  int get totalSubscriptionsCanceled => _totalSubscriptionsCanceled;

  /// 潜在的なメモリリークを検出
  bool get hasPotentialMemoryLeak {
    // アクティブなサブスクリプションが10個以上ある場合は警告
    if (_subscriptions.length >= 10) {
      return true;
    }
    
    // 5分以上前に作成されたアクティブなサブスクリプションがある場合は警告
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _subscriptionHistory.any((_SubscriptionInfo info) => 
      _subscriptions.contains(info.subscription) && info.createdAt.isBefore(fiveMinutesAgo));
  }

  /// メモリリーク警告メッセージを取得
  String? get memoryLeakWarningMessage {
    if (!hasPotentialMemoryLeak) {
      return null;
    }
    
    if (_subscriptions.length >= 20) {
      return "Critical: ${_subscriptions.length}個のアクティブなSubscriptionが検出されました。メモリリークの可能性があります。";
    } else if (_subscriptions.length >= 10) {
      return "Warning: ${_subscriptions.length}個のアクティブなSubscriptionが検出されました。";
    }
    
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final int longRunningCount = _subscriptionHistory
        .where((_SubscriptionInfo info) => 
          _subscriptions.contains(info.subscription) && info.createdAt.isBefore(fiveMinutesAgo))
        .length;
    
    if (longRunningCount > 0) {
      return "Warning: $longRunningCount個の長時間実行中のSubscriptionが検出されました。";
    }
    
    return null;
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getStreamDebugInfo() => <String, dynamic>{
    "active_subscriptions": _subscriptions.length,
    "total_created": _totalSubscriptionsCreated,
    "total_canceled": _totalSubscriptionsCanceled,
    "has_potential_leak": hasPotentialMemoryLeak,
    "warning_message": memoryLeakWarningMessage,
    "subscription_history": _subscriptionHistory.map((_SubscriptionInfo info) => <String, dynamic>{
      "debug_name": info.debugName,
      "source": info.source,
      "created_at": info.createdAt.toIso8601String(),
      "is_active": _subscriptions.contains(info.subscription),
    }).toList(),
  };
}

/// サブスクリプション情報を管理するプライベートクラス
class _SubscriptionInfo {
  _SubscriptionInfo({
    required this.subscription,
    required this.createdAt,
    required this.debugName,
    required this.source,
  });

  final StreamSubscription<dynamic> subscription;
  final DateTime createdAt;
  final String debugName;
  final String source;
}

/// StreamControllerを管理するミックスイン
///
/// 複数のStreamControllerを管理し、disposeで一括破棄を行います。
/// メモリリーク検出とライフサイクル監視機能付き。
mixin StreamControllerManagerMixin {
  final List<StreamController<dynamic>> _controllers = <StreamController<dynamic>>[];
  final List<_ControllerInfo> _controllerHistory = <_ControllerInfo>[];
  int _totalControllersCreated = 0;
  int _totalControllersClosed = 0;

  /// StreamControllerを管理リストに追加
  void addController(
    StreamController<dynamic> controller, {
    String? debugName,
    String? source,
  }) {
    _controllers.add(controller);
    _totalControllersCreated++;
    
    final _ControllerInfo info = _ControllerInfo(
      controller: controller,
      createdAt: DateTime.now(),
      debugName: debugName ?? "unnamed_controller",
      source: source ?? "unknown",
    );
    
    _controllerHistory.add(info);
    
    // 履歴が100件を超えたら古いものを削除
    if (_controllerHistory.length > 100) {
      _controllerHistory.removeAt(0);
    }
  }

  /// 全てのStreamControllerを破棄
  void disposeControllers() {
    for (final StreamController<dynamic> controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
        _totalControllersClosed++;
      }
    }
    _controllers.clear();
  }

  /// 特定のStreamControllerを破棄
  void closeController(StreamController<dynamic> controller) {
    if (!controller.isClosed) {
      controller.close();
      _totalControllersClosed++;
    }
    _controllers.remove(controller);
  }

  /// アクティブなコントローラー数を取得
  int get activeControllerCount => _controllers.length;

  /// 作成されたコントローラーの総数
  int get totalControllersCreated => _totalControllersCreated;

  /// クローズされたコントローラーの総数
  int get totalControllersClosed => _totalControllersClosed;

  /// 潜在的なメモリリークを検出（Controller版）
  bool get hasControllerMemoryLeak {
    // アクティブなコントローラーが5個以上ある場合は警告
    if (_controllers.length >= 5) {
      return true;
    }
    
    // 5分以上前に作成されたアクティブなコントローラーがある場合は警告
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _controllerHistory.any((_ControllerInfo info) => 
      _controllers.contains(info.controller) && info.createdAt.isBefore(fiveMinutesAgo));
  }

  /// コントローラーメモリリーク警告メッセージを取得
  String? get controllerMemoryLeakWarningMessage {
    if (!hasControllerMemoryLeak) {
      return null;
    }
    
    if (_controllers.length >= 10) {
      return "Critical: ${_controllers.length}個のアクティブなStreamControllerが検出されました。メモリリークの可能性があります。";
    } else if (_controllers.length >= 5) {
      return "Warning: ${_controllers.length}個のアクティブなStreamControllerが検出されました。";
    }
    
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final int longRunningCount = _controllerHistory
        .where((_ControllerInfo info) => 
          _controllers.contains(info.controller) && info.createdAt.isBefore(fiveMinutesAgo))
        .length;
    
    if (longRunningCount > 0) {
      return "Warning: $longRunningCount個の長時間実行中のStreamControllerが検出されました。";
    }
    
    return null;
  }

  /// コントローラーデバッグ情報を取得
  Map<String, dynamic> getControllerDebugInfo() => <String, dynamic>{
    "active_controllers": _controllers.length,
    "total_created": _totalControllersCreated,
    "total_closed": _totalControllersClosed,
    "has_potential_leak": hasControllerMemoryLeak,
    "warning_message": controllerMemoryLeakWarningMessage,
    "controller_history": _controllerHistory.map((_ControllerInfo info) => <String, dynamic>{
      "debug_name": info.debugName,
      "source": info.source,
      "created_at": info.createdAt.toIso8601String(),
      "is_active": _controllers.contains(info.controller),
      "is_closed": info.controller.isClosed,
    }).toList(),
  };
}

/// コントローラー情報を管理するプライベートクラス
class _ControllerInfo {
  _ControllerInfo({
    required this.controller,
    required this.createdAt,
    required this.debugName,
    required this.source,
  });

  final StreamController<dynamic> controller;
  final DateTime createdAt;
  final String debugName;
  final String source;
}

/// 包括的なリソース管理ミックスイン
///
/// StreamSubscriptionとStreamControllerの両方を管理します。
/// 統合されたメモリリーク検出とライフサイクル監視機能付き。
mixin ResourceManagerMixin implements StreamManagerMixin, StreamControllerManagerMixin {
  @override
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  @override
  final List<StreamController<dynamic>> _controllers = <StreamController<dynamic>>[];
  @override
  final List<_SubscriptionInfo> _subscriptionHistory = <_SubscriptionInfo>[];
  @override
  final List<_ControllerInfo> _controllerHistory = <_ControllerInfo>[];
  @override
  int _totalSubscriptionsCreated = 0;
  @override
  int _totalSubscriptionsCanceled = 0;
  @override
  int _totalControllersCreated = 0;
  @override
  int _totalControllersClosed = 0;

  @override
  void addSubscription(
    StreamSubscription<dynamic> subscription, {
    String? debugName,
    String? source,
  }) {
    _subscriptions.add(subscription);
    _totalSubscriptionsCreated++;
    
    final _SubscriptionInfo info = _SubscriptionInfo(
      subscription: subscription,
      createdAt: DateTime.now(),
      debugName: debugName ?? "unnamed_subscription",
      source: source ?? "unknown",
    );
    
    _subscriptionHistory.add(info);
    
    if (_subscriptionHistory.length > 100) {
      _subscriptionHistory.removeAt(0);
    }
  }

  @override
  void disposeStreams() {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      subscription.cancel();
      _totalSubscriptionsCanceled++;
    }
    _subscriptions.clear();
  }

  @override
  void cancelSubscription(StreamSubscription<dynamic> subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
    _totalSubscriptionsCanceled++;
  }

  @override
  void addController(
    StreamController<dynamic> controller, {
    String? debugName,
    String? source,
  }) {
    _controllers.add(controller);
    _totalControllersCreated++;
    
    final _ControllerInfo info = _ControllerInfo(
      controller: controller,
      createdAt: DateTime.now(),
      debugName: debugName ?? "unnamed_controller",
      source: source ?? "unknown",
    );
    
    _controllerHistory.add(info);
    
    if (_controllerHistory.length > 100) {
      _controllerHistory.removeAt(0);
    }
  }

  @override
  void disposeControllers() {
    for (final StreamController<dynamic> controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
        _totalControllersClosed++;
      }
    }
    _controllers.clear();
  }

  @override
  void closeController(StreamController<dynamic> controller) {
    if (!controller.isClosed) {
      controller.close();
      _totalControllersClosed++;
    }
    _controllers.remove(controller);
  }

  // StreamManagerMixinの必須プロパティ実装
  @override
  int get activeSubscriptionCount => _subscriptions.length;
  @override
  int get totalSubscriptionsCreated => _totalSubscriptionsCreated;
  @override
  int get totalSubscriptionsCanceled => _totalSubscriptionsCanceled;
  @override
  bool get hasPotentialMemoryLeak {
    if (_subscriptions.length >= 10) {
      return true;
    }
    
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _subscriptionHistory.any((_SubscriptionInfo info) => 
      _subscriptions.contains(info.subscription) && info.createdAt.isBefore(fiveMinutesAgo));
  }
  @override
  String? get memoryLeakWarningMessage {
    if (!hasPotentialMemoryLeak) {
      return null;
    }
    
    if (_subscriptions.length >= 20) {
      return "Critical: ${_subscriptions.length}個のアクティブなSubscriptionが検出されました。メモリリークの可能性があります。";
    } else if (_subscriptions.length >= 10) {
      return "Warning: ${_subscriptions.length}個のアクティブなSubscriptionが検出されました。";
    }
    return null;
  }
  @override
  Map<String, dynamic> getStreamDebugInfo() => <String, dynamic>{
    "active_subscriptions": _subscriptions.length,
    "total_created": _totalSubscriptionsCreated,
    "total_canceled": _totalSubscriptionsCanceled,
    "has_potential_leak": hasPotentialMemoryLeak,
    "warning_message": memoryLeakWarningMessage,
  };

  // StreamControllerManagerMixinの必須プロパティ実装
  @override
  int get activeControllerCount => _controllers.length;
  @override
  int get totalControllersCreated => _totalControllersCreated;
  @override
  int get totalControllersClosed => _totalControllersClosed;
  @override
  bool get hasControllerMemoryLeak {
    if (_controllers.length >= 5) {
      return true;
    }
    
    final DateTime fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return _controllerHistory.any((_ControllerInfo info) => 
      _controllers.contains(info.controller) && info.createdAt.isBefore(fiveMinutesAgo));
  }
  @override
  String? get controllerMemoryLeakWarningMessage {
    if (!hasControllerMemoryLeak) {
      return null;
    }
    
    if (_controllers.length >= 10) {
      return "Critical: ${_controllers.length}個のアクティブなStreamControllerが検出されました。メモリリークの可能性があります。";
    } else if (_controllers.length >= 5) {
      return "Warning: ${_controllers.length}個のアクティブなStreamControllerが検出されました。";
    }
    return null;
  }
  @override
  Map<String, dynamic> getControllerDebugInfo() => <String, dynamic>{
    "active_controllers": _controllers.length,
    "total_created": _totalControllersCreated,
    "total_closed": _totalControllersClosed,
    "has_potential_leak": hasControllerMemoryLeak,
    "warning_message": controllerMemoryLeakWarningMessage,
  };

  /// 全てのリソースを破棄
  void disposeAll() {
    disposeStreams();
    disposeControllers();
  }

  /// 統合されたメモリリーク検出
  bool get hasAnyMemoryLeak => hasPotentialMemoryLeak || hasControllerMemoryLeak;

  /// 統合されたメモリリーク警告メッセージ
  List<String> get allMemoryLeakWarnings {
    final List<String> warnings = <String>[];
    if (memoryLeakWarningMessage != null) {
      warnings.add(memoryLeakWarningMessage!);
    }
    if (controllerMemoryLeakWarningMessage != null) {
      warnings.add(controllerMemoryLeakWarningMessage!);
    }
    return warnings;
  }

  /// 統合されたリソースデバッグ情報
  Map<String, dynamic> getAllResourceDebugInfo() => <String, dynamic>{
    "streams": getStreamDebugInfo(),
    "controllers": getControllerDebugInfo(),
    "total_resources": activeSubscriptionCount + activeControllerCount,
    "has_any_leak": hasAnyMemoryLeak,
    "all_warnings": allMemoryLeakWarnings,
  };
}
