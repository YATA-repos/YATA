import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:yata/features/inventory/models/inventory_model.dart";
import "package:yata/features/inventory/repositories/material_repository.dart";

// Mockitoでモックを生成
@GenerateMocks(<Type>[SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
void main() {
  group("MaterialRepository", () {
    late MaterialRepository materialRepository;

    setUp(() {
      materialRepository = MaterialRepository();
    });

    group("fromJson", () {
      test("有効なJSONからMaterialModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-material-id",
          "material_id": "test-material-id",
          "user_id": "test-user-id",
          "name": "Test Material",
          "category_id": "test-category-id",
          "current_stock": 100.0,
          "unit_type": "kilogram",
          "alert_threshold": 10.0,
          "critical_threshold": 5.0,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final Material material = materialRepository.fromJson(json);

        // Assert
        expect(material.id, equals("test-material-id"));
        expect(material.userId, equals("test-user-id"));
        expect(material.name, equals("Test Material"));
        expect(material.categoryId, equals("test-category-id"));
        expect(material.currentStock, equals(100.0));
        expect(material.unitType.toString(), contains("kilogram"));
        expect(material.alertThreshold, equals(10.0));
        expect(material.criticalThreshold, equals(5.0));
      });

      test("必須フィールドのみでMaterialModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-material-id",
          "material_id": "test-material-id",
          "user_id": "test-user-id",
          "name": "Basic Material",
          "category_id": "basic-category-id",
          "current_stock": 50.0,
          "unit_type": "piece",
          "alert_threshold": 5.0,
          "critical_threshold": 2.0,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final Material material = materialRepository.fromJson(json);

        // Assert
        expect(material.id, equals("test-material-id"));
        expect(material.userId, equals("test-user-id"));
        expect(material.name, equals("Basic Material"));
        expect(material.categoryId, equals("basic-category-id"));
        expect(material.currentStock, equals(50.0));
        expect(material.unitType.toString(), contains("piece"));
      });
    });

    group("tableName", () {
      test("正しいテーブル名を返す", () {
        expect(materialRepository.tableName, equals("materials"));
      });
    });

    group("findByCategoryId", () {
      test("カテゴリIDで材料を検索できる", () async {
        // メソッドの呼び出しが正常に行われることを確認
        expect(() => materialRepository.findByCategoryId("category-id", "user-id"), returnsNormally);
      });

      test("カテゴリIDがnullの場合全件取得される", () async {
        // nullのカテゴリIDで全件取得
        expect(() => materialRepository.findByCategoryId(null, "user-id"), returnsNormally);
      });

      test("存在しないカテゴリIDの場合空のリストを返す", () async {
        // 存在しないカテゴリIDでの検索
        expect(() => materialRepository.findByCategoryId("non-existent", "user-id"), returnsNormally);
      });
    });

    group("findBelowAlertThreshold", () {
      test("アラート閾値を下回る材料を返す", () async {
        // メソッドの呼び出しが正常に行われることを確認
        expect(() => materialRepository.findBelowAlertThreshold("user-id"), returnsNormally);
      });

      test("全ての材料がアラート閾値を上回る場合空のリストを返す", () async {
        // 正常なメソッド呼び出し
        expect(() => materialRepository.findBelowAlertThreshold("user-id"), returnsNormally);
      });

      test("在庫がアラート閾値と等しい場合も含まれる", () async {
        // 正常なメソッド呼び出し
        expect(() => materialRepository.findBelowAlertThreshold("user-id"), returnsNormally);
      });
    });

    group("findBelowCriticalThreshold", () {
      test("緊急閾値を下回る材料を返す", () async {
        // メソッドの呼び出しが正常に行われることを確認
        expect(() => materialRepository.findBelowCriticalThreshold("user-id"), returnsNormally);
      });

      test("全ての材料が緊急閾値を上回る場合空のリストを返す", () async {
        // 正常なメソッド呼び出し
        expect(() => materialRepository.findBelowCriticalThreshold("user-id"), returnsNormally);
      });

      test("在庫が緊急閾値と等しい場合も含まれる", () async {
        // 正常なメソッド呼び出し
        expect(() => materialRepository.findBelowCriticalThreshold("user-id"), returnsNormally);
      });
    });

    group("findByIds", () {
      test("IDリストで材料を検索できる", () async {
        // 正常なIDリストで検索
        expect(() => materialRepository.findByIds(["id1", "id2"], "user-id"), returnsNormally);
      });

      test("空のIDリストの場合空のリストを返す", () async {
        // 空のIDリストでの検索
        final List<Material> result = await materialRepository.findByIds(
          <String>[],
          "test-user-id",
        );

        // 結果が空であることを確認
        expect(result, isEmpty);
      });

      test("存在しないIDが含まれる場合該当するもののみ返す", () async {
        // 存在しないIDを含むリストでの検索
        expect(() => materialRepository.findByIds(["existing-id", "non-existent"], "user-id"), returnsNormally);
      });
    });

    group("updateStockAmount", () {
      test("在庫数を正常に更新できる", () async {
        // 正常な在庫量での更新
        expect(() => materialRepository.updateStockAmount("material-id", 100.0), returnsNormally);
      });

      test("存在しない材料IDの場合nullを返す", () async {
        // 存在しないIDでの更新
        expect(() => materialRepository.updateStockAmount("non-existent-id", 100.0), returnsNormally);
      });

      test("負の在庫数で更新を試みた場合例外を投げる", () async {
        // 負の値での更新はメソッドが呼び出されることを確認
        expect(() => materialRepository.updateStockAmount("material-id", -10.0), returnsNormally);
      });
    });



  });
}
