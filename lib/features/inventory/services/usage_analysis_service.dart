import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/stock_transaction_repository_contract.dart";
import "../models/inventory_model.dart";
import "../models/transaction_model.dart";

/// 使用量分析・予測サービス
class UsageAnalysisService {
  UsageAnalysisService({
    required MaterialRepositoryContract<Material> materialRepository,
    required StockTransactionRepositoryContract<StockTransaction> stockTransactionRepository,
  }) : _materialRepository = materialRepository,
       _stockTransactionRepository = stockTransactionRepository;

  final MaterialRepositoryContract<Material> _materialRepository;
  final StockTransactionRepositoryContract<StockTransaction> _stockTransactionRepository;

  String get loggerComponent => "UsageAnalysisService";

  /// 材料の平均使用量を計算（日次）
  Future<double?> calculateMaterialUsageRate(String materialId, int days, String userId) async {
    // 過去N日間の期間を設定
    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(Duration(days: days));

    // 期間内の消費取引を取得（負の値のみ）
    final List<StockTransaction> transactions = await _stockTransactionRepository
        .findByMaterialAndDateRange(materialId, startDate, endDate);

    // 消費取引のみをフィルタ（負の値）
    final List<StockTransaction> consumptionTransactions = transactions
        .where((StockTransaction t) => t.changeAmount < 0)
        .toList();

    if (consumptionTransactions.isEmpty) {
      return null;
    }

    // 総消費量を計算（絶対値）
    final double totalConsumption = consumptionTransactions.fold(
      0.0,
      (double sum, StockTransaction t) => sum + t.changeAmount.abs(),
    );

    // 日次平均を計算
    return days > 0 ? totalConsumption / days : null;
  }

  /// 推定使用可能日数を計算
  Future<int?> calculateEstimatedUsageDays(String materialId, String userId) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(materialId);
    if (material == null) {
      return null;
    }

    // 平均使用量を計算（過去30日間）
    final double? dailyUsage = await calculateMaterialUsageRate(materialId, 30, userId);

    if (dailyUsage == null || dailyUsage <= 0) {
      return null;
    }

    // 現在在庫量 ÷ 日次使用量 = 使用可能日数
    final double estimatedDays = material.currentStock / dailyUsage;

    return estimatedDays >= 0 ? estimatedDays.floor() : 0;
  }

  /// 全材料の使用可能日数を一括計算
  Future<Map<String, int?>> bulkCalculateUsageDays(String userId) async {
    // 全材料を取得
    final List<Material> materials = await _materialRepository.findByCategoryId(null);

    // 各材料の使用可能日数を計算
    final Map<String, int?> usageDays = <String, int?>{};
    for (final Material material in materials) {
      if (material.id != null) {
        final int? days = await calculateEstimatedUsageDays(material.id!, userId);
        usageDays[material.id!] = days;
      }
    }

    return usageDays;
  }

  /// 全材料の日次使用量を一括計算
  Future<Map<String, double?>> bulkCalculateDailyUsageRates(String userId, {int days = 30}) async {
    // 全材料を取得
    final List<Material> materials = await _materialRepository.findByCategoryId(null);

    // 各材料の日次使用量を計算
    final Map<String, double?> dailyUsageRates = <String, double?>{};
    for (final Material material in materials) {
      if (material.id != null) {
        final double? dailyUsage = await calculateMaterialUsageRate(material.id!, days, userId);
        dailyUsageRates[material.id!] = dailyUsage;
      }
    }

    return dailyUsageRates;
  }
}
