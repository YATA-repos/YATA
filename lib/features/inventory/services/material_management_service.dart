import "../../../core/base/base_error_msg.dart";
import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/contracts/repositories/inventory/material_category_repository_contract.dart";
import "../../../core/contracts/repositories/inventory/material_repository_contract.dart";
import "../../../core/contracts/logging/logger.dart" as log_contract;
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
