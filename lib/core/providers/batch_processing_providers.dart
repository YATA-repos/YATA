import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../features/auth/presentation/providers/auth_providers.dart";
import "../constants/enums.dart" as core_enums;
import "../services/batch_processing_service.dart";

part "batch_processing_providers.g.dart";

/// バッチ処理サービスプロバイダー
@riverpod
BatchProcessingService batchProcessingService(Ref ref) => 
    BatchProcessingService(ref: ref);

/// 在庫バッチデータプロバイダー
@riverpod
Future<BatchResult<InventoryBatchData>> inventoryBatchData(
  Ref ref, {
  List<String>? materialIds,
  bool includeAlerts = true,
  bool includeStats = true,
}) async {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BatchResult<InventoryBatchData>(
      success: false,
      data: null,
      error: "User not authenticated",
    );
  }

  final BatchProcessingService service = ref.watch(batchProcessingServiceProvider);
  return service.getInventoryBatch(
    userId,
    materialIds: materialIds,
    includeAlerts: includeAlerts,
    includeStats: includeStats,
  );
}

/// 注文バッチデータプロバイダー
@riverpod
Future<BatchResult<OrderBatchData>> orderBatchData(
  Ref ref, {
  DateTimeRange? dateRange,
  List<core_enums.OrderStatus>? statusFilter,
  bool includeStats = true,
}) async {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BatchResult<OrderBatchData>(
      success: false,
      data: null,
      error: "User not authenticated",
    );
  }

  final BatchProcessingService service = ref.watch(batchProcessingServiceProvider);
  return service.getOrderBatch(
    userId,
    dateRange: dateRange,
    statusFilter: statusFilter,
    includeStats: includeStats,
  );
}

/// 分析バッチデータプロバイダー
@riverpod
Future<BatchResult<AnalyticsBatchData>> analyticsBatchData(
  Ref ref,
  DateTimeRange dateRange,
) async {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BatchResult<AnalyticsBatchData>(
      success: false,
      data: null,
      error: "User not authenticated",
    );
  }

  final BatchProcessingService service = ref.watch(batchProcessingServiceProvider);
  return service.getAnalyticsBatch(userId, dateRange);
}

/// バッチ処理統計プロバイダー
@riverpod
Future<BatchProcessingStats> batchProcessingStats(Ref ref) async {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const BatchProcessingStats(
      totalBatches: 0,
      successfulBatches: 0,
      failedBatches: 0,
      averageProcessingTime: Duration.zero,
    );
  }

  // 実際の実装では、バッチ処理の履歴を追跡して統計を計算
  return const BatchProcessingStats(
    totalBatches: 0,
    successfulBatches: 0,
    failedBatches: 0,
    averageProcessingTime: Duration.zero,
  );
}

/// 統合データプロバイダー（複数のバッチを組み合わせ）
@riverpod
Future<UnifiedBatchData> unifiedBatchData(
  Ref ref, {
  DateTimeRange? dateRange,
  bool includeInventory = true,
  bool includeOrders = true,
  bool includeAnalytics = false,
}) async {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const UnifiedBatchData(
      inventory: null,
      orders: null,
      analytics: null,
      success: false,
      error: "User not authenticated",
    );
  }

  final BatchProcessingService service = ref.watch(batchProcessingServiceProvider);

  try {
    // 並列でバッチ処理を実行
    final List<Future<dynamic>> futures = <Future<dynamic>>[];

    if (includeInventory) {
      futures.add(service.getInventoryBatch(userId));
    }

    if (includeOrders) {
      futures.add(service.getOrderBatch(userId, dateRange: dateRange));
    }

    if (includeAnalytics && dateRange != null) {
      futures.add(service.getAnalyticsBatch(userId, dateRange));
    }

    final List<dynamic> results = await Future.wait(futures);

    BatchResult<InventoryBatchData>? inventoryResult;
    BatchResult<OrderBatchData>? orderResult;
    BatchResult<AnalyticsBatchData>? analyticsResult;

    int resultIndex = 0;
    if (includeInventory) {
      inventoryResult = results[resultIndex++] as BatchResult<InventoryBatchData>;
    }
    
    if (includeOrders) {
      orderResult = results[resultIndex++] as BatchResult<OrderBatchData>;
    }
    
    if (includeAnalytics && dateRange != null) {
      analyticsResult = results[resultIndex++] as BatchResult<AnalyticsBatchData>;
    }

    return UnifiedBatchData(
      inventory: inventoryResult?.data,
      orders: orderResult?.data,
      analytics: analyticsResult?.data,
      success: true,
      error: null,
    );
  } catch (e) {
    return UnifiedBatchData(
      inventory: null,
      orders: null,
      analytics: null,
      success: false,
      error: e.toString(),
    );
  }
}

/// バッチ処理統計データ
class BatchProcessingStats {
  const BatchProcessingStats({
    required this.totalBatches,
    required this.successfulBatches,
    required this.failedBatches,
    required this.averageProcessingTime,
  });

  final int totalBatches;
  final int successfulBatches;
  final int failedBatches;
  final Duration averageProcessingTime;

  double get successRate =>
      totalBatches > 0 ? successfulBatches / totalBatches : 0.0;

  double get failureRate =>
      totalBatches > 0 ? failedBatches / totalBatches : 0.0;
}

/// 統合バッチデータ
class UnifiedBatchData {
  const UnifiedBatchData({
    required this.inventory,
    required this.orders,
    required this.analytics,
    required this.success,
    required this.error,
  });

  final InventoryBatchData? inventory;
  final OrderBatchData? orders;
  final AnalyticsBatchData? analytics;
  final bool success;
  final String? error;

  bool get hasInventoryData => inventory != null;
  bool get hasOrderData => orders != null;
  bool get hasAnalyticsData => analytics != null;
}