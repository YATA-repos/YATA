import "package:flutter_test/flutter_test.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/core/constants/exceptions.dart";
import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/inventory/services/material_management_service.dart";

void main() {
  group("MaterialManagementService", () {
    late MaterialManagementService materialManagementService;

    setUp(() {
      // 実際のテストでは、モックリポジトリを使用します
      materialManagementService = MaterialManagementService();
    });

    group("createMaterial", () {
      test("空の材料名が提供された場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "", // 空の名前
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 20,
          criticalThreshold: 10,
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("無効なユーザーIDが提供された場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 20,
          criticalThreshold: 10,
        );
        const String invalidUserId = ""; // 空のユーザーID

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, invalidUserId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("負の在庫量が提供された場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: -10, // 負の在庫量
          alertThreshold: 20,
          criticalThreshold: 10,
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("負のアラート閾値が提供された場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: -5, // 負のアラート閾値
          criticalThreshold: 10,
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("負の危険閾値が提供された場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 20,
          criticalThreshold: -5, // 負の危険閾値
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("危険閾値がアラート閾値より大きい場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 10,
          criticalThreshold: 20, // アラート閾値より大きい
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("材料名が制限を超える場合はValidationExceptionを投げる", () async {
        // Arrange
        final Material material = Material(
          name: "あ" * 101, // 101文字（制限を超える）
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 20,
          criticalThreshold: 10,
        );
        const String userId = "test-user";

        // Act & Assert
        await expectLater(
          materialManagementService.createMaterial(material, userId),
          throwsA(isA<ValidationException>()),
        );
      });

      test("有効な材料データの場合は検証エラーが発生しない", () async {
        // Arrange
        final Material material = Material(
          name: "テスト材料",
          categoryId: "test-category",
          unitType: UnitType.gram,
          currentStock: 100,
          alertThreshold: 20,
          criticalThreshold: 10,
        );
        const String userId = "test-user";

        // Act & Assert
        // この部分は実際のモックが必要です
        // 現在は入力検証のみをテストしています
        try {
          await materialManagementService.createMaterial(material, userId);
        } catch (e) {
          // ValidationException以外のエラーが発生した場合は想定内
          expect(e, isNot(isA<ValidationException>()));
        }
      });
    });

    // 他のメソッドのテストもここに追加します
    group("getMaterialCategories", () {
      test("無効なユーザーIDが提供された場合は適切にエラーハンドリングされる", () async {
        // 実際のテストはモックリポジトリを使用して実装
      });
    });

    group("updateMaterialThresholds", () {
      test("無効な閾値が提供された場合は適切にエラーハンドリングされる", () async {
        // 実際のテストはモックリポジトリを使用して実装
      });
    });
  });
}
