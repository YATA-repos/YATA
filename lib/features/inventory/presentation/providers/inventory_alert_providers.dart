import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../dto/inventory_dto.dart";
import "../../services/inventory_service.dart";
import "inventory_providers.dart";

part "inventory_alert_providers.g.dart";

/// 在庫アラート設定
class InventoryAlertSettings {
  const InventoryAlertSettings({
    this.enableCriticalAlerts = true,
    this.enableLowStockAlerts = true,
    this.enableUsageDayAlerts = true,
    this.usageDayThreshold = 7,
    this.autoRefreshEnabled = true,
    this.refreshInterval = const Duration(minutes: 5),
  });

  final bool enableCriticalAlerts;
  final bool enableLowStockAlerts;
  final bool enableUsageDayAlerts;
  final int usageDayThreshold;
  final bool autoRefreshEnabled;
  final Duration refreshInterval;

  InventoryAlertSettings copyWith({
    bool? enableCriticalAlerts,
    bool? enableLowStockAlerts,
    bool? enableUsageDayAlerts,
    int? usageDayThreshold,
    bool? autoRefreshEnabled,
    Duration? refreshInterval,
  }) => InventoryAlertSettings(
      enableCriticalAlerts: enableCriticalAlerts ?? this.enableCriticalAlerts,
      enableLowStockAlerts: enableLowStockAlerts ?? this.enableLowStockAlerts,
      enableUsageDayAlerts: enableUsageDayAlerts ?? this.enableUsageDayAlerts,
      usageDayThreshold: usageDayThreshold ?? this.usageDayThreshold,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
}

/// アラート統計情報
class AlertStatistics {
  const AlertStatistics({
    required this.totalAlerts,
    required this.criticalCount,
    required this.lowStockCount,
    required this.shortUsageDaysCount,
    required this.lastUpdated,
  });

  final int totalAlerts;
  final int criticalCount;
  final int lowStockCount;
  final int shortUsageDaysCount;
  final DateTime lastUpdated;

  bool get hasAlerts => totalAlerts > 0;
  bool get hasCriticalAlerts => criticalCount > 0;
}

/// 在庫アラート設定プロバイダー
@riverpod
class InventoryAlertSettingsNotifier extends _$InventoryAlertSettingsNotifier {
  @override
  InventoryAlertSettings build() => const InventoryAlertSettings();

  /// 設定を更新
  void updateSettings(InventoryAlertSettings newSettings) {
    state = newSettings;
  }

  /// 緊急アラートの有効/無効を切り替え
  void toggleCriticalAlerts() {
    state = state.copyWith(enableCriticalAlerts: !state.enableCriticalAlerts);
  }

  /// 低在庫アラートの有効/無効を切り替え
  void toggleLowStockAlerts() {
    state = state.copyWith(enableLowStockAlerts: !state.enableLowStockAlerts);
  }

  /// 使用可能日数アラートの有効/無効を切り替え
  void toggleUsageDayAlerts() {
    state = state.copyWith(enableUsageDayAlerts: !state.enableUsageDayAlerts);
  }

  /// 使用可能日数の閾値を設定
  void setUsageDayThreshold(int threshold) {
    state = state.copyWith(usageDayThreshold: threshold);
  }

  /// 自動更新の有効/無効を切り替え
  void toggleAutoRefresh() {
    state = state.copyWith(autoRefreshEnabled: !state.autoRefreshEnabled);
  }
}

/// 詳細アラート情報プロバイダー
@riverpod
Future<Map<String, List<MaterialStockInfo>>> detailedInventoryAlerts(
  Ref ref,
  String userId,
) async {
  final InventoryService service = ref.watch(inventoryServiceProvider);
  return service.getDetailedStockAlerts(userId);
}

/// フィルタリングされたアラート情報プロバイダー
@riverpod
Future<Map<String, List<MaterialStockInfo>>> filteredInventoryAlerts(
  Ref ref,
  String userId,
) async {
  final InventoryAlertSettings settings = ref.watch(inventoryAlertSettingsNotifierProvider);
  final Map<String, List<MaterialStockInfo>> allAlerts = await ref.watch(detailedInventoryAlertsProvider(userId).future);
  
  final Map<String, List<MaterialStockInfo>> filteredAlerts = <String, List<MaterialStockInfo>>{
    "critical": <MaterialStockInfo>[],
    "low": <MaterialStockInfo>[],
    "sufficient": <MaterialStockInfo>[],
  };

  // 緊急アラート
  if (settings.enableCriticalAlerts) {
    filteredAlerts["critical"]!.addAll(allAlerts["critical"] ?? <MaterialStockInfo>[]);
  }

  // 低在庫アラート
  if (settings.enableLowStockAlerts) {
    filteredAlerts["low"]!.addAll(allAlerts["low"] ?? <MaterialStockInfo>[]);
  }

  // 使用可能日数によるフィルタリング
  if (settings.enableUsageDayAlerts) {
    final List<MaterialStockInfo> shortUsageDayItems = <MaterialStockInfo>[];
    
    for (final MaterialStockInfo item in allAlerts["sufficient"] ?? <MaterialStockInfo>[]) {
      if (item.estimatedUsageDays != null && 
          item.estimatedUsageDays! <= settings.usageDayThreshold) {
        shortUsageDayItems.add(item);
      }
    }
    
    // 使用可能日数が短いものを低在庫として扱う
    filteredAlerts["low"]!.addAll(shortUsageDayItems);
  }

  return filteredAlerts;
}

/// アラート統計情報プロバイダー
@riverpod
Future<AlertStatistics> alertStatistics(
  Ref ref,
  String userId,
) async {
  final Map<String, List<MaterialStockInfo>> alerts = await ref.watch(filteredInventoryAlertsProvider(userId).future);
  
  final int criticalCount = alerts["critical"]?.length ?? 0;
  final int lowStockCount = alerts["low"]?.length ?? 0;
  final int shortUsageDaysCount = alerts["low"]
      ?.where((MaterialStockInfo item) =>
          item.stockLevel == StockLevel.sufficient &&
          item.estimatedUsageDays != null &&
          item.estimatedUsageDays! <= 7)
      .length ?? 0;

  return AlertStatistics(
    totalAlerts: criticalCount + lowStockCount,
    criticalCount: criticalCount,
    lowStockCount: lowStockCount,
    shortUsageDaysCount: shortUsageDaysCount,
    lastUpdated: DateTime.now(),
  );
}

/// 緊急アラート専用プロバイダー
@riverpod
Future<List<MaterialStockInfo>> criticalAlerts(
  Ref ref,
  String userId,
) async {
  final Map<String, List<MaterialStockInfo>> alerts = await ref.watch(filteredInventoryAlertsProvider(userId).future);
  return alerts["critical"] ?? <MaterialStockInfo>[];
}

/// 低在庫アラート専用プロバイダー
@riverpod
Future<List<MaterialStockInfo>> lowStockAlerts(
  Ref ref,
  String userId,
) async {
  final Map<String, List<MaterialStockInfo>> alerts = await ref.watch(filteredInventoryAlertsProvider(userId).future);
  return alerts["low"] ?? <MaterialStockInfo>[];
}

/// アラート監視プロバイダー（自動更新用）
@riverpod
class AlertWatcher extends _$AlertWatcher {
  @override
  DateTime build() => DateTime.now();

  /// アラートを手動更新
  void refresh() {
    state = DateTime.now();
    // 関連するプロバイダーを無効化して再取得を促す
    ref..invalidate(detailedInventoryAlertsProvider)
    ..invalidate(filteredInventoryAlertsProvider)
    ..invalidate(alertStatisticsProvider);
  }
}