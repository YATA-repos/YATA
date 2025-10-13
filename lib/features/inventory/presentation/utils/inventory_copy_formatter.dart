import "../../../../shared/utils/unit_config.dart";
import "../controllers/inventory_management_controller.dart";

/// 在庫関連のコピー文言を生成するヘルパー。
class InventoryCopyFormatter {
  const InventoryCopyFormatter._();

  /// 「在庫 N」形式のラベルを返す。
  static String stockLabel(InventoryItemViewData item) {
    final String value = UnitFormatter.format(item.current, item.unitType);
    final String unit = item.unit.trim();
    if (unit.isEmpty) {
      return "在庫 $value";
    }
    return "在庫 $value$unit";
  }
}
