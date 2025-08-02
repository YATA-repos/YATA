import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/providers/common_providers.dart";
import "../../../../core/providers/unified_realtime_providers.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/inventory_dto.dart";
import "../../models/inventory_model.dart";
import "inventory_providers.dart";

part "realtime_inventory_providers.g.dart";

/// リアルタイム在庫更新情報
class InventoryUpdate {
  const InventoryUpdate({
    required this.materialId,
    required this.previousStock,
    required this.currentStock,
    required this.previousLevel,
    required this.currentLevel,
    required this.changeAmount,
    required this.changeReason,
    required this.timestamp,
  });

  final String materialId;
  final double previousStock;
  final double currentStock;
  final StockLevel previousLevel;
  final StockLevel currentLevel;
  final double changeAmount;
  final String changeReason;
  final DateTime timestamp;

  /// 在庫レベルが変化したかどうか
  bool get levelChanged => previousLevel != currentLevel;

  /// 在庫が増加したかどうか
  bool get isIncrease => changeAmount > 0;

  /// 在庫が減少したかどうか
  bool get isDecrease => changeAmount < 0;

  /// 警告が必要かどうか
  bool get needsAlert =>
      currentLevel == StockLevel.critical ||
      (previousLevel != StockLevel.critical && currentLevel == StockLevel.critical);
}

/// リアルタイム在庫監視プロバイダー
@riverpod
class RealTimeInventoryMonitor extends _$RealTimeInventoryMonitor {
  @override
  Map<String, InventoryUpdate> build() => <String, InventoryUpdate>{};

  /// リアルタイム監視を開始
  void startMonitoring({Duration interval = const Duration(minutes: 2)}) {
    _scheduleCheck(interval);
  }

  /// 定期チェックをスケジュール
  void _scheduleCheck(Duration interval) {
    Future<void>.delayed(interval, () async {
      await _checkForUpdates();
      _scheduleCheck(interval);
    });
  }

  /// 在庫更新をチェック
  Future<void> _checkForUpdates() async {
    try {
      final String? currentUserId = ref.read(currentUserProvider)?.id;
      if (currentUserId == null) {
        return;
      }

      // 現在の在庫情報を取得
      final List<MaterialStockInfo> currentInventory = await ref.read(
        materialsWithStockInfoProvider(null, currentUserId).future,
      );

      // 前回の状態と比較して更新を検出
      for (final MaterialStockInfo stockInfo in currentInventory) {
        await _processInventoryChange(stockInfo);
      }
    } catch (e) {
      ref.read(globalErrorProvider.notifier).setError("在庫監視エラー: ${e.toString()}");
    }
  }

  /// 在庫変化を処理
  Future<void> _processInventoryChange(MaterialStockInfo stockInfo) async {
    final String materialId = stockInfo.material.id!;
    final InventoryUpdate? previousUpdate = state[materialId];

    if (previousUpdate != null) {
      final double currentStock = stockInfo.material.currentStock;
      final double previousStock = previousUpdate.currentStock;

      if (currentStock != previousStock) {
        final StockLevel currentLevel = _calculateStockLevel(stockInfo);
        final InventoryUpdate update = InventoryUpdate(
          materialId: materialId,
          previousStock: previousStock,
          currentStock: currentStock,
          previousLevel: previousUpdate.currentLevel,
          currentLevel: currentLevel,
          changeAmount: currentStock - previousStock,
          changeReason: "自動検出",
          timestamp: DateTime.now(),
        );

        // 状態を更新
        state = <String, InventoryUpdate>{...state, materialId: update};

        // アラートが必要な場合は通知
        if (update.needsAlert) {
          _sendStockAlert(stockInfo, update);
        }
      }
    } else {
      // 初回記録
      final StockLevel currentLevel = _calculateStockLevel(stockInfo);
      final InventoryUpdate update = InventoryUpdate(
        materialId: materialId,
        previousStock: stockInfo.material.currentStock,
        currentStock: stockInfo.material.currentStock,
        previousLevel: currentLevel,
        currentLevel: currentLevel,
        changeAmount: 0,
        changeReason: "初期化",
        timestamp: DateTime.now(),
      );

      state = <String, InventoryUpdate>{...state, materialId: update};
    }
  }

  /// 在庫レベルを計算
  StockLevel _calculateStockLevel(MaterialStockInfo stockInfo) {
    final double current = stockInfo.material.currentStock;
    final double critical = stockInfo.material.criticalThreshold;
    final double alert = stockInfo.material.alertThreshold;

    if (current <= critical) {
      return StockLevel.critical;
    } else if (current <= alert) {
      return StockLevel.low;
    } else {
      return StockLevel.sufficient;
    }
  }

  /// 在庫アラートを送信
  void _sendStockAlert(MaterialStockInfo stockInfo, InventoryUpdate update) {
    final Material material = stockInfo.material;
    final String message = "${material.name}の在庫が${update.currentLevel.displayName}レベルになりました";

    if (update.currentLevel == StockLevel.critical) {
      ref.read(warningMessageProvider.notifier).setMessage(message);
    } else {
      ref.read(successMessageProvider.notifier).setMessage(message);
    }
  }

  /// 手動更新
  Future<void> manualUpdate() async {
    await _checkForUpdates();
  }

  /// 特定材料の更新記録を取得
  InventoryUpdate? getUpdateForMaterial(String materialId) => state[materialId];

  /// 更新履歴をクリア
  void clearHistory() {
    state = <String, InventoryUpdate>{};
  }
}

/// 在庫レベル変更通知プロバイダー
@riverpod
Future<List<InventoryUpdate>> recentStockLevelChanges(Ref ref, String userId) async {
  final Map<String, InventoryUpdate> monitor = ref.watch(realTimeInventoryMonitorProvider);

  // 過去1時間以内にレベルが変わった更新のみを返す
  final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 1));

  return monitor.values
      .where((InventoryUpdate update) => update.levelChanged && update.timestamp.isAfter(cutoff))
      .toList()
    ..sort((InventoryUpdate a, InventoryUpdate b) => b.timestamp.compareTo(a.timestamp));
}

/// 緊急在庫アラートプロバイダー
@riverpod
Future<List<MaterialStockInfo>> criticalStockAlerts(Ref ref, String userId) async {
  final List<MaterialStockInfo> allMaterials = await ref.watch(
    materialsWithStockInfoProvider(null, userId).future,
  );

  return allMaterials.where((MaterialStockInfo stockInfo) {
    final double current = stockInfo.material.currentStock;
    final double critical = stockInfo.material.criticalThreshold;
    return current <= critical;
  }).toList();
}

/// 在庫使用量追跡プロバイダー
@riverpod
class InventoryUsageTracker extends _$InventoryUsageTracker {
  @override
  Map<String, List<double>> build() => <String, List<double>>{};

  /// 使用量を記録
  void recordUsage(String materialId, double amount) {
    final List<double> currentUsage = state[materialId] ?? <double>[];
    final List<double> updatedUsage = <double>[...currentUsage, amount];

    // 最新の20件のみ保持
    if (updatedUsage.length > 20) {
      updatedUsage.removeAt(0);
    }

    state = <String, List<double>>{...state, materialId: updatedUsage};
  }

  /// 平均使用量を計算
  double getAverageUsage(String materialId) {
    final List<double>? usage = state[materialId];
    if (usage == null || usage.isEmpty) {
      return 0.0;
    }

    return usage.reduce((double a, double b) => a + b) / usage.length;
  }

  /// 使用傾向を取得（増加傾向かどうか）
  bool isUsageIncreasing(String materialId) {
    final List<double>? usage = state[materialId];
    if (usage == null || usage.length < 3) {
      return false;
    }

    final List<double> recent = usage.sublist(usage.length - 3);
    return recent[2] > recent[0];
  }

  /// 予想在庫切れ日時を計算
  DateTime? predictStockOutDate(String materialId, double currentStock) {
    final double avgUsage = getAverageUsage(materialId);
    if (avgUsage <= 0) {
      return null;
    }

    // 1日あたりの使用量を想定（現在は単純に平均使用量とする）
    final double daysUntilStockOut = currentStock / avgUsage;

    return DateTime.now().add(Duration(days: daysUntilStockOut.ceil()));
  }
}

/// 在庫補充推奨プロバイダー
@riverpod
Future<List<MaterialStockInfo>> restockRecommendations(Ref ref, String userId) async {
  final List<MaterialStockInfo> allMaterials = await ref.watch(
    materialsWithStockInfoProvider(null, userId).future,
  );

  final List<MaterialStockInfo> recommendations = <MaterialStockInfo>[];

  for (final MaterialStockInfo stockInfo in allMaterials) {
    final String materialId = stockInfo.material.id!;
    final double currentStock = stockInfo.material.currentStock;
    final double alertThreshold = stockInfo.material.alertThreshold;

    // 在庫切れ予想日を計算
    final DateTime? predictedStockOut = ref
        .read(inventoryUsageTrackerProvider.notifier)
        .predictStockOutDate(materialId, currentStock);

    // 在庫レベルまたは予想在庫切れ日に基づいて推奨
    final bool needsRestock =
        currentStock <= alertThreshold * 1.5 ||
        (predictedStockOut != null &&
            predictedStockOut.isBefore(DateTime.now().add(const Duration(days: 3))));

    if (needsRestock) {
      recommendations.add(stockInfo);
    }
  }

  // 優先度でソート（在庫レベルが低い順）
  recommendations.sort((MaterialStockInfo a, MaterialStockInfo b) {
    final double aRatio = a.material.currentStock / a.material.alertThreshold;
    final double bRatio = b.material.currentStock / b.material.alertThreshold;
    return aRatio.compareTo(bRatio);
  });

  return recommendations;
}

/// リアルタイム在庫ダッシュボード用プロバイダー
@riverpod
Future<InventoryDashboardData> inventoryDashboard(Ref ref, String userId) async {
  final List<MaterialStockInfo> allMaterials = await ref.watch(
    materialsWithStockInfoProvider(null, userId).future,
  );
  final List<InventoryUpdate> recentChanges = await ref.watch(
    recentStockLevelChangesProvider(userId).future,
  );
  final List<MaterialStockInfo> criticalAlerts = await ref.watch(
    criticalStockAlertsProvider(userId).future,
  );
  final List<MaterialStockInfo> restockRecs = await ref.watch(
    restockRecommendationsProvider(userId).future,
  );

  return InventoryDashboardData(
    totalMaterials: allMaterials.length,
    sufficientStock: allMaterials
        .where((MaterialStockInfo m) => m.material.currentStock > m.material.alertThreshold * 2)
        .length,
    lowStock: allMaterials
        .where(
          (MaterialStockInfo m) =>
              m.material.currentStock <= m.material.alertThreshold &&
              m.material.currentStock > m.material.criticalThreshold,
        )
        .length,
    criticalStock: criticalAlerts.length,
    recentChanges: recentChanges.length,
    restockNeeded: restockRecs.length,
  );
}

/// 在庫ダッシュボードデータ
class InventoryDashboardData {
  const InventoryDashboardData({
    required this.totalMaterials,
    required this.sufficientStock,
    required this.lowStock,
    required this.criticalStock,
    required this.recentChanges,
    required this.restockNeeded,
  });

  final int totalMaterials;
  final int sufficientStock;
  final int lowStock;
  final int criticalStock;
  final int recentChanges;
  final int restockNeeded;

  /// 在庫健全性スコア（0-100）
  double get healthScore {
    if (totalMaterials == 0) {
      return 100.0;
    }

    final double sufficientRatio = sufficientStock / totalMaterials;
    final double criticalRatio = criticalStock / totalMaterials;

    return ((sufficientRatio * 100) - (criticalRatio * 50)).clamp(0.0, 100.0);
  }
}

/// 在庫変更ストリームプロバイダー
/// 統合リアルタイム監視システムを使用
@riverpod
Stream<List<InventoryUpdate>> inventoryChangesStream(Ref ref, String userId) async* {
  // 統合リアルタイム監視を自動開始
  final UnifiedRealtimeManager unifiedManager = ref.read(unifiedRealtimeManagerProvider.notifier);
  await unifiedManager.startInventoryMonitoring(userId);

  // 15秒間隔で在庫変更をチェック
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 15));

    try {
      // 統合システムから在庫更新イベントを取得
      final List<InventoryUpdateEvent> realtimeEvents = unifiedManager.getRecentInventoryUpdates();
      
      // 既存のInventoryUpdate形式に変換
      final List<InventoryUpdate> updates = realtimeEvents.map((InventoryUpdateEvent event) => InventoryUpdate(
          materialId: event.materialId,
          previousStock: event.previousStock,
          currentStock: event.currentStock,
          previousLevel: StockLevel.sufficient, // 簡略化
          currentLevel: StockLevel.sufficient,  // 簡略化
          changeAmount: event.changeAmount,
          changeReason: event.changeReason,
          timestamp: event.timestamp,
        )).toList();

      yield updates;
    } catch (e) {
      // エラーの場合は空のリストを返す
      yield <InventoryUpdate>[];
    }
  }
}
