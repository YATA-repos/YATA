import "dart:io";
import "package:csv/csv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/constants/enums.dart";
import "../../../core/constants/exceptions/exceptions.dart";
import "../../../core/logging/logger_mixin.dart";
import "../models/inventory_model.dart";
import "material_management_service.dart";

/// CSVインポート用のデータ構造
class CSVImportResult {
  const CSVImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.importedMaterials,
  });

  final int successCount;
  final int errorCount;
  final List<CSVImportError> errors;
  final List<Material> importedMaterials;

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => errorCount == 0 && successCount > 0;
}

/// CSVインポートエラー情報
class CSVImportError {
  const CSVImportError({
    required this.row,
    required this.column,
    required this.value,
    required this.message,
  });

  final int row;
  final String? column;
  final String value;
  final String message;

  @override
  String toString() => 'Row $row, Column $column: $message (Value: "$value")';
}

/// CSVインポートプレビューデータ
class CSVImportPreview {
  const CSVImportPreview({
    required this.headers,
    required this.materials,
    required this.validationErrors,
  });

  final List<String> headers;
  final List<Material> materials;
  final List<CSVImportError> validationErrors;

  bool get hasValidationErrors => validationErrors.isNotEmpty;
}

/// CSVインポートサービス
class CSVImportService with LoggerMixin {
  CSVImportService({
    required Ref ref,
    MaterialManagementService? materialManagementService,
  }) : _materialManagementService = materialManagementService ?? MaterialManagementService(ref: ref);

  final MaterialManagementService _materialManagementService;

  @override
  String get loggerComponent => "CSVImportService";

  /// 期待されるCSVヘッダー
  static const List<String> expectedHeaders = <String>[
    "name",
    "category_id",
    "unit_type",
    "current_stock",
    "alert_threshold",
    "critical_threshold",
    "notes",
  ];

  /// CSVファイルをプレビュー用に解析
  Future<CSVImportPreview> previewCSVFile(File csvFile) async {
    logInfo("Starting CSV preview for file: ${csvFile.path}");

    try {
      final String csvContent = await csvFile.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty) {
        throw ValidationException(<String>["CSVファイルが空です"]);
      }

      // ヘッダー行を取得
      final List<String> headers = csvData.first.map((dynamic e) => e.toString()).toList();
      
      // ヘッダーの検証
      final List<CSVImportError> headerErrors = _validateHeaders(headers);
      if (headerErrors.isNotEmpty) {
        return CSVImportPreview(
          headers: headers,
          materials: <Material>[],
          validationErrors: headerErrors,
        );
      }

      // データ行を解析
      final List<Material> materials = <Material>[];
      final List<CSVImportError> validationErrors = <CSVImportError>[];

      for (int i = 1; i < csvData.length; i++) {
        final List<dynamic> row = csvData[i];
        final Map<String, dynamic> rowData = _rowToMap(headers, row);
        
        try {
          final Material material = _createMaterialFromRow(rowData, i + 1);
          materials.add(material);
        } catch (e) {
          if (e is List<CSVImportError>) {
            validationErrors.addAll(e);
          } else {
            validationErrors.add(CSVImportError(
              row: i + 1,
              column: null,
              value: row.toString(),
              message: e.toString(),
            ));
          }
        }
      }

      logInfo("CSV preview completed. Materials: ${materials.length}, Errors: ${validationErrors.length}");

      return CSVImportPreview(
        headers: headers,
        materials: materials,
        validationErrors: validationErrors,
      );
    } catch (e, stackTrace) {
      logError("Failed to preview CSV file", e, stackTrace);
      rethrow;
    }
  }

  /// CSVファイルからの材料インポート実行
  Future<CSVImportResult> importMaterialsFromCSV(
    File csvFile,
    String userId, {
    bool skipInvalidRows = false,
  }) async {
    logInfo("Starting CSV import for file: ${csvFile.path}");

    try {
      final CSVImportPreview preview = await previewCSVFile(csvFile);
      
      if (preview.hasValidationErrors && !skipInvalidRows) {
        throw ValidationException(<String>[
          "CSVファイルに検証エラーがあります。プレビューで確認してください。",
        ]);
      }

      final List<Material> importedMaterials = <Material>[];
      final List<CSVImportError> errors = <CSVImportError>[];
      int successCount = 0;

      // 有効な材料のみをインポート
      for (final Material material in preview.materials) {
        try {
          final Material? imported = await _materialManagementService.createMaterial(
            material,
          );
          
          if (imported != null) {
            importedMaterials.add(imported);
            successCount++;
            logInfo("Successfully imported material: ${material.name}");
          } else {
            errors.add(CSVImportError(
              row: 0, // 行番号は追跡困難
              column: null,
              value: material.name,
              message: "材料の作成に失敗しました",
            ));
          }
        } catch (e) {
          errors.add(CSVImportError(
            row: 0,
            column: null,
            value: material.name,
            message: "インポートエラー: ${e.toString()}",
          ));
        }
      }

      // プレビューで検出されたエラーも含める
      errors.addAll(preview.validationErrors);

      final CSVImportResult result = CSVImportResult(
        successCount: successCount,
        errorCount: errors.length,
        errors: errors,
        importedMaterials: importedMaterials,
      );

      logInfo("CSV import completed. Success: $successCount, Errors: ${errors.length}");
      return result;
    } catch (e, stackTrace) {
      logError("Failed to import CSV file", e, stackTrace);
      rethrow;
    }
  }

  /// ヘッダーの検証
  List<CSVImportError> _validateHeaders(List<String> headers) {
    final List<CSVImportError> errors = <CSVImportError>[];

    // 必須ヘッダーのチェック
    final List<String> requiredHeaders = <String>["name", "category_id", "unit_type", "current_stock"];
    for (final String required in requiredHeaders) {
      if (!headers.contains(required)) {
        errors.add(CSVImportError(
          row: 1,
          column: required,
          value: "",
          message: "必須ヘッダー \"$required\" が見つかりません",
        ));
      }
    }

    // 未知のヘッダーの警告
    for (final String header in headers) {
      if (!expectedHeaders.contains(header)) {
        errors.add(CSVImportError(
          row: 1,
          column: header,
          value: header,
          message: '未知のヘッダー "$header" です（無視されます）',
        ));
      }
    }

    return errors;
  }

  /// 行データをMapに変換
  Map<String, dynamic> _rowToMap(List<String> headers, List<dynamic> row) {
    final Map<String, dynamic> rowData = <String, dynamic>{};
    
    for (int i = 0; i < headers.length && i < row.length; i++) {
      rowData[headers[i]] = row[i];
    }
    
    return rowData;
  }

  /// 行データからMaterialオブジェクトを作成
  Material _createMaterialFromRow(Map<String, dynamic> rowData, int rowNumber) {
    final List<CSVImportError> errors = <CSVImportError>[];

    // 必須フィールドの検証
    final String? name = rowData["name"]?.toString().trim();
    if (name == null || name.isEmpty) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "name",
        value: rowData["name"]?.toString() ?? "",
        message: "材料名は必須です",
      ));
    }

    final String? categoryId = rowData["category_id"]?.toString().trim();
    if (categoryId == null || categoryId.isEmpty) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "category_id",
        value: rowData["category_id"]?.toString() ?? "",
        message: "カテゴリIDは必須です",
      ));
    }

    // 単位タイプの解析
    UnitType? unitType;
    final String? unitTypeStr = rowData["unit_type"]?.toString().trim().toLowerCase();
    if (unitTypeStr == null || unitTypeStr.isEmpty) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "unit_type",
        value: rowData["unit_type"]?.toString() ?? "",
        message: "単位タイプは必須です",
      ));
    } else {
      switch (unitTypeStr) {
        case "piece":
        case "個":
        case "個数":
          unitType = UnitType.piece;
          break;
        case "gram":
        case "g":
        case "グラム":
          unitType = UnitType.gram;
          break;
        default:
          errors.add(CSVImportError(
            row: rowNumber,
            column: "unit_type",
            value: unitTypeStr,
            message: "単位タイプは 'piece' または 'gram' である必要があります",
          ));
      }
    }

    // 数値フィールドの検証
    double? currentStock;
    try {
      currentStock = double.parse(rowData["current_stock"]?.toString() ?? "0");
      if (currentStock < 0) {
        errors.add(CSVImportError(
          row: rowNumber,
          column: "current_stock",
          value: rowData["current_stock"]?.toString() ?? "",
          message: "現在在庫量は0以上である必要があります",
        ));
      }
    } catch (e) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "current_stock",
        value: rowData["current_stock"]?.toString() ?? "",
        message: "現在在庫量は数値で入力してください",
      ));
    }

    double alertThreshold = 10.0;
    try {
      alertThreshold = double.parse(rowData["alert_threshold"]?.toString() ?? "10.0");
      if (alertThreshold < 0) {
        errors.add(CSVImportError(
          row: rowNumber,
          column: "alert_threshold",
          value: rowData["alert_threshold"]?.toString() ?? "",
          message: "アラート閾値は0以上である必要があります",
        ));
      }
    } catch (e) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "alert_threshold",
        value: rowData["alert_threshold"]?.toString() ?? "",
        message: "アラート閾値は数値で入力してください",
      ));
    }

    double criticalThreshold = 5.0;
    try {
      criticalThreshold = double.parse(rowData["critical_threshold"]?.toString() ?? "5.0");
      if (criticalThreshold < 0) {
        errors.add(CSVImportError(
          row: rowNumber,
          column: "critical_threshold",
          value: rowData["critical_threshold"]?.toString() ?? "",
          message: "危険閾値は0以上である必要があります",
        ));
      }
    } catch (e) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "critical_threshold",
        value: rowData["critical_threshold"]?.toString() ?? "",
        message: "危険閾値は数値で入力してください",
      ));
    }

    // 閾値の関係性チェック
    if (criticalThreshold > alertThreshold) {
      errors.add(CSVImportError(
        row: rowNumber,
        column: "critical_threshold",
        value: criticalThreshold.toString(),
        message: "危険閾値はアラート閾値以下である必要があります",
      ));
    }

    if (errors.isNotEmpty) {
      throw errors;
    }

    // Materialオブジェクトを作成
    return Material(
      name: name!,
      categoryId: categoryId!,
      unitType: unitType!,
      currentStock: currentStock ?? 0.0,
      alertThreshold: alertThreshold,
      criticalThreshold: criticalThreshold,
      notes: rowData["notes"]?.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}