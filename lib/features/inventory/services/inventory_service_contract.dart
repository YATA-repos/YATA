import "../dto/inventory_dto.dart";
import "../dto/transaction_dto.dart";
import "../models/inventory_model.dart";

/// 在庫サービスの共通契約。
abstract interface class InventoryServiceContract {
  /// 材料カテゴリ一覧を取得する。
  Future<List<MaterialCategory>> getMaterialCategories();

  /// 在庫情報を取得する。
  Future<List<MaterialStockInfo>> getMaterialsWithStockInfo(String? categoryId, String userId);

  /// 材料を新規作成する。
  Future<Material?> createMaterial(Material material);

  /// 材料カテゴリを新規作成する。
  Future<MaterialCategory?> createMaterialCategory(MaterialCategory category);

  /// 材料カテゴリを更新する。
  Future<MaterialCategory?> updateMaterialCategory(MaterialCategory category);

  /// 材料カテゴリを削除する。
  Future<void> deleteMaterialCategory(String categoryId);

  /// 材料情報を更新する。
  Future<Material?> updateMaterial(Material material);

  /// 在庫数量を更新する。
  Future<Material?> updateMaterialStock(StockUpdateRequest request, String userId);
}
