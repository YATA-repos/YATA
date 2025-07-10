import "../../../core/constants/log_enums/service.dart";
import "../../../core/utils/logger_mixin.dart";
import "../models/inventory_model.dart";
import "../repositories/material_category_repository.dart";
import "../repositories/material_repository.dart";

/// 材料管理サービス
class MaterialManagementService with LoggerMixin {
  MaterialManagementService({
    MaterialRepository? materialRepository,
    MaterialCategoryRepository? materialCategoryRepository,
  }) : _materialRepository = materialRepository ?? MaterialRepository(),
       _materialCategoryRepository = materialCategoryRepository ?? MaterialCategoryRepository();

  final MaterialRepository _materialRepository;
  final MaterialCategoryRepository _materialCategoryRepository;

  @override
  String get loggerComponent => "MaterialManagementService";

  /// 材料を作成
  Future<Material?> createMaterial(Material material, String userId) async {
    logInfoMessage(ServiceInfo.materialCreationStarted, <String, String>{
      "materialName": material.name,
    });

    try {
      // ユーザーIDを設定
      material.userId = userId;
      final Material? createdMaterial = await _materialRepository.create(material);

      if (createdMaterial != null) {
        logInfoMessage(ServiceInfo.materialCreationSuccessful, <String, String>{
          "materialName": material.name,
        });
      } else {
        logWarningMessage(ServiceWarning.creationFailed, <String, String>{
          "entityType": "material: ${material.name}",
        });
      }

      return createdMaterial;
    } catch (e, stackTrace) {
      logErrorMessage(
        ServiceError.materialCreationFailed,
        <String, String>{"materialName": material.name},
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 材料カテゴリ一覧を取得
  Future<List<MaterialCategory>> getMaterialCategories(String userId) async =>
      _materialCategoryRepository.findActiveOrdered(userId);

  /// カテゴリ別材料一覧を取得
  Future<List<Material>> getMaterialsByCategory(String? categoryId, String userId) async =>
      _materialRepository.findByCategoryId(categoryId, userId);

  /// 材料のアラート閾値を更新
  Future<Material?> updateMaterialThresholds(
    String materialId,
    double alertThreshold,
    double criticalThreshold,
    String userId,
  ) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(materialId);
    if (material == null || material.userId != userId) {
      throw Exception("Material not found or access denied");
    }

    // 閾値の妥当性チェック
    if (criticalThreshold > alertThreshold) {
      throw Exception("Critical threshold must be less than or equal to alert threshold");
    }

    if (criticalThreshold < 0 || alertThreshold < 0) {
      throw Exception("Thresholds must be non-negative");
    }

    // 閾値を更新
    material
      ..alertThreshold = alertThreshold
      ..criticalThreshold = criticalThreshold;

    // 材料を更新して返す
    return _materialRepository.updateById(materialId, <String, dynamic>{
      "alert_threshold": alertThreshold,
      "critical_threshold": criticalThreshold,
    });
  }
}
