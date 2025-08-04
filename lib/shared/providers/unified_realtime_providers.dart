import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../core/constants/enums.dart" as core_enums;
import "../../data/realtime/realtime_manager.dart";
import "../../features/auth/presentation/providers/auth_providers.dart";
import "../../features/inventory/dto/inventory_dto.dart";
import "../../features/inventory/presentation/providers/inventory_providers.dart";
import "../../features/order/models/order_model.dart";
import "../../features/order/presentation/providers/order_providers.dart";
import "common_providers.dart";

part "unified_realtime_providers.g.dart";

/// 統合リアルタイム更新イベント
abstract class RealtimeUpdateEvent {
  const RealtimeUpdateEvent({required this.timestamp, required this.userId});

  final DateTime timestamp;
  final String userId;
}

/// 在庫更新イベント
class InventoryUpdateEvent extends RealtimeUpdateEvent {
  const InventoryUpdateEvent({
    required super.timestamp,
    required super.userId,
    required this.materialId,
    required this.previousStock,
    required this.currentStock,
    required this.changeReason,
  });

  final String materialId;
  final double previousStock;
  final double currentStock;
  final String changeReason;

  double get changeAmount => currentStock - previousStock;
  bool get isDecrease => changeAmount < 0;
  bool get isIncrease => changeAmount > 0;
}

/// 注文状況更新イベント
class OrderStatusUpdateEvent extends RealtimeUpdateEvent {
  const OrderStatusUpdateEvent({
    required super.timestamp,
    required super.userId,
    required this.orderId,
    required this.previousStatus,
    required this.currentStatus,
  });

  final String orderId;
  final String previousStatus;
  final String currentStatus;
}

/// 統合リアルタイム監視マネージャー
@riverpod
class UnifiedRealtimeManager extends _$UnifiedRealtimeManager {
  final Map<String, Timer> _timers = <String, Timer>{};
  final RealtimeManager _realtimeManager = RealtimeManager();

  @override
  Map<String, RealtimeUpdateEvent> build() => <String, RealtimeUpdateEvent>{};

  /// 在庫監視を開始
  Future<void> startInventoryMonitoring(String userId) async {
    const String subscriptionId = "inventory_monitoring";
    
    if (_timers.containsKey(subscriptionId)) {
      return; // 既に監視中
    }

    // 30秒間隔で在庫をチェック
    _timers[subscriptionId] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkInventoryUpdates(userId),
    );

    // 初回チェック実行
    await _checkInventoryUpdates(userId);
  }

  /// 注文監視を開始
  Future<void> startOrderMonitoring(String userId) async {
    const String subscriptionId = "order_monitoring";
    
    if (_timers.containsKey(subscriptionId)) {
      return; // 既に監視中
    }

    // 10秒間隔で注文をチェック
    _timers[subscriptionId] = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkOrderUpdates(userId),
    );

    // 初回チェック実行
    await _checkOrderUpdates(userId);
  }

  /// 在庫更新をチェック
  Future<void> _checkInventoryUpdates(String userId) async {
    try {
      final List<MaterialStockInfo> currentInventory = await ref.read(
        materialsWithStockInfoProvider(null, userId).future,
      );

      for (final MaterialStockInfo stockInfo in currentInventory) {
        await _processInventoryChange(stockInfo, userId);
      }
    } catch (e) {
      ref.read(globalErrorProvider.notifier).setError("在庫監視エラー: ${e.toString()}");
    }
  }

  /// 注文更新をチェック
  Future<void> _checkOrderUpdates(String userId) async {
    try {
      final Map<core_enums.OrderStatus, List<Order>> ordersByStatus = await ref.read(
        activeOrdersByStatusProvider(userId).future,
      );

      for (final List<Order> orders in ordersByStatus.values) {
        for (final Order order in orders) {
          await _processOrderChange(order, userId);
        }
      }
    } catch (e) {
      ref.read(globalErrorProvider.notifier).setError("注文監視エラー: ${e.toString()}");
    }
  }

  /// 在庫変更を処理
  Future<void> _processInventoryChange(MaterialStockInfo stockInfo, String userId) async {
    final String materialId = stockInfo.material.id!;
    final String eventKey = "inventory_$materialId";
    final RealtimeUpdateEvent? previousEvent = state[eventKey];

    if (previousEvent is InventoryUpdateEvent) {
      final double currentStock = stockInfo.material.currentStock;
      final double previousStock = previousEvent.currentStock;

      if (currentStock != previousStock) {
        final InventoryUpdateEvent updateEvent = InventoryUpdateEvent(
          timestamp: DateTime.now(),
          userId: userId,
          materialId: materialId,
          previousStock: previousStock,
          currentStock: currentStock,
          changeReason: "自動検出",
        );

        state = <String, RealtimeUpdateEvent>{...state, eventKey: updateEvent};

        // 重要な変更の場合は通知
        if (updateEvent.isDecrease && currentStock <= stockInfo.material.criticalThreshold) {
          ref.read(warningMessageProvider.notifier).setMessage(
            "${stockInfo.material.name}の在庫が危険レベルまで減少しました",
          );
        }
      }
    } else {
      // 初回記録
      final InventoryUpdateEvent initialEvent = InventoryUpdateEvent(
        timestamp: DateTime.now(),
        userId: userId,
        materialId: materialId,
        previousStock: stockInfo.material.currentStock,
        currentStock: stockInfo.material.currentStock,
        changeReason: "初期化",
      );

      state = <String, RealtimeUpdateEvent>{...state, eventKey: initialEvent};
    }
  }

  /// 注文変更を処理
  Future<void> _processOrderChange(Order order, String userId) async {
    final String orderId = order.id!;
    final String eventKey = "order_$orderId";
    final RealtimeUpdateEvent? previousEvent = state[eventKey];

    if (previousEvent is OrderStatusUpdateEvent) {
      final String currentStatus = order.status.name;
      final String previousStatus = previousEvent.currentStatus;

      if (currentStatus != previousStatus) {
        final OrderStatusUpdateEvent updateEvent = OrderStatusUpdateEvent(
          timestamp: DateTime.now(),
          userId: userId,
          orderId: orderId,
          previousStatus: previousStatus,
          currentStatus: currentStatus,
        );

        state = <String, RealtimeUpdateEvent>{...state, eventKey: updateEvent};

        // 重要なステータス変更の場合は通知
        if (currentStatus == "ready") {
          ref.read(successMessageProvider.notifier).setMessage(
            "注文${orderId.substring(0, 8)}の準備が完了しました",
          );
        }
      }
    } else {
      // 初回記録
      final OrderStatusUpdateEvent initialEvent = OrderStatusUpdateEvent(
        timestamp: DateTime.now(),
        userId: userId,
        orderId: orderId,
        previousStatus: order.status.name,
        currentStatus: order.status.name,
      );

      state = <String, RealtimeUpdateEvent>{...state, eventKey: initialEvent};
    }
  }

  /// 特定タイプの更新を取得
  List<T> getUpdatesOfType<T extends RealtimeUpdateEvent>() => state.values.whereType<T>().toList()
      ..sort((T a, T b) => b.timestamp.compareTo(a.timestamp));

  /// 最近の在庫更新を取得
  List<InventoryUpdateEvent> getRecentInventoryUpdates({
    Duration? since,
  }) {
    final DateTime cutoff = since != null 
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 1));

    return getUpdatesOfType<InventoryUpdateEvent>()
        .where((InventoryUpdateEvent event) => event.timestamp.isAfter(cutoff))
        .toList();
  }

  /// 最近の注文更新を取得
  List<OrderStatusUpdateEvent> getRecentOrderUpdates({
    Duration? since,
  }) {
    final DateTime cutoff = since != null 
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 1));

    return getUpdatesOfType<OrderStatusUpdateEvent>()
        .where((OrderStatusUpdateEvent event) => event.timestamp.isAfter(cutoff))
        .toList();
  }

  /// 監視を停止
  Future<void> stopMonitoring(String subscriptionId) async {
    final Timer? timer = _timers[subscriptionId];
    if (timer != null) {
      timer.cancel();
      _timers.remove(subscriptionId);
    }
  }

  /// 全監視を停止
  Future<void> stopAllMonitoring() async {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    state = <String, RealtimeUpdateEvent>{};
  }

  /// リソース解放
  Future<void> dispose() async {
    await stopAllMonitoring();
    await _realtimeManager.dispose();
  }
}

/// 統合リアルタイム監視状態プロバイダー
@riverpod
class UnifiedRealtimeState extends _$UnifiedRealtimeState {
  @override
  Map<String, bool> build() => <String, bool>{
    "inventory": false,
    "orders": false,
  };

  /// 在庫監視の有効/無効を切り替え
  Future<void> toggleInventoryMonitoring() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final bool currentState = state["inventory"] ?? false;
    final UnifiedRealtimeManager manager = ref.read(unifiedRealtimeManagerProvider.notifier);

    if (currentState) {
      await manager.stopMonitoring("inventory_monitoring");
    } else {
      await manager.startInventoryMonitoring(userId);
    }

    state = <String, bool>{...state, "inventory": !currentState};
  }

  /// 注文監視の有効/無効を切り替え
  Future<void> toggleOrderMonitoring() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final bool currentState = state["orders"] ?? false;
    final UnifiedRealtimeManager manager = ref.read(unifiedRealtimeManagerProvider.notifier);

    if (currentState) {
      await manager.stopMonitoring("order_monitoring");
    } else {
      await manager.startOrderMonitoring(userId);
    }

    state = <String, bool>{...state, "orders": !currentState};
  }

  /// 全監視を有効化
  Future<void> enableAllMonitoring() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final UnifiedRealtimeManager manager = ref.read(unifiedRealtimeManagerProvider.notifier);
    
    await manager.startInventoryMonitoring(userId);
    await manager.startOrderMonitoring(userId);

    state = <String, bool>{
      "inventory": true,
      "orders": true,
    };
  }

  /// 全監視を無効化
  Future<void> disableAllMonitoring() async {
    final UnifiedRealtimeManager manager = ref.read(unifiedRealtimeManagerProvider.notifier);
    await manager.stopAllMonitoring();

    state = <String, bool>{
      "inventory": false,
      "orders": false,
    };
  }
}

/// 統合リアルタイムストリームプロバイダー
/// メモリリーク対策強化版
@riverpod
Stream<List<RealtimeUpdateEvent>> unifiedRealtimeStream(Ref ref, String userId) async* {
  // 統合監視を自動開始
  final UnifiedRealtimeState state = ref.read(unifiedRealtimeStateProvider.notifier);
  await state.enableAllMonitoring();

  // キャンセレーション用のCompleter
  final Completer<void> cancelCompleter = Completer<void>();
  
  // ref.onDispose でキャンセレーションを設定
  ref.onDispose(() {
    if (!cancelCompleter.isCompleted) {
      cancelCompleter.complete();
    }
  });

  // 5秒間隔でイベントを配信（キャンセレーション対応）
  while (!cancelCompleter.isCompleted) {
    try {
      // キャンセレーションかタイムアウトのいずれかを待機
      await Future.any(<Future<void>>[
        Future<void>.delayed(const Duration(seconds: 5)),
        cancelCompleter.future,
      ]);

      // キャンセルされた場合はループを終了
      if (cancelCompleter.isCompleted) {
        break;
      }

      final Map<String, RealtimeUpdateEvent> events = ref.read(unifiedRealtimeManagerProvider);
      final List<RealtimeUpdateEvent> sortedEvents = events.values.toList()
        ..sort((RealtimeUpdateEvent a, RealtimeUpdateEvent b) => 
           b.timestamp.compareTo(a.timestamp));

      yield sortedEvents;
    } catch (e) {
      // エラーの場合は空のリストを返すが、キャンセル例外は再スロー
      if (e is StateError && cancelCompleter.isCompleted) {
        // キャンセルによる正常終了
        break;
      }
      yield <RealtimeUpdateEvent>[];
    }
  }
  
  // 監視終了時のクリーンアップ
  await state.disableAllMonitoring();
}

/// 統合リアルタイム統計プロバイダー
@riverpod
Future<RealtimeStats> unifiedRealtimeStats(Ref ref, String userId) async {
  final UnifiedRealtimeManager manager = ref.read(unifiedRealtimeManagerProvider.notifier);
  
  final List<InventoryUpdateEvent> inventoryUpdates = manager.getRecentInventoryUpdates();
  final List<OrderStatusUpdateEvent> orderUpdates = manager.getRecentOrderUpdates();

  return RealtimeStats(
    totalUpdates: inventoryUpdates.length + orderUpdates.length,
    inventoryUpdates: inventoryUpdates.length,
    orderUpdates: orderUpdates.length,
    criticalInventoryChanges: inventoryUpdates
        .where((InventoryUpdateEvent e) => e.isDecrease && e.changeAmount.abs() > 10)
        .length,
    importantOrderChanges: orderUpdates
        .where((OrderStatusUpdateEvent e) => 
           e.currentStatus == "ready" || e.currentStatus == "delivered")
        .length,
  );
}

/// リアルタイム統計データ
class RealtimeStats {
  const RealtimeStats({
    required this.totalUpdates,
    required this.inventoryUpdates,
    required this.orderUpdates,
    required this.criticalInventoryChanges,
    required this.importantOrderChanges,
  });

  final int totalUpdates;
  final int inventoryUpdates;
  final int orderUpdates;
  final int criticalInventoryChanges;
  final int importantOrderChanges;

  /// アクティビティレベル（0-100）
  double get activityLevel {
    if (totalUpdates == 0) {
      return 0.0;
    }
    
    final int criticalScore = criticalInventoryChanges * 3 + importantOrderChanges * 2;
    return (criticalScore / totalUpdates * 100).clamp(0.0, 100.0);
  }
}