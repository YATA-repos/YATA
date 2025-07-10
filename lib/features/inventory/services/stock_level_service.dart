import "../../../core/constants/enums.dart";
import "../../../core/utils/logger_mixin.dart";
import "../dto/inventory_dto.dart";
import "../models/inventory_model.dart";
import "../repositories/material_repository.dart";

/// 在庫レベル判定・アラートサービス
class StockLevelService with LoggerMixin {
  StockLevelService({MaterialRepository? materialRepository})
    : _materialRepository = materialRepository ?? MaterialRepository();

  final MaterialRepository _materialRepository;

  @override
  String get loggerComponent => "StockLevelService";

  /// 在庫レベル別アラート材料を取得
  Future<Map<StockLevel, List<Material>>> getStockAlertsByLevel(String userId) async {
    final List<Material> criticalMaterials = await _materialRepository.findBelowCriticalThreshold(
      userId,
    );
    final List<Material> alertMaterials = await _materialRepository.findBelowAlertThreshold(userId);

    // アラートレベルからクリティカルを除外
    final List<Material> alertOnly = alertMaterials
        .where((Material m) => !criticalMaterials.contains(m))
        .toList();

    return <StockLevel, List<Material>>{
      StockLevel.critical: criticalMaterials,
      StockLevel.low: alertOnly,
      StockLevel.sufficient: <Material>[],
    };
  }

  /// 緊急レベルの材料一覧を取得
  Future<List<Material>> getCriticalStockMaterials(String userId) async =>
      _materialRepository.findBelowCriticalThreshold(userId);

  /// 材料一覧を在庫レベル・使用可能日数付きで取得
  /// 注意: 使用可能日数の計算にはUsageAnalysisServiceが必要
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    String? categoryId,
    String userId, {
    Map<String, int?>? usageDays,
    Map<String, double?>? dailyUsageRates,
  }) async {
    // 材料一覧を取得
    final List<Material> materials = await _materialRepository.findByCategoryId(categoryId, userId);

    // MaterialStockInfoに変換
    final List<MaterialStockInfo> stockInfos = <MaterialStockInfo>[];
    for (final Material material in materials) {
      final MaterialStockInfo stockInfo = MaterialStockInfo(
        material: material,
        stockLevel: material.getStockLevel(),
        estimatedUsageDays: usageDays?[material.id!],
        dailyUsageRate: dailyUsageRates?[material.id!],
      );
      stockInfos.add(stockInfo);
    }

    return stockInfos;
  }

  /// 詳細な在庫アラート情報を取得（レベル別 + 詳細情報付き）
  /// 注意: 使用可能日数の計算にはUsageAnalysisServiceが必要
  Future<Map<String, List<MaterialStockInfo>>> getDetailedStockAlerts(
    String userId, {
    Map<String, int?>? usageDays,
    Map<String, double?>? dailyUsageRates,
  }) async {
    // 全材料の在庫情報を取得
    final List<MaterialStockInfo> allMaterialsInfo = await getMaterialsWithStockInfo(
      null,
      userId,
      usageDays: usageDays,
      dailyUsageRates: dailyUsageRates,
    );

    // レベル別に分類
    final Map<String, List<MaterialStockInfo>> alerts = <String, List<MaterialStockInfo>>{
      "critical": <MaterialStockInfo>[],
      "low": <MaterialStockInfo>[],
      "sufficient": <MaterialStockInfo>[],
    };

    for (final MaterialStockInfo materialInfo in allMaterialsInfo) {
      if (materialInfo.stockLevel == StockLevel.critical) {
        alerts["critical"]!.add(materialInfo);
      } else if (materialInfo.stockLevel == StockLevel.low) {
        alerts["low"]!.add(materialInfo);
      } else {
        alerts["sufficient"]!.add(materialInfo);
      }
    }

    // 各レベル内で材料名でソート
    for (final String level in alerts.keys) {
      alerts[level]!.sort(
        (MaterialStockInfo a, MaterialStockInfo b) => a.material.name.compareTo(b.material.name),
      );
    }

    return alerts;
  }
}
