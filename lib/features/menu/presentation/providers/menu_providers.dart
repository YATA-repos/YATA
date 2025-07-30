import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../inventory/dto/inventory_dto.dart";
import "../../dto/menu_dto.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";

part "menu_providers.g.dart";

/// MenuService プロバイダー
/// 既存の高度なMenuServiceをRiverpodで利用可能にする
@riverpod
MenuService menuService(MenuServiceRef ref) => MenuService(ref: ref);

/// メニューカテゴリー一覧プロバイダー
/// 既存のMenuService.getMenuCategoriesを直接活用
@riverpod
Future<List<MenuCategory>> menuCategories(MenuCategoriesRef ref) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getMenuCategories();
}

/// カテゴリー別メニューアイテム一覧プロバイダー
/// 既存のMenuService.getMenuItemsByCategoryを直接活用
@riverpod
Future<List<MenuItem>> menuItems(MenuItemsRef ref, String? categoryId) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getMenuItemsByCategory(categoryId);
}

/// メニューアイテム検索プロバイダー
/// 既存のMenuService.searchMenuItemsを直接活用
@riverpod
Future<List<MenuItem>> searchMenuItems(
  SearchMenuItemsRef ref,
  String keyword,
  String userId,
) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.searchMenuItems(keyword, userId);
}

/// メニューアイテム可否チェックプロバイダー
/// 既存のMenuService.checkMenuAvailabilityを直接活用
@riverpod
Future<MenuAvailabilityInfo> menuAvailability(
  MenuAvailabilityRef ref,
  String menuItemId,
  int quantity,
  String userId,
) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.checkMenuAvailability(menuItemId, quantity, userId);
}

/// 全メニューアイテム可否一括チェックプロバイダー
/// 既存のMenuService.bulkCheckMenuAvailabilityを直接活用
@riverpod
Future<Map<String, MenuAvailabilityInfo>> bulkMenuAvailability(
  BulkMenuAvailabilityRef ref,
  String userId,
) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.bulkCheckMenuAvailability(userId);
}

/// 在庫不足メニューアイテムプロバイダー
/// 既存のMenuService.getUnavailableMenuItemsを直接活用
@riverpod
Future<List<String>> unavailableMenuItems(UnavailableMenuItemsRef ref, String userId) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getUnavailableMenuItems(userId);
}

/// 最大作成可能数計算プロバイダー
/// 既存のMenuService.calculateMaxServingsを直接活用
@riverpod
Future<int> maxServings(MaxServingsRef ref, String menuItemId, String userId) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.calculateMaxServings(menuItemId, userId);
}

/// 材料使用量計算プロバイダー
/// 既存のMenuService.getRequiredMaterialsForMenuを直接活用
@riverpod
Future<List<MaterialUsageCalculation>> requiredMaterials(
  RequiredMaterialsRef ref,
  String menuItemId,
  int quantity,
  String userId,
) async {
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getRequiredMaterialsForMenu(menuItemId, quantity, userId);
}

/// UI状態管理：選択中カテゴリー
@riverpod
class SelectedMenuCategory extends _$SelectedMenuCategory {
  @override
  String build() => "all"; // デフォルトは全カテゴリー

  /// カテゴリーを選択
  void selectCategory(String categoryId) {
    state = categoryId;
  }

  /// 全カテゴリーに戻す
  void selectAll() {
    state = "all";
  }
}

/// UI状態管理：検索クエリ
@riverpod
class MenuSearchQuery extends _$MenuSearchQuery {
  @override
  String build() => "";

  /// 検索クエリを更新
  void updateQuery(String query) {
    state = query;
  }

  /// 検索クエリをクリア
  void clearQuery() {
    state = "";
  }
}

@riverpod
class MenuDisplayModeNotifier extends _$MenuDisplayModeNotifier {
  @override
  MenuDisplayMode build() => MenuDisplayMode.grid;

  /// 表示モードを切り替え
  void toggleMode() {
    state = state == MenuDisplayMode.grid ? MenuDisplayMode.list : MenuDisplayMode.grid;
  }

  /// 特定のモードに設定
  void setMode(MenuDisplayMode mode) {
    state = mode;
  }
}
