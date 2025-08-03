import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/enums.dart";
import "../../../../core/utils/provider_logger.dart";
import "../../../inventory/dto/inventory_dto.dart";
import "../../dto/menu_dto.dart";
import "../../models/menu_model.dart";
import "../../services/menu_service.dart";

part "menu_providers.g.dart";

/// MenuService プロバイダー
/// 既存の高度なMenuServiceをRiverpodで利用可能にする
/// **ライフサイクル**: keepAlive（サービスクラスは永続化）
/// **データ性質**: service, **アクセス頻度**: high
@riverpod
MenuService menuService(Ref ref) {
  ref.keepAlive(); // サービスインスタンスは永続化
  ProviderLogger.info("MenuProviders", "MenuServiceを初期化しました");
  return MenuService(ref: ref);
}

/// メニューカテゴリー一覧プロバイダー
/// 既存のMenuService.getMenuCategoriesを直接活用
/// **ライフサイクル**: keepAlive（マスターデータ・高頻度アクセス）
/// **データ性質**: masterData, **アクセス頻度**: high
@riverpod
Future<List<MenuCategory>> menuCategories(Ref ref) async {
  ref.keepAlive(); // マスターデータは永続キャッシュ
  try {
    ProviderLogger.debug("MenuProviders", "メニューカテゴリー一覧取得を開始");
    final MenuService service = ref.watch(menuServiceProvider);
    final List<MenuCategory> result = await service.getMenuCategories();
    ProviderLogger.info("MenuProviders", "メニューカテゴリー一覧取得が完了: ${result.length}件");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("MenuProviders", "menuCategories", e, stackTrace);
    rethrow;
  }
}

/// カテゴリー別メニューアイテム一覧プロバイダー
/// 既存のMenuService.getMenuItemsByCategoryを直接活用
/// **ライフサイクル**: keepAlive（マスターデータ・高頻度アクセス）
/// **データ性質**: masterData, **アクセス頻度**: high
@riverpod
Future<List<MenuItem>> menuItems(Ref ref, String? categoryId) async {
  ref.keepAlive(); // マスターデータは永続キャッシュ
  try {
    ProviderLogger.debug("MenuProviders", "カテゴリー別メニューアイテム一覧取得を開始: $categoryId");
    final MenuService service = ref.watch(menuServiceProvider);
    final List<MenuItem> result = await service.getMenuItemsByCategory(categoryId);
    ProviderLogger.info("MenuProviders", "カテゴリー別メニューアイテム一覧取得が完了: ${result.length}件");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("MenuProviders", "menuItems", e, stackTrace);
    rethrow;
  }
}

/// メニューアイテム検索プロバイダー
/// 既存のMenuService.searchMenuItemsを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・中頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: medium
@riverpod
Future<List<MenuItem>> searchMenuItems(
  Ref ref,
  String keyword,
  String userId,
) async {
  // 検索結果は一時的なため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.searchMenuItems(keyword, userId);
}

/// メニューアイテム可否チェックプロバイダー
/// 既存のMenuService.checkMenuAvailabilityを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・高頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: high
@riverpod
Future<MenuAvailabilityInfo> menuAvailability(
  Ref ref,
  String menuItemId,
  int quantity,
  String userId,
) async {
  // 可否情報は在庫に依存し頻繁に変わるため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.checkMenuAvailability(menuItemId, quantity, userId);
}

/// 全メニューアイテム可否一括チェックプロバイダー
/// 既存のMenuService.bulkCheckMenuAvailabilityを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・中頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: medium
@riverpod
Future<Map<String, MenuAvailabilityInfo>> bulkMenuAvailability(
  Ref ref,
  String userId,
) async {
  // 一括可否チェックは計算コストが高いが在庫変動で変わるため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.bulkCheckMenuAvailability(userId);
}

/// 在庫不足メニューアイテムプロバイダー
/// 既存のMenuService.getUnavailableMenuItemsを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・高頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: high
@riverpod
Future<List<String>> unavailableMenuItems(Ref ref, String userId) async {
  // 在庫不足アイテムは頻繁に変わるため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getUnavailableMenuItems(userId);
}

/// 最大作成可能数計算プロバイダー
/// 既存のMenuService.calculateMaxServingsを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・中頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: medium
@riverpod
Future<int> maxServings(Ref ref, String menuItemId, String userId) async {
  // 最大作成数は在庫に依存し変動するため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.calculateMaxServings(menuItemId, userId);
}

/// 材料使用量計算プロバイダー
/// 既存のMenuService.getRequiredMaterialsForMenuを直接活用
/// **ライフサイクル**: AutoDispose（userDynamic・低頻度アクセス）
/// **データ性質**: userDynamic, **アクセス頻度**: low
@riverpod
Future<List<MaterialUsageCalculation>> requiredMaterials(
  Ref ref,
  String menuItemId,
  int quantity,
  String userId,
) async {
  // 材料使用量計算は一時的な計算結果のため自動破棄
  final MenuService service = ref.watch(menuServiceProvider);
  return service.getRequiredMaterialsForMenu(menuItemId, quantity, userId);
}

/// UI状態管理：選択中カテゴリー
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: high
@riverpod
class SelectedMenuCategory extends _$SelectedMenuCategory {
  @override
  String build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return "all"; // デフォルトは全カテゴリー
  }

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
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: high
@riverpod
class MenuSearchQuery extends _$MenuSearchQuery {
  @override
  String build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return "";
  }

  /// 検索クエリを更新
  void updateQuery(String query) {
    state = query;
  }

  /// 検索クエリをクリア
  void clearQuery() {
    state = "";
  }
}

/// UI状態管理：メニュー表示モード
/// **ライフサイクル**: keepAlive（UI状態は永続化）
/// **データ性質**: uiState, **アクセス頻度**: medium
@riverpod
class MenuDisplayModeNotifier extends _$MenuDisplayModeNotifier {
  @override
  MenuDisplayMode build() {
    ref.keepAlive(); // UI状態は画面使用中は永続化
    return MenuDisplayMode.grid;
  }

  /// 表示モードを切り替え
  void toggleMode() {
    state = state == MenuDisplayMode.grid ? MenuDisplayMode.list : MenuDisplayMode.grid;
  }

  /// 特定のモードに設定
  void setMode(MenuDisplayMode mode) {
    state = mode;
  }
}
