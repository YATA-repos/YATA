import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../features/analytics/dto/analytics_dto.dart";
import "../../features/inventory/dto/inventory_dto.dart";
import "../../features/inventory/repositories/material_repository.dart";
import "../../features/order/models/order_model.dart";
import "../../features/order/repositories/order_repository.dart";
import "../../core/constants/enums.dart";
import "../../core/logging/logger_mixin.dart";

/// バッチ処理の種類
enum BatchOperationType {
  /// 在庫データ取得バッチ
  inventoryData,
  /// 注文データ取得バッチ
  orderData,
  /// 分析データ取得バッチ
  analyticsData,
  /// 混合データ取得バッチ
  mixedData,
}

/// バッチ処理リクエスト
class BatchRequest {
  const BatchRequest({
    required this.type,
    required this.userId,
    this.dateRange,
    this.filters,
    this.options,
  });

  final BatchOperationType type;
  final String userId;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? options;
}

/// バッチ処理結果
class BatchResult<T> {
  const BatchResult({
    required this.success,
    required this.data,
    this.error,
    this.duration,
  });

  final bool success;
  final T? data;
  final String? error;
  final Duration? duration;
}

/// 日時範囲クラス
class DateTimeRange {
  const DateTimeRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

/// バッチ処理統合サービス
/// 複数のデータ取得操作を効率的にバッチ処理
class BatchProcessingService with LoggerMixin {
  BatchProcessingService({required Ref ref}) : _ref = ref;

  final Ref _ref;
  final Map<String, Completer<dynamic>> _pendingBatches = <String, Completer<dynamic>>{};
  
  @override
  String get loggerComponent => "BatchProcessingService";

  /// 在庫関連データをバッチ取得
  Future<BatchResult<InventoryBatchData>> getInventoryBatch(
    String userId, {
    List<String>? materialIds,
    bool includeAlerts = true,
    bool includeStats = true,
  }) async {
    const String batchId = "inventory_batch";
    
    // 重複リクエストの防止
    if (_pendingBatches.containsKey(batchId)) {
      return await _pendingBatches[batchId]!.future as BatchResult<InventoryBatchData>;
    }

    final Completer<BatchResult<InventoryBatchData>> completer = 
        Completer<BatchResult<InventoryBatchData>>();
    _pendingBatches[batchId] = completer;

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      logInfo("Starting inventory batch processing for user: $userId");

      // 並列でデータを取得
      final List<Future<dynamic>> futures = <Future<dynamic>>[
        _getMaterialsWithStock(userId, materialIds),
        if (includeAlerts) _getInventoryAlerts(userId),
        if (includeStats) _getInventoryStats(userId),
      ];

      final List<dynamic> results = await Future.wait(futures);

      final List<MaterialStockInfo> materials = results[0] as List<MaterialStockInfo>;
      final Map<String, List<MaterialStockInfo>>? alerts = 
          includeAlerts ? results[1] as Map<String, List<MaterialStockInfo>>? : null;
      final InventoryStats? stats = 
          includeStats ? results[2] as InventoryStats? : null;

      final InventoryBatchData batchData = InventoryBatchData(
        materials: materials,
        alerts: alerts,
        stats: stats,
      );

      stopwatch.stop();
      logInfo("Inventory batch processing completed in ${stopwatch.elapsedMilliseconds}ms");

      final BatchResult<InventoryBatchData> result = BatchResult<InventoryBatchData>(
        success: true,
        data: batchData,
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } catch (e) {
      stopwatch.stop();
      logError("Inventory batch processing failed", e);

      final BatchResult<InventoryBatchData> result = BatchResult<InventoryBatchData>(
        success: false,
        data: null,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } finally {
      _pendingBatches.remove(batchId);
    }
  }

  /// 注文関連データをバッチ取得
  Future<BatchResult<OrderBatchData>> getOrderBatch(
    String userId, {
    DateTimeRange? dateRange,
    List<OrderStatus>? statusFilter,
    bool includeStats = true,
  }) async {
    const String batchId = "order_batch";
    
    if (_pendingBatches.containsKey(batchId)) {
      return await _pendingBatches[batchId]!.future as BatchResult<OrderBatchData>;
    }

    final Completer<BatchResult<OrderBatchData>> completer = 
        Completer<BatchResult<OrderBatchData>>();
    _pendingBatches[batchId] = completer;

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      logInfo("Starting order batch processing for user: $userId");

      final OrderRepository orderRepository = OrderRepository(ref: _ref);

      // 並列でデータを取得
      final List<Future<dynamic>> futures = <Future<dynamic>>[
        _getOrdersByStatus(userId, statusFilter),
        if (includeStats && dateRange != null) 
          orderRepository.findCompletedByDateRange(dateRange.start, dateRange.end),
      ];

      final List<dynamic> results = await Future.wait(futures);

      final Map<OrderStatus, List<Order>> ordersByStatus = 
          results[0] as Map<OrderStatus, List<Order>>;
      final List<Order>? completedOrders = 
          includeStats && results.length > 1 ? results[1] as List<Order>? : null;

      // 統計計算
      OrderStats? stats;
      if (includeStats && completedOrders != null) {
        stats = _calculateOrderStats(completedOrders);
      }

      final OrderBatchData batchData = OrderBatchData(
        ordersByStatus: ordersByStatus,
        stats: stats,
      );

      stopwatch.stop();
      logInfo("Order batch processing completed in ${stopwatch.elapsedMilliseconds}ms");

      final BatchResult<OrderBatchData> result = BatchResult<OrderBatchData>(
        success: true,
        data: batchData,
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } catch (e) {
      stopwatch.stop();
      logError("Order batch processing failed", e);

      final BatchResult<OrderBatchData> result = BatchResult<OrderBatchData>(
        success: false,
        data: null,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } finally {
      _pendingBatches.remove(batchId);
    }
  }

  /// 分析データをバッチ取得
  Future<BatchResult<AnalyticsBatchData>> getAnalyticsBatch(
    String userId,
    DateTimeRange dateRange,
  ) async {
    const String batchId = "analytics_batch";
    
    if (_pendingBatches.containsKey(batchId)) {
      return await _pendingBatches[batchId]!.future as BatchResult<AnalyticsBatchData>;
    }

    final Completer<BatchResult<AnalyticsBatchData>> completer = 
        Completer<BatchResult<AnalyticsBatchData>>();
    _pendingBatches[batchId] = completer;

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      logInfo("Starting analytics batch processing for user: $userId");

      final OrderRepository orderRepository = OrderRepository(ref: _ref);

      // 並列でデータを取得
      final List<Future<dynamic>> futures = <Future<dynamic>>[
        orderRepository.findCompletedByDateRange(dateRange.start, dateRange.end),
        orderRepository.countByStatusAndDateRange(dateRange.start, dateRange.end),
        _getPopularItemsForDateRange(userId, dateRange),
      ];

      final List<dynamic> results = await Future.wait(futures);

      final List<Order> completedOrders = results[0] as List<Order>;
      final Map<OrderStatus, Map<DateTime, int>> statusCounts = 
          results[1] as Map<OrderStatus, Map<DateTime, int>>;
      final List<Map<String, dynamic>> popularItems = 
          results[2] as List<Map<String, dynamic>>;

      // 日次統計を計算
      final List<DailyStatsResult> dailyStats = <DailyStatsResult>[];
      DateTime currentDate = dateRange.start;
      
      while (currentDate.isBefore(dateRange.end) || currentDate.isAtSameMomentAs(dateRange.end)) {
        final List<Order> dayOrders = completedOrders
            .where((Order order) => _isSameDay(order.orderedAt, currentDate))
            .toList();

        final DailyStatsResult dayStat = _calculateDayStats(dayOrders, currentDate);
        dailyStats.add(dayStat);
        
        currentDate = currentDate.add(const Duration(days: 1));
      }

      final AnalyticsBatchData batchData = AnalyticsBatchData(
        dailyStats: dailyStats,
        statusCounts: statusCounts,
        popularItems: popularItems,
        totalRevenue: completedOrders.fold(0, (int sum, Order order) => sum + order.totalAmount),
      );

      stopwatch.stop();
      logInfo("Analytics batch processing completed in ${stopwatch.elapsedMilliseconds}ms");

      final BatchResult<AnalyticsBatchData> result = BatchResult<AnalyticsBatchData>(
        success: true,
        data: batchData,
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } catch (e) {
      stopwatch.stop();
      logError("Analytics batch processing failed", e);

      final BatchResult<AnalyticsBatchData> result = BatchResult<AnalyticsBatchData>(
        success: false,
        data: null,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } finally {
      _pendingBatches.remove(batchId);
    }
  }

  // ===== プライベートヘルパーメソッド =====

  Future<List<MaterialStockInfo>> _getMaterialsWithStock(
    String userId,
    List<String>? materialIds,
  ) async {
    final MaterialRepository materialRepository = MaterialRepository(ref: _ref);
    
    if (materialIds != null && materialIds.isNotEmpty) {
      return materialRepository.getMaterialsWithStockInfo(materialIds, userId);
    } else {
      return materialRepository.getMaterialsWithStockInfo(null, userId);
    }
  }

  Future<Map<String, List<MaterialStockInfo>>> _getInventoryAlerts(String userId) async {
    final MaterialRepository materialRepository = MaterialRepository(ref: _ref);
    final List<MaterialStockInfo> allMaterials = 
        await materialRepository.getMaterialsWithStockInfo(null, userId);

    final Map<String, List<MaterialStockInfo>> alerts = <String, List<MaterialStockInfo>>{
      "critical": <MaterialStockInfo>[],
      "low": <MaterialStockInfo>[],
    };

    for (final MaterialStockInfo stockInfo in allMaterials) {
      final double current = stockInfo.material.currentStock;
      final double critical = stockInfo.material.criticalThreshold;
      final double alert = stockInfo.material.alertThreshold;

      if (current <= critical) {
        alerts["critical"]!.add(stockInfo);
      } else if (current <= alert) {
        alerts["low"]!.add(stockInfo);
      }
    }

    return alerts;
  }

  Future<InventoryStats> _getInventoryStats(String userId) async {
    final MaterialRepository materialRepository = MaterialRepository(ref: _ref);
    final List<MaterialStockInfo> allMaterials = 
        await materialRepository.getMaterialsWithStockInfo(null, userId);

    final int totalMaterials = allMaterials.length;
    int sufficientStock = 0;
    int lowStock = 0;
    int criticalStock = 0;

    for (final MaterialStockInfo stockInfo in allMaterials) {
      final double current = stockInfo.material.currentStock;
      final double critical = stockInfo.material.criticalThreshold;
      final double alert = stockInfo.material.alertThreshold;

      if (current <= critical) {
        criticalStock++;
      } else if (current <= alert) {
        lowStock++;
      } else {
        sufficientStock++;
      }
    }

    return InventoryStats(
      totalMaterials: totalMaterials,
      sufficientStock: sufficientStock,
      lowStock: lowStock,
      criticalStock: criticalStock,
    );
  }

  Future<Map<OrderStatus, List<Order>>> _getOrdersByStatus(
    String userId,
    List<OrderStatus>? statusFilter,
  ) async {
    final OrderRepository orderRepository = OrderRepository(ref: _ref);
    return orderRepository.getActiveOrdersByStatus(userId);
  }

  Future<List<Map<String, dynamic>>> _getPopularItemsForDateRange(
    String userId,
    DateTimeRange dateRange,
  ) async =>
      // 簡略化された実装 - 実際の実装では適切なリポジトリメソッドを使用
      <Map<String, dynamic>>[];

  OrderStats _calculateOrderStats(List<Order> orders) {
    final Map<OrderStatus, int> statusCounts = <OrderStatus, int>{};
    int totalRevenue = 0;
    final List<int> prepTimes = <int>[];

    for (final Order order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
      totalRevenue += order.totalAmount;

      final DateTime? startedAt = order.startedPreparingAt;
      final DateTime? readyAt = order.readyAt;
      if (startedAt != null && readyAt != null) {
        final Duration delta = readyAt.difference(startedAt);
        prepTimes.add(delta.inMinutes);
      }
    }

    final double avgPrepTime = prepTimes.isNotEmpty
        ? prepTimes.reduce((int a, int b) => a + b) / prepTimes.length
        : 0.0;

    return OrderStats(
      statusCounts: statusCounts,
      totalRevenue: totalRevenue,
      averagePrepTime: avgPrepTime,
    );
  }

  DailyStatsResult _calculateDayStats(List<Order> orders, DateTime date) {
    final int totalRevenue = orders.fold(0, (int sum, Order order) => sum + order.totalAmount);
    final List<int> prepTimes = <int>[];

    for (final Order order in orders) {
      final DateTime? startedAt = order.startedPreparingAt;
      final DateTime? readyAt = order.readyAt;
      if (startedAt != null && readyAt != null) {
        final Duration delta = readyAt.difference(startedAt);
        prepTimes.add(delta.inMinutes);
      }
    }

    final int? avgPrepTime = prepTimes.isNotEmpty
        ? (prepTimes.reduce((int a, int b) => a + b) / prepTimes.length).round()
        : null;

    return DailyStatsResult(
      completedOrders: orders.length,
      pendingOrders: 0,
      totalRevenue: totalRevenue,
      averagePrepTimeMinutes: avgPrepTime,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// 全てのペンディングバッチをクリア
  void clearPendingBatches() {
    _pendingBatches.clear();
  }
}

// ===== バッチデータクラス =====

/// 在庫バッチデータ
class InventoryBatchData {
  const InventoryBatchData({
    required this.materials,
    this.alerts,
    this.stats,
  });

  final List<MaterialStockInfo> materials;
  final Map<String, List<MaterialStockInfo>>? alerts;
  final InventoryStats? stats;
}

/// 注文バッチデータ
class OrderBatchData {
  const OrderBatchData({
    required this.ordersByStatus,
    this.stats,
  });

  final Map<OrderStatus, List<Order>> ordersByStatus;
  final OrderStats? stats;
}

/// 分析バッチデータ
class AnalyticsBatchData {
  const AnalyticsBatchData({
    required this.dailyStats,
    required this.statusCounts,
    required this.popularItems,
    required this.totalRevenue,
  });

  final List<DailyStatsResult> dailyStats;
  final Map<OrderStatus, Map<DateTime, int>> statusCounts;
  final List<Map<String, dynamic>> popularItems;
  final int totalRevenue;
}

/// 在庫統計データ
class InventoryStats {
  const InventoryStats({
    required this.totalMaterials,
    required this.sufficientStock,
    required this.lowStock,
    required this.criticalStock,
  });

  final int totalMaterials;
  final int sufficientStock;
  final int lowStock;
  final int criticalStock;

  double get healthScore {
    if (totalMaterials == 0) return 100.0;
    final double sufficientRatio = sufficientStock / totalMaterials;
    final double criticalRatio = criticalStock / totalMaterials;
    return ((sufficientRatio * 100) - (criticalRatio * 50)).clamp(0.0, 100.0);
  }
}

/// 注文統計データ
class OrderStats {
  const OrderStats({
    required this.statusCounts,
    required this.totalRevenue,
    required this.averagePrepTime,
  });

  final Map<OrderStatus, int> statusCounts;
  final int totalRevenue;
  final double averagePrepTime;
}