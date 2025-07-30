import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/logging/logger_mixin.dart";
import "../models/inventory_model.dart";
import "../models/transaction_model.dart";
import "../repositories/material_repository.dart";
import "../repositories/purchase_repository.dart";
import "stock_level_service.dart";
import "usage_analysis_service.dart";

/// 発注提案データ
class OrderSuggestion {
  const OrderSuggestion({
    required this.material,
    required this.currentStock,
    required this.suggestedOrderQuantity,
    required this.estimatedUsageDays,
    required this.dailyUsageRate,
    required this.reason,
    required this.priority,
  });

  final Material material;
  final double currentStock;
  final double suggestedOrderQuantity;
  final int? estimatedUsageDays;
  final double? dailyUsageRate;
  final String reason;
  final OrderPriority priority;

  /// 発注が必要かどうか
  bool get needsOrder => suggestedOrderQuantity > 0;
}

/// 発注優先度
enum OrderPriority {
  /// 緊急（危険閾値以下）
  critical,
  
  /// 高（アラート閾値以下）
  high,
  
  /// 中（推定使用可能日数が短い）
  medium,
  
  /// 低（念のため）
  low,
}

/// 発注計算結果
class OrderCalculationResult {
  const OrderCalculationResult({
    required this.suggestions,
    required this.totalSuggestions,
    required this.criticalCount,
    required this.highPriorityCount,
  });

  final List<OrderSuggestion> suggestions;
  final int totalSuggestions;
  final int criticalCount;
  final int highPriorityCount;

  /// 緊急発注が必要かどうか
  bool get hasCriticalOrders => criticalCount > 0;
  
  /// 発注提案があるかどうか
  bool get hasOrderSuggestions => totalSuggestions > 0;
}

/// 発注ワークフローサービス
class OrderWorkflowService with LoggerMixin {
  OrderWorkflowService({
    required Ref ref,
    MaterialRepository? materialRepository,
    PurchaseRepository? purchaseRepository,
    StockLevelService? stockLevelService,
    UsageAnalysisService? usageAnalysisService,
  }) : _materialRepository = materialRepository ?? MaterialRepository(ref: ref),
       _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
       _stockLevelService = stockLevelService ?? StockLevelService(ref: ref),
       _usageAnalysisService = usageAnalysisService ?? UsageAnalysisService(ref: ref);

  final MaterialRepository _materialRepository;
  final PurchaseRepository _purchaseRepository;
  final StockLevelService _stockLevelService;
  final UsageAnalysisService _usageAnalysisService;

  @override
  String get loggerComponent => "OrderWorkflowService";

  /// 発注提案を計算
  Future<OrderCalculationResult> calculateOrderSuggestions(
    String userId, {
    String? categoryId,
    int analysisdays = 30,
    double safetyStockMultiplier = 1.5,
  }) async {
    logInfo("Starting order suggestion calculation for user: $userId");

    try {
      // 材料一覧を取得
      final List<Material> materials = await _materialRepository.findByCategoryId(categoryId);
      
      if (materials.isEmpty) {
        logInfo("No materials found for user: $userId");
        return const OrderCalculationResult(
          suggestions: <OrderSuggestion>[],
          totalSuggestions: 0,
          criticalCount: 0,
          highPriorityCount: 0,
        );
      }

      // 使用量分析データを一括取得
      final Map<String, int?> usageDays = await _usageAnalysisService.bulkCalculateUsageDays(userId);
      final Map<String, double?> dailyUsageRates = await _usageAnalysisService
          .bulkCalculateDailyUsageRates(userId);

      final List<OrderSuggestion> suggestions = <OrderSuggestion>[];
      int criticalCount = 0;
      int highPriorityCount = 0;

      // 各材料について発注提案を計算
      for (final Material material in materials) {
        final OrderSuggestion? suggestion = await _calculateMaterialOrderSuggestion(
          material,
          usageDays[material.id!],
          dailyUsageRates[material.id!],
          safetyStockMultiplier,
        );

        if (suggestion != null && suggestion.needsOrder) {
          suggestions.add(suggestion);
          
          switch (suggestion.priority) {
            case OrderPriority.critical:
              criticalCount++;
              break;
            case OrderPriority.high:
              highPriorityCount++;
              break;
            case OrderPriority.medium:
            case OrderPriority.low:
              break;
          }
        }
      }

      // 優先度でソート
      suggestions.sort((OrderSuggestion a, OrderSuggestion b) => a.priority.index.compareTo(b.priority.index));

      final OrderCalculationResult result = OrderCalculationResult(
        suggestions: suggestions,
        totalSuggestions: suggestions.length,
        criticalCount: criticalCount,
        highPriorityCount: highPriorityCount,
      );

      logInfo("Order calculation completed. Total suggestions: ${result.totalSuggestions}, "
              "Critical: ${result.criticalCount}, High: ${result.highPriorityCount}");

      return result;
    } catch (e, stackTrace) {
      logError("Failed to calculate order suggestions", e, stackTrace);
      rethrow;
    }
  }

  /// 単一材料の発注提案を計算
  Future<OrderSuggestion?> _calculateMaterialOrderSuggestion(
    Material material,
    int? estimatedUsageDays,
    double? dailyUsageRate,
    double safetyStockMultiplier,
  ) async {
    final double currentStock = material.currentStock;
    final double alertThreshold = material.alertThreshold;
    final double criticalThreshold = material.criticalThreshold;

    // 基本的な発注量計算
    double suggestedOrderQuantity = 0;
    String reason = "";
    OrderPriority priority = OrderPriority.low;

    // 1. 危険閾値を下回っている場合（最優先）
    if (currentStock <= criticalThreshold) {
      suggestedOrderQuantity = alertThreshold * safetyStockMultiplier - currentStock;
      reason = "危険閾値（$criticalThreshold）を下回っています";
      priority = OrderPriority.critical;
    }
    // 2. アラート閾値を下回っている場合（高優先度）
    else if (currentStock <= alertThreshold) {
      suggestedOrderQuantity = alertThreshold * safetyStockMultiplier - currentStock;
      reason = "アラート閾値（$alertThreshold）を下回っています";
      priority = OrderPriority.high;
    }
    // 3. 推定使用可能日数が短い場合（中優先度）
    else if (estimatedUsageDays != null && estimatedUsageDays <= 7) {
      // 7日以内に不足する可能性がある
      suggestedOrderQuantity = alertThreshold * safetyStockMultiplier - currentStock;
      reason = "推定使用可能日数が$estimatedUsageDays日と短いため";
      priority = OrderPriority.medium;
    }
    // 4. 念のための発注（使用量ベース）
    else if (dailyUsageRate != null && dailyUsageRate > 0) {
      // 30日分の在庫を維持したい場合
      final double desiredStock = dailyUsageRate * 30 * safetyStockMultiplier;
      if (currentStock < desiredStock) {
        suggestedOrderQuantity = desiredStock - currentStock;
        reason = "30日分の安全在庫を確保するため";
        priority = OrderPriority.low;
      }
    }

    // 発注量が少なすぎる場合は提案しない
    if (suggestedOrderQuantity < 1) {
      return null;
    }

    // 発注量を適切な単位に調整（小数点以下を切り上げ）
    suggestedOrderQuantity = suggestedOrderQuantity.ceilToDouble();

    return OrderSuggestion(
      material: material,
      currentStock: currentStock,
      suggestedOrderQuantity: suggestedOrderQuantity,
      estimatedUsageDays: estimatedUsageDays,
      dailyUsageRate: dailyUsageRate,
      reason: reason,
      priority: priority,
    );
  }

  /// 発注履歴を取得
  Future<List<Purchase>> getOrderHistory(
    String userId, {
    int days = 30,
  }) async {
    logInfo("Fetching order history for user: $userId, days: $days");

    try {
      return _purchaseRepository.findRecent(days, userId);
    } catch (e, stackTrace) {
      logError("Failed to fetch order history", e, stackTrace);
      rethrow;
    }
  }

  /// 期間指定で発注履歴を取得
  Future<List<Purchase>> getOrderHistoryByDateRange(
    DateTime dateFrom,
    DateTime dateTo,
    String userId,
  ) async {
    logInfo("Fetching order history by date range for user: $userId");

    try {
      return _purchaseRepository.findByDateRange(dateFrom, dateTo, userId);
    } catch (e, stackTrace) {
      logError("Failed to fetch order history by date range", e, stackTrace);
      rethrow;
    }
  }

  /// 発注量の統計情報を取得
  Future<Map<String, dynamic>> getOrderStatistics(
    String userId, {
    int days = 30,
  }) async {
    logInfo("Calculating order statistics for user: $userId");

    try {
      final List<Purchase> recentPurchases = await _purchaseRepository.findRecent(days, userId);
      
      final int totalOrders = recentPurchases.length;

      return <String, dynamic>{
        "totalOrders": totalOrders,
        "analysisDate": DateTime.now(),
        "analysisPeriodDays": days,
        "recentPurchases": recentPurchases.map((Purchase p) => <String, Object?>{
          "id": p.id,
          "purchaseDate": p.purchaseDate,
          "notes": p.notes,
        }).toList(),
      };
    } catch (e, stackTrace) {
      logError("Failed to calculate order statistics", e, stackTrace);
      rethrow;
    }
  }
}