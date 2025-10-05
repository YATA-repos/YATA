import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/contracts/repositories/inventory/material_category_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
import "../../../core/constants/query_types.dart";
import "../../../core/validation/input_validator.dart";
import "../models/inventory_model.dart";

/// 材料管理サービス
class MaterialManagementService {
  MaterialManagementService({
    required log_contract.LoggerContract logger,
    required MaterialRepositoryContract<Material> materialRepository,
    required MaterialCategoryRepositoryContract<MaterialCategory> materialCategoryRepository,
  }) : _logger = logger,
       _materialRepository = materialRepository,
       _materialCategoryRepository = materialCategoryRepository;

  final log_contract.LoggerContract _logger;
  log_contract.LoggerContract get log => _logger;

  final MaterialRepositoryContract<Material> _materialRepository;
  final MaterialCategoryRepositoryContract<MaterialCategory> _materialCategoryRepository;

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
      log.e(
        "Validation failed for material creation: ${errorMessages.join(', ')}",
        tag: loggerComponent,
      );
      throw ValidationException(errorMessages);
    }

    log.i(
      ServiceInfo.materialCreationStarted.withParams(<String, String>{
        "materialName": material.name,
      }),
      tag: loggerComponent,
    );

    try {
      final Material? createdMaterial = await _materialRepository.create(material);

      if (createdMaterial != null) {
        log.i(
          ServiceInfo.materialCreationSuccessful.withParams(<String, String>{
            "materialName": material.name,
          }),
          tag: loggerComponent,
        );
      } else {
        log.w(
          ServiceWarning.creationFailed.withParams(<String, String>{
            "entityType": "material: ${material.name}",
          }),
          tag: loggerComponent,
        );
      }

      return createdMaterial;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.materialCreationFailed.withParams(<String, String>{
          "materialName": material.name,
        }),
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 材料カテゴリ一覧を取得
  Future<List<MaterialCategory>> getMaterialCategories() async =>
      _materialCategoryRepository.findActiveOrdered();

  /// 材料カテゴリを作成
  Future<MaterialCategory?> createCategory(MaterialCategory category) async {
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateString(
        category.name,
        required: true,
        maxLength: 100,
        fieldName: "カテゴリ名",
      ),
      InputValidator.validateNumber(
        category.displayOrder,
        min: 0,
        fieldName: "表示順序",
      ),
    ];

    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      final List<String> errorMessages = InputValidator.getErrorMessages(errors);
      log.e(
        "Validation failed for material category creation: ${errorMessages.join(', ')}",
        tag: loggerComponent,
      );
      throw ValidationException(errorMessages);
    }

    log.i(
      ServiceInfo.operationStarted.withParams(<String, String>{
        "operationType": "create_material_category",
      }),
      tag: loggerComponent,
    );

    try {
      final MaterialCategory? createdCategory = await _materialCategoryRepository.create(category);
      if (createdCategory != null) {
        log.i(
          ServiceInfo.creationSuccessful.withParams(<String, String>{
            "entityType": "material_category:${createdCategory.name}",
          }),
          tag: loggerComponent,
        );
      } else {
        log.w(
          ServiceWarning.creationFailed.withParams(<String, String>{
            "entityType": "material_category:${category.name}",
          }),
          tag: loggerComponent,
        );
      }
      return createdCategory;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.operationFailed.withParams(<String, String>{
          "operationType": "create_material_category",
        }),
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 材料カテゴリを更新
  Future<MaterialCategory?> updateCategory(MaterialCategory category) async {
    if (category.id == null || category.id!.isEmpty) {
      throw ArgumentError("Category ID is required for update");
    }

    final String trimmedName = category.name.trim();
    final List<ValidationResult> validationResults = <ValidationResult>[
      InputValidator.validateCategoryName(trimmedName),
      InputValidator.validateNumber(
        category.displayOrder,
        min: 0,
        fieldName: "表示順序",
      ),
    ];

    final List<ValidationResult> errors = InputValidator.validateAll(validationResults);
    if (errors.isNotEmpty) {
      final List<String> errorMessages = InputValidator.getErrorMessages(errors);
      log.e(
        "Validation failed for material category update: ${errorMessages.join(', ')}",
        tag: loggerComponent,
      );
      throw ValidationException(errorMessages);
    }

    final MaterialCategory? existing = await _materialCategoryRepository.getById(category.id!);
    if (existing == null) {
      log.w(
        ServiceWarning.entityNotFound.withParams(<String, String>{
          "entityType": "material_category:${category.id}",
        }),
        tag: loggerComponent,
      );
      throw ServiceException.operationFailed(
        "update_material_category",
        "Category not found",
      );
    }

    final List<QueryFilter> duplicateFilters = <QueryFilter>[
      QueryConditionBuilder.eq("name", trimmedName),
      if (existing.userId != null) QueryConditionBuilder.eq("user_id", existing.userId),
      QueryConditionBuilder.neq("id", category.id!),
    ];

    final int duplicateCount = await _materialCategoryRepository.count(filters: duplicateFilters);
    if (duplicateCount > 0) {
      const String message = "同じ名前のカテゴリが既に存在します";
      log.w(
        "Duplicate category name detected during update: $trimmedName",
        tag: loggerComponent,
      );
      throw ValidationException(<String>[message]);
    }

    log.i(
      ServiceInfo.operationStarted.withParams(<String, String>{
        "operationType": "update_material_category",
      }),
      tag: loggerComponent,
    );

    final Map<String, dynamic> updatePayload = <String, dynamic>{
      "name": trimmedName,
      "display_order": category.displayOrder,
      "updated_at": DateTime.now().toIso8601String(),
    };

    try {
      final MaterialCategory? updatedCategory = await _materialCategoryRepository.updateById(
        category.id!,
        updatePayload,
      );

      if (updatedCategory != null) {
        log.i(
          ServiceInfo.updateSuccessful.withParams(<String, String>{
            "entityType": "material_category:${updatedCategory.id ?? category.id}",
          }),
          tag: loggerComponent,
        );
      } else {
        log.w(
          ServiceWarning.updateFailed.withParams(<String, String>{
            "entityType": "material_category:${category.id}",
          }),
          tag: loggerComponent,
        );
      }

      return updatedCategory;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.operationFailed.withParams(<String, String>{
          "operationType": "update_material_category",
        }),
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

  /// 材料カテゴリを削除
  Future<void> deleteCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      throw ArgumentError("Category ID is required for deletion");
    }

    final MaterialCategory? existing = await _materialCategoryRepository.getById(categoryId);
    if (existing == null) {
      log.w(
        ServiceWarning.entityNotFound.withParams(<String, String>{
          "entityType": "material_category:$categoryId",
        }),
        tag: loggerComponent,
      );
      throw ServiceException.operationFailed(
        "delete_material_category",
        "Category not found",
      );
    }

    final int linkedMaterialCount = await _materialRepository.count(
      filters: <QueryFilter>[QueryConditionBuilder.eq("category_id", categoryId)],
    );

    if (linkedMaterialCount > 0) {
      const String message = "このカテゴリに紐づく在庫アイテムが存在するため削除できません";
      log.w(
        ServiceWarning.operationFailed.withParams(<String, String>{
          "operationType": "delete_material_category",
        }),
        tag: loggerComponent,
      );
      throw ValidationException(<String>[message]);
    }

    log.i(
      ServiceInfo.operationStarted.withParams(<String, String>{
        "operationType": "delete_material_category",
      }),
      tag: loggerComponent,
    );

    try {
      await _materialCategoryRepository.deleteById(categoryId);
      log.i(
        ServiceInfo.deletionSuccessful.withParams(<String, String>{
          "entityType": "material_category:${existing.name}",
        }),
        tag: loggerComponent,
      );
    } catch (e, stackTrace) {
      log.e(
        ServiceError.operationFailed.withParams(<String, String>{
          "operationType": "delete_material_category",
        }),
        tag: loggerComponent,
        error: e,
        st: stackTrace,
      );
      rethrow;
    }
  }

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
      log.e(
        "Validation failed for material update: ${errorMessages.join(', ')}",
        tag: loggerComponent,
      );
      throw ValidationException(errorMessages);
    }

    log.i(
      ServiceInfo.materialCreationStarted.withParams(<String, String>{
        "materialId": material.id!,
        "materialName": material.name,
      }),
      tag: loggerComponent,
    );

    try {
      // 材料を更新
      final Material? updatedMaterial = await _materialRepository.updateById(
        material.id!,
        material.toJson(),
      );

      if (updatedMaterial != null) {
        log.i(
          ServiceInfo.materialCreationSuccessful.withParams(<String, String>{
            "materialId": material.id!,
            "materialName": material.name,
          }),
          tag: loggerComponent,
        );
      } else {
        log.w(
          ServiceWarning.updateFailed.withParams(<String, String>{
            "entityType": "material: ${material.name}",
          }),
          tag: loggerComponent,
        );
      }

      return updatedMaterial;
    } catch (e, stackTrace) {
      log.e(
        ServiceError.materialCreationFailed.withParams(<String, String>{
          "materialId": material.id!,
          "materialName": material.name,
        }),
        tag: loggerComponent,
        error: e,
        st: stackTrace,
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
