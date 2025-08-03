import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/utils/provider_logger.dart";
import "../../../auth/models/user_profile.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../dto/analytics_dto.dart";
import "../../services/analytics_service.dart";

part "analytics_providers.g.dart";

/// AnalyticsService プロバイダー
@riverpod
AnalyticsService analyticsService(Ref ref) {
  ProviderLogger.info("AnalyticsProviders", "AnalyticsServiceを初期化しました");
  return AnalyticsService(ref: ref);
}

/// 本日の統計データプロバイダー
@riverpod
Future<DailyStatsResult> todayStats(Ref ref) async {
  try {
    ProviderLogger.debug("AnalyticsProviders", "本日の統計データ取得を開始");
    final UserProfile? user = ref.watch(currentUserProvider);
    final String? userId = ref.watch(currentUserIdProvider);
    if (user == null || userId == null) {
      throw StateError("User not authenticated");
    }
    
    final AnalyticsService service = ref.watch(analyticsServiceProvider);
    final DateTime today = DateTime.now();
    final DailyStatsResult result = await service.getRealTimeDailyStats(today, userId);
    ProviderLogger.info("AnalyticsProviders", "本日の統計データ取得が完了");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("AnalyticsProviders", "todayStats", e, stackTrace);
    rethrow;
  }
}

/// 期間別統計データプロバイダー
@riverpod
Future<List<DailyStatsResult>> periodStats(Ref ref, DateTime startDate, DateTime endDate) async {
  final UserProfile? user = ref.watch(currentUserProvider);
  final String? userId = ref.watch(currentUserIdProvider);
  if (user == null || userId == null) {
    throw StateError("User not authenticated");
  }
  
  final AnalyticsService service = ref.watch(analyticsServiceProvider);
  final List<DailyStatsResult> stats = <DailyStatsResult>[];
  
  DateTime currentDate = startDate;
  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    final DailyStatsResult dailyStats = await service.getRealTimeDailyStats(currentDate, userId);
    stats.add(dailyStats);
    currentDate = currentDate.add(const Duration(days: 1));
  }
  
  return stats;
}

/// 人気商品ランキングプロバイダー
@riverpod
Future<List<Map<String, dynamic>>> popularItems(Ref ref, {int days = 7, int limit = 10}) async {
  final UserProfile? user = ref.watch(currentUserProvider);
  final String? userId = ref.watch(currentUserIdProvider);  
  if (user == null || userId == null) {
    throw StateError("User not authenticated");
  }
  
  final AnalyticsService service = ref.watch(analyticsServiceProvider);
  return service.getPopularItemsRanking(days, limit, userId);
}

/// 売上推移チャートデータプロバイダー
@riverpod
Future<Map<String, dynamic>> salesTrendChartData(Ref ref, DateTime startDate, DateTime endDate) async {
  final List<DailyStatsResult> stats = await ref.watch(periodStatsProvider(startDate, endDate).future);
  
  final Map<String, dynamic> chartData = <String, dynamic>{};
  
  for (int i = 0; i < stats.length; i++) {
    final DailyStatsResult stat = stats[i];
    final DateTime date = startDate.add(Duration(days: i));
    final String dateKey = "${date.month}/${date.day}";
    chartData[dateKey] = "¥${stat.totalRevenue.toStringAsFixed(0)}";
  }
  
  return chartData;
}

/// 商品別売上チャートデータプロバイダー
@riverpod
Future<Map<String, dynamic>> itemSalesChartData(Ref ref, {int days = 7}) async {
  final List<Map<String, dynamic>> popularItems = await ref.watch(popularItemsProvider(days: days).future);
  
  final Map<String, dynamic> chartData = <String, dynamic>{};
  
  for (final Map<String, dynamic> item in popularItems.take(5)) {
    final String itemName = "商品${item['rank']}"; // 実際の商品名は別途取得が必要
    final int totalAmount = item["total_amount"] as int? ?? 0;
    chartData[itemName] = "¥${totalAmount.toStringAsFixed(0)}";
  }
  
  return chartData;
}

/// 商品別販売数チャートデータプロバイダー
@riverpod
Future<Map<String, dynamic>> itemQuantityChartData(Ref ref, {int days = 7}) async {
  final List<Map<String, dynamic>> popularItems = await ref.watch(popularItemsProvider(days: days).future);
  
  final Map<String, dynamic> chartData = <String, dynamic>{};
  
  for (final Map<String, dynamic> item in popularItems.take(5)) {
    final String itemName = "商品${item['rank']}"; // 実際の商品名は別途取得が必要
    final int totalQuantity = item["total_quantity"] as int? ?? 0;
    chartData[itemName] = "$totalQuantity個";
  }
  
  return chartData;
}