import "dart:async";

import "package:supabase_flutter/supabase_flutter.dart";

import "../../core/contracts/batch/batch_processing_service.dart" as contract;
import "../../infra/logging/logger.dart" as log;
import "../supabase/supabase_client.dart";

/// バッチ処理統合サービス
/// 複数のデータ取得操作を効率的にバッチ処理
class BatchProcessingService implements contract.BatchProcessingServiceContract {
  BatchProcessingService();
  final Map<String, Completer<dynamic>> _pendingBatches = <String, Completer<dynamic>>{};

  String get loggerComponent => "BatchProcessingService";

  @override
  Future<contract.BatchResult<T>> run<T>(contract.BatchRequest<T> request) async {
    final String type = request.type.trim().toLowerCase();
    final String batchId = "batch:$type";

    // 重複リクエストの防止
    if (_pendingBatches.containsKey(batchId)) {
      return await _pendingBatches[batchId]!.future as contract.BatchResult<T>;
    }

    final Completer<contract.BatchResult<T>> completer = Completer<contract.BatchResult<T>>();
    _pendingBatches[batchId] = completer;

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      log.i("Starting batch processing: type=$type, user=${request.userId}", tag: loggerComponent);

      dynamic data;
      switch (type) {
        case "inventory":
          data = await _runInventory(
            userId: request.userId,
            materialIds: (request.filters?["materialIds"] as List<dynamic>?)?.cast<String>(),
            includeAlerts: request.options?["includeAlerts"] as bool? ?? true,
            includeStats: request.options?["includeStats"] as bool? ?? true,
          );
          break;
        case "orders":
          data = await _runOrders(
            userId: request.userId,
            dateRange: request.dateRange,
            statusFilter: (request.filters?["status"] as List<dynamic>?)?.cast<String>(),
            includeStats: request.options?["includeStats"] as bool? ?? true,
          );
          break;
        case "analytics":
          if (request.dateRange == null) {
            throw ArgumentError("analytics batch requires dateRange");
          }
          data = await _runAnalytics(userId: request.userId, dateRange: request.dateRange!);
          break;
        default:
          throw UnsupportedError("Unknown batch type: $type");
      }

      stopwatch.stop();
      log.i(
        "Batch processing completed in ${stopwatch.elapsedMilliseconds}ms",
        tag: loggerComponent,
      );

      final contract.BatchResult<T> result = contract.BatchResult<T>(
        success: true,
        data: data as T,
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } catch (e) {
      stopwatch.stop();
      log.e("Batch processing failed: $e", tag: loggerComponent, error: e);

      final contract.BatchResult<T> result = contract.BatchResult<T>(
        success: false,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );

      completer.complete(result);
      return result;
    } finally {
      _pendingBatches.remove(batchId);
    }
  }
  // ===== プライベート: 各バッチの実処理（コア非依存のMap構造で返却） =====

  Future<Map<String, dynamic>> _runInventory({
    required String userId,
    List<String>? materialIds,
    bool includeAlerts = true,
    bool includeStats = true,
  }) async {
    final SupabaseClient client = SupabaseClientService.client;
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = client
        .from("materials")
        .select("id,name,current_stock,alert_threshold,critical_threshold,user_id");
    query = query.eq("user_id", userId);
    if (materialIds != null && materialIds.isNotEmpty) {
      query = query.inFilter("id", materialIds);
    }
    final List<Map<String, dynamic>> materials = await query;

    final Map<String, dynamic> result = <String, dynamic>{"materials": materials};

    if (includeAlerts) {
      final Map<String, List<Map<String, dynamic>>> alerts = <String, List<Map<String, dynamic>>>{
        "critical": <Map<String, dynamic>>[],
        "low": <Map<String, dynamic>>[],
      };
      for (final Map<String, dynamic> m in materials) {
        final double current = (m["current_stock"] as num).toDouble();
        final double critical = (m["critical_threshold"] as num).toDouble();
        final double alert = (m["alert_threshold"] as num).toDouble();
        if (current <= critical) {
          alerts["critical"]!.add(m);
        } else if (current <= alert) {
          alerts["low"]!.add(m);
        }
      }
      result["alerts"] = alerts;
    }

    if (includeStats) {
      final int total = materials.length;
      int sufficient = 0, low = 0, critical = 0;
      for (final Map<String, dynamic> m in materials) {
        final double current = (m["current_stock"] as num).toDouble();
        final double c = (m["critical_threshold"] as num).toDouble();
        final double a = (m["alert_threshold"] as num).toDouble();
        if (current <= c) {
          critical++;
        } else if (current <= a) {
          low++;
        } else {
          sufficient++;
        }
      }
      final double healthScore = total == 0
          ? 100.0
          : (((sufficient / total) * 100) - ((critical / total) * 50)).clamp(0.0, 100.0);
      result["stats"] = <String, dynamic>{
        "totalMaterials": total,
        "sufficientStock": sufficient,
        "lowStock": low,
        "criticalStock": critical,
        "healthScore": healthScore,
      };
    }

    return result;
  }

  Future<Map<String, dynamic>> _runOrders({
    required String userId,
    contract.DateTimeRange? dateRange,
    List<String>? statusFilter,
    bool includeStats = true,
  }) async {
    final SupabaseClient client = SupabaseClientService.client;
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = client
        .from("orders")
        .select(
          "id,status,ordered_at,completed_at,ready_at,started_preparing_at,total_amount,user_id",
        );
    query = query.eq("user_id", userId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.inFilter("status", statusFilter);
    }
    if (dateRange != null) {
      final String start = dateRange.start.toIso8601String();
      final String end = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();
      query = query.gte("ordered_at", start).lte("ordered_at", end);
    }
    final List<Map<String, dynamic>> orders = await query;

    // Group by status
    final Map<String, List<Map<String, dynamic>>> byStatus = <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> o in orders) {
      final String status = o["status"] as String? ?? "unknown";
      (byStatus[status] ??= <Map<String, dynamic>>[]).add(o);
    }

    final Map<String, dynamic> result = <String, dynamic>{"orders_by_status": byStatus};

    if (includeStats) {
      int totalRevenue = 0;
      final List<int> prepTimes = <int>[];
      for (final Map<String, dynamic> o in orders) {
        totalRevenue += (o["total_amount"] as num?)?.toInt() ?? 0;
        final String? startedStr = o["started_preparing_at"] as String?;
        final String? readyStr = o["ready_at"] as String?;
        if (startedStr != null && readyStr != null) {
          final DateTime started = DateTime.parse(startedStr);
          final DateTime ready = DateTime.parse(readyStr);
          final int minutes = ready.difference(started).inMinutes;
          if (minutes >= 0) {
            prepTimes.add(minutes);
          }
        }
      }
      final double avgPrep = prepTimes.isNotEmpty
          ? prepTimes.reduce((int a, int b) => a + b) / prepTimes.length
          : 0.0;
      result["stats"] = <String, dynamic>{"totalRevenue": totalRevenue, "averagePrepTime": avgPrep};
    }

    return result;
  }

  Future<Map<String, dynamic>> _runAnalytics({
    required String userId,
    required contract.DateTimeRange dateRange,
  }) async {
    final SupabaseClient client = SupabaseClientService.client;
    final String start = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    ).toIso8601String();
    final String end = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();

    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = client
        .from("orders")
        .select(
          "id,status,ordered_at,completed_at,total_amount,user_id,ready_at,started_preparing_at",
        );
    query = query.eq("user_id", userId).gte("ordered_at", start).lte("ordered_at", end);
    final List<Map<String, dynamic>> orders = await query;

    // Build daily stats
    final List<Map<String, dynamic>> dailyStats = <Map<String, dynamic>>[];
    DateTime cursor = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
    final DateTime endDay = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

    while (!cursor.isAfter(endDay)) {
      final DateTime dayStart = DateTime(cursor.year, cursor.month, cursor.day);
      final DateTime dayEnd = DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59, 999);
      final List<Map<String, dynamic>> dayOrders = orders.where((Map<String, dynamic> o) {
        final DateTime orderedAt = DateTime.parse(o["ordered_at"] as String);
        return orderedAt.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
            orderedAt.isBefore(dayEnd.add(const Duration(milliseconds: 1)));
      }).toList();
      final int totalRevenue = dayOrders.fold(
        0,
        (int s, Map<String, dynamic> o) => s + ((o["total_amount"] as num?)?.toInt() ?? 0),
      );
      final List<int> prepTimes = <int>[];
      for (final Map<String, dynamic> o in dayOrders) {
        final String? startedStr = o["started_preparing_at"] as String?;
        final String? readyStr = o["ready_at"] as String?;
        if (startedStr != null && readyStr != null) {
          final int minutes = DateTime.parse(
            readyStr,
          ).difference(DateTime.parse(startedStr)).inMinutes;
          if (minutes >= 0) prepTimes.add(minutes);
        }
      }
      final int? avgPrep = prepTimes.isNotEmpty
          ? (prepTimes.reduce((int a, int b) => a + b) / prepTimes.length).round()
          : null;
      dailyStats.add(<String, dynamic>{
        "date": dayStart.toIso8601String(),
        "completedOrders": dayOrders.length,
        "pendingOrders": 0,
        "totalRevenue": totalRevenue,
        "averagePrepTimeMinutes": avgPrep,
      });
      cursor = cursor.add(const Duration(days: 1));
    }

    // Status counts for whole range
    final Map<String, Map<String, int>> statusCounts = <String, Map<String, int>>{};
    for (final Map<String, dynamic> o in orders) {
      final String status = (o["status"] as String?) ?? "unknown";
      final DateTime orderedAt = DateTime.parse(o["ordered_at"] as String);
      final String dayKey = DateTime(
        orderedAt.year,
        orderedAt.month,
        orderedAt.day,
      ).toIso8601String();
      (statusCounts[status] ??= <String, int>{});
      statusCounts[status]![dayKey] = (statusCounts[status]![dayKey] ?? 0) + 1;
    }

    final int totalRevenue = orders.fold(
      0,
      (int s, Map<String, dynamic> o) => s + ((o["total_amount"] as num?)?.toInt() ?? 0),
    );

    return <String, dynamic>{
      "dailyStats": dailyStats,
      "statusCounts": statusCounts,
      "popularItems": <Map<String, dynamic>>[],
      "totalRevenue": totalRevenue,
    };
  }

  /// 全てのペンディングバッチをクリア
  void clearPendingBatches() {
    _pendingBatches.clear();
  }
}
