/// メニュー在庫可否情報
class MenuAvailabilityInfo {
  MenuAvailabilityInfo({
    required this.menuItemId,
    required this.isAvailable,
    required this.missingMaterials,
    this.estimatedServings,
  });

  /// JSONからオブジェクトを生成
  factory MenuAvailabilityInfo.fromJson(Map<String, dynamic> json) => MenuAvailabilityInfo(
    menuItemId: json["menu_item_id"] as String,
    isAvailable: json["is_available"] as bool,
    missingMaterials: (json["missing_materials"] as List<dynamic>).cast<String>(),
    estimatedServings: json["estimated_servings"] as int?,
  );

  /// メニューアイテムID
  String menuItemId;

  /// 利用可能かどうか
  bool isAvailable;

  /// 不足材料名のリスト
  List<String> missingMaterials;

  /// 作れる数量
  int? estimatedServings;

  /// オブジェクトをJSONに変換
  Map<String, dynamic> toJson() => <String, dynamic>{
    "menu_item_id": menuItemId,
    "is_available": isAvailable,
    "missing_materials": missingMaterials,
    "estimated_servings": estimatedServings,
  };
}
