import "../../../core/constants/enums.dart";
import "../models/order_model.dart";
import "kitchen_analysis_service.dart";
import "kitchen_operation_service.dart";

/// キッチンサービス統合クラス
/// KitchenOperationServiceとKitchenAnalysisServiceを組み合わせて使用
class KitchenService {
  KitchenService({
    required KitchenOperationService kitchenOperationService,
    required KitchenAnalysisService kitchenAnalysisService,
  }) : _kitchenOperationService = kitchenOperationService,
       _kitchenAnalysisService = kitchenAnalysisService;

  final KitchenOperationService _kitchenOperationService;
  final KitchenAnalysisService _kitchenAnalysisService;

  String get loggerComponent => "KitchenService";

  // ===== キッチン操作関連メソッド =====

  /// ステータス別進行中注文を取得
  Future<Map<OrderStatus, List<Order>>> getActiveOrdersByStatus(String userId) async =>
      _kitchenOperationService.getActiveOrdersByStatus(userId);

  /// 注文キューを取得（調理順序順）
  Future<List<Order>> getOrderQueue(String userId) async =>
      _kitchenOperationService.getOrderQueue(userId);

  /// 注文の調理を開始
  Future<Order?> startOrderPreparation(String orderId, String userId) async =>
      _kitchenOperationService.startOrderPreparation(orderId, userId);

  /// 注文の調理を完了
  Future<Order?> completeOrderPreparation(String orderId, String userId) async =>
      _kitchenOperationService.completeOrderPreparation(orderId, userId);

  /// 注文を提供準備完了にマーク
  Future<Order?> markOrderReady(String orderId, String userId) async =>
      _kitchenOperationService.markOrderReady(orderId, userId);

  /// 注文を提供完了
  Future<Order?> deliverOrder(String orderId, String userId) async =>
      _kitchenOperationService.deliverOrder(orderId, userId);

  /// 完成予定時刻を調整
  Future<Order?> adjustEstimatedCompletionTime(
    String orderId,
    int additionalMinutes,
    String userId,
  ) async =>
      _kitchenOperationService.adjustEstimatedCompletionTime(orderId, additionalMinutes, userId);

  /// キッチン状況を更新
  Future<bool> updateKitchenStatus(int activeStaffCount, String? notes, String userId) async =>
      _kitchenOperationService.updateKitchenStatus(activeStaffCount, notes, userId);

  /// 実際の調理時間を取得（分）
  double? getActualPrepTimeMinutes(Order order) =>
      _kitchenOperationService.getActualPrepTimeMinutes(order);

  // ===== キッチン分析関連メソッド =====

  /// 完成予定時刻を計算
  Future<DateTime?> calculateEstimatedCompletionTime(String orderId, String userId) async =>
      _kitchenAnalysisService.calculateEstimatedCompletionTime(orderId, userId);

  /// キッチンの負荷状況を取得
  Future<Map<String, dynamic>> getKitchenWorkload(String userId) async =>
      _kitchenAnalysisService.getKitchenWorkload(userId);

  /// 注文キューの待ち時間を計算（分）
  Future<int> calculateQueueWaitTime(String userId) async =>
      _kitchenAnalysisService.calculateQueueWaitTime(userId);

  /// 調理順序を最適化（注文IDリストを返す）
  Future<List<String>> optimizeCookingOrder(String userId) async =>
      _kitchenAnalysisService.optimizeCookingOrder(userId);

  /// 全注文の完成予定時刻を予測
  Future<Map<String, DateTime>> predictCompletionTimes(String userId) async =>
      _kitchenAnalysisService.predictCompletionTimes(userId);

  /// キッチンパフォーマンス指標を取得
  Future<Map<String, dynamic>> getKitchenPerformanceMetrics(
    DateTime targetDate,
    String userId,
  ) async => _kitchenAnalysisService.getKitchenPerformanceMetrics(targetDate, userId);
}
