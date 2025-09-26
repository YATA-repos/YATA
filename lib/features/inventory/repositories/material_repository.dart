import "../../../core/constants/enums.dart";
import "../../../core/constants/query_types.dart";
import "../../../core/contracts/repositories/crud_repository.dart" as repo_contract;
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../dto/inventory_dto.dart";
import "../models/inventory_model.dart";

/// 材料リポジトリ（キャッシュ対応）
class MaterialRepository implements MaterialRepositoryContract<Material> {
  MaterialRepository({required repo_contract.CrudRepository<Material, String> delegate})
    : _delegate = delegate;

  final repo_contract.CrudRepository<Material, String> _delegate;

  /// カテゴリIDで材料を取得（None時は全件）
  /// キャッシュ対応版（マスターデータなので長期キャッシュが効果的）
  @override
  Future<List<Material>> findByCategoryId(String? categoryId) async {
    if (categoryId == null) {
      return _delegate.find();
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.eq("category_id", categoryId),
    ];

    return _delegate.find(filters: filters);
  }

  /// アラート閾値を下回る材料を取得
  Future<List<Material>> findBelowAlertThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await _delegate.find();

    // アラート閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.alertThreshold)
        .toList();
  }

  /// 緊急閾値を下回る材料を取得
  Future<List<Material>> findBelowCriticalThreshold() async {
    // 全材料を取得
    final List<Material> allMaterials = await _delegate.find();

    // 緊急閾値以下の材料をフィルタ
    return allMaterials
        .where((Material material) => material.currentStock <= material.criticalThreshold)
        .toList();
  }

  /// IDリストで材料を取得
  @override
  Future<List<Material>> findByIds(List<String> materialIds) async {
    if (materialIds.isEmpty) {
      return <Material>[];
    }

    final List<QueryFilter> filters = <QueryFilter>[
      QueryConditionBuilder.inList("id", materialIds),
    ];

    return _delegate.find(filters: filters);
  }

  /// 材料の在庫量を更新（キャッシュ無効化付き）
  @override
  Future<Material?> updateStockAmount(String materialId, double newAmount) async {
    // 在庫量を更新（マルチテナント対応により自動的にuser_idチェック）
    final Map<String, dynamic> updateData = <String, dynamic>{"current_stock": newAmount};
    final Material? updatedMaterial = await _delegate.updateById(materialId, updateData);

    return updatedMaterial;
  }

  /// 在庫情報付きの材料リストを取得
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(
    List<String>? materialIds,
    String userId,
  ) async {
    List<Material> materials;

    if (materialIds != null && materialIds.isNotEmpty) {
      // 指定IDの材料を取得
      materials = await findByIds(materialIds);
    } else {
      // 全材料を取得
      materials = await _delegate.find();
    }

    // MaterialStockInfoに変換
    final List<MaterialStockInfo> stockInfoList = <MaterialStockInfo>[];

    for (final Material material in materials) {
      final StockLevel stockLevel = _calculateStockLevel(material);
      final MaterialStockInfo stockInfo = MaterialStockInfo(
        material: material,
        stockLevel: stockLevel,
        estimatedUsageDays: _calculateEstimatedUsageDays(material),
        dailyUsageRate: _calculateDailyUsageRate(material),
      );
      stockInfoList.add(stockInfo);
    }

    return stockInfoList;
  }

  /// 在庫レベルを計算
  StockLevel _calculateStockLevel(Material material) {
    final double currentStock = material.currentStock;
    final double criticalThreshold = material.criticalThreshold;
    final double alertThreshold = material.alertThreshold;

    if (currentStock <= criticalThreshold) {
      return StockLevel.critical;
    } else if (currentStock <= alertThreshold) {
      return StockLevel.low;
    } else {
      return StockLevel.sufficient;
    }
  }

  /// 推定使用日数を計算（簡易版）
  int? _calculateEstimatedUsageDays(Material material) {
    // 簡易計算：現在の在庫÷平均使用量（仮定値）
    const double averageDailyUsage = 1.0; // 仮の値
    if (material.currentStock > 0) {
      return (material.currentStock / averageDailyUsage).ceil();
    }
    return null;
  }

  /// 日間使用率を計算（簡易版）
  double? _calculateDailyUsageRate(Material material) => 1.0; // 簡易計算: 固定値（仮）

  // ==== CrudRepository delegation (explicit implementations) ====
  @override
  Future<Material?> create(Material entity) => _delegate.create(entity);

  @override
  Future<List<Material>> bulkCreate(List<Material> entities) => _delegate.bulkCreate(entities);

  @override
  Future<Material?> getById(String id) => _delegate.getById(id);

  @override
  Future<Material?> getByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.getByPrimaryKey(keyMap);

  @override
  Future<Material?> updateById(String id, Map<String, dynamic> updates) =>
      _delegate.updateById(id, updates);

  @override
  Future<Material?> updateByPrimaryKey(Map<String, dynamic> keyMap, Map<String, dynamic> updates) =>
      _delegate.updateByPrimaryKey(keyMap, updates);

  @override
  Future<void> deleteById(String id) => _delegate.deleteById(id);

  @override
  Future<void> deleteByPrimaryKey(Map<String, dynamic> keyMap) =>
      _delegate.deleteByPrimaryKey(keyMap);

  @override
  Future<void> bulkDelete(List<String> keys) => _delegate.bulkDelete(keys);

  @override
  Future<List<Material>> find({
    List<QueryFilter>? filters,
    List<OrderByCondition>? orderBy,
    int limit = 100,
    int offset = 0,
  }) => _delegate.find(filters: filters, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> count({List<QueryFilter>? filters}) => _delegate.count(filters: filters);
}
