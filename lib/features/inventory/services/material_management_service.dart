import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/logging/logger_mixin.dart";
import "../../../core/validation/input_validator.dart";
import "../models/inventory_model.dart";
import "../repositories/material_category_repository.dart";
import "../repositories/material_repository.dart";

/// 材料管理サービス
class MaterialManagementService with LoggerMixin {
  MaterialManagementService({
    required Ref ref,
    MaterialRepository? materialRepository,
    MaterialCategoryRepository? materialCategoryRepository,
  }) : _materialRepository = materialRepository ?? MaterialRepository(ref: ref),
       _materialCategoryRepository = materialCategoryRepository ?? MaterialCategoryRepository(ref: ref);

  final MaterialRepository _materialRepository;
  final MaterialCategoryRepository _materialCategoryRepository;

  @override
  String get loggerComponent => "MaterialManagementService";

  /// 材料を作成
  Future<Material?> createMaterial(Material material) async {
    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(
        material.name,
        required: true,
        maxLength: 100,
        fieldName: "材料名",
      ),
      InputValidator.validateNumber(material.currentStock, min: 0, fieldName: "現在在庫量"),
      InputValidator.validateNumber(material.alertThreshold, min: 0, fieldName: "アラート閾値"),
      InputValidator.validateNumber(material.criticalThreshold, min: 0, fieldName: "危険閾値"),
    ];

    // 閾値の妥当性検証
    if (material.criticalThreshold > material.alertThreshold) {
      validationResults.add(ValidationResult.error("危険閾値はアラート閾値以下である必要があります"));
    }

    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      final List<String> errorMessages = InputValidator.getErrorMessages(errors);
      logError("Validation failed for material creation: ${errorMessages.join(', ')}");
      throw ValidationException(errorMessages);
    }

    logInfoMessage(ServiceInfo.materialCreationStarted, <String, String>{
      "materialName": material.name,
    });

    try {
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
  Future<List<MaterialCategory>> getMaterialCategories() async =>
      _materialCategoryRepository.findActiveOrdered();

  /// カテゴリ別材料一覧を取得
  Future<List<Material>> getMaterialsByCategory(String? categoryId) async =>
      _materialRepository.findByCategoryId(categoryId);

  /// 材料を更新
  Future<Material?> updateMaterial(Material material) async {
    if (material.id == null) {
      throw ArgumentError("Material ID is required for update");
    }

    // 既存の材料を確認
    final Material? existingMaterial = await _materialRepository.getById(material.id!);
    if (existingMaterial == null) {
      throw Exception("Material not found");
    }

    // 入力検証
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(
        material.name,
        required: true,
        maxLength: 100,
        fieldName: "材料名",
      ),
      InputValidator.validateNumber(material.currentStock, min: 0, fieldName: "現在在庫量"),
      InputValidator.validateNumber(material.alertThreshold, min: 0, fieldName: "アラート閾値"),
      InputValidator.validateNumber(material.criticalThreshold, min: 0, fieldName: "危険閾値"),
    ];

    // 閾値の妥当性検証
    if (material.criticalThreshold > material.alertThreshold) {
      validationResults.add(ValidationResult.error("危険閾値はアラート閾値以下である必要があります"));
    }

    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      final List<String> errorMessages = InputValidator.getErrorMessages(errors);
      logError("Validation failed for material update: ${errorMessages.join(', ')}");
      throw ValidationException(errorMessages);
    }

    logInfoMessage(ServiceInfo.materialCreationStarted, <String, String>{
      "materialId": material.id!,
      "materialName": material.name,
    });

    try {
      // 材料を更新
      final Material? updatedMaterial = await _materialRepository.updateById(
        material.id!,
        material.toJson(),
      );

      if (updatedMaterial != null) {
        logInfoMessage(ServiceInfo.materialCreationSuccessful, <String, String>{
          "materialId": material.id!,
          "materialName": material.name,
        });
      } else {
        logWarningMessage(ServiceWarning.updateFailed, <String, String>{
          "entityType": "material: ${material.name}",
        });
      }

      return updatedMaterial;
    } catch (e, stackTrace) {
      logErrorMessage(
        ServiceError.materialCreationFailed,
        <String, String>{
          "materialId": material.id!,
          "materialName": material.name,
        },
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 材料のアラート閾値を更新
  Future<Material?> updateMaterialThresholds(
    String materialId,
    double alertThreshold,
    double criticalThreshold,
  ) async {
    // 材料を取得
    final Material? material = await _materialRepository.getById(materialId);
    if (material == null) {
      throw Exception("Material not found");
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
