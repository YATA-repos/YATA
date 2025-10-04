import "../../dto/menu_recipe_detail.dart";
import "../../models/menu_model.dart";

/// メニュー可用性で使用するフィルター種別。
enum MenuAvailabilityFilter {
  /// すべてのメニュー。
  all,

  /// 販売可能なメニュー。
  available,

  /// 在庫不足や販売停止中のメニュー。
  unavailable,

  /// レシピ未登録など要確認のメニュー。
  attention,
}

/// カテゴリ一覧で表示する集計済みデータ。
class MenuCategoryViewData {
  /// 表示用データを生成する。
  const MenuCategoryViewData({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.totalItems,
    required this.availableItems,
    required this.attentionItems,
  });

  /// カテゴリモデルから表示データを生成する。
  factory MenuCategoryViewData.fromModel(
    MenuCategory category, {
    required int total,
    required int available,
    required int attention,
  }) => MenuCategoryViewData(
    id: category.id,
    name: category.name,
    displayOrder: category.displayOrder,
    totalItems: total,
    availableItems: available,
    attentionItems: attention,
  );

  /// カテゴリID。`null` の場合は疑似的な「すべて」カテゴリ。
  final String? id;

  /// カテゴリ名。
  final String name;

  /// 表示順。
  final int displayOrder;

  /// 登録メニュー数。
  final int totalItems;

  /// 提供可能なメニュー数。
  final int availableItems;

  /// 在庫不足やレシピ未登録など要確認のメニュー数。
  final int attentionItems;

  /// 疑似「すべて」カテゴリかどうか。
  bool get isAll => id == null;

  /// コピーを返す。
  MenuCategoryViewData copyWith({
    String? id,
    String? name,
    int? displayOrder,
    int? totalItems,
    int? availableItems,
    int? attentionItems,
  }) => MenuCategoryViewData(
    id: id ?? this.id,
    name: name ?? this.name,
    displayOrder: displayOrder ?? this.displayOrder,
    totalItems: totalItems ?? this.totalItems,
    availableItems: availableItems ?? this.availableItems,
    attentionItems: attentionItems ?? this.attentionItems,
  );
}

/// メニュー一覧テーブルで利用する表示データ。
class MenuItemViewData {
  /// 表示データを生成する。
  const MenuItemViewData({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.isStockAvailable,
    required this.categoryId,
    required this.categoryName,
    required this.displayOrder,
    required this.hasRecipe,
    required this.missingMaterials,
    this.description,
    this.imageUrl,
    this.updatedAt,
    this.estimatedServings,
  });

  /// メニューID。
  final String id;

  /// 表示名。
  final String name;

  /// 販売価格。
  final int price;

  /// 販売可否。
  final bool isAvailable;

  /// 材料在庫ベースの提供可否。
  final bool isStockAvailable;

  /// カテゴリID。
  final String categoryId;

  /// カテゴリ名。
  final String categoryName;

  /// 表示順。
  final int displayOrder;

  /// レシピが登録済みかどうか。
  final bool hasRecipe;

  /// 不足している材料名リスト。
  final List<String> missingMaterials;

  /// 説明文。
  final String? description;

  /// 画像URL。
  final String? imageUrl;

  /// 最終更新日時。
  final DateTime? updatedAt;

  /// 材料在庫から算出した最大提供数。
  final int? estimatedServings;

  /// 在庫可否が判定できているか。
  bool get hasAvailabilityCheck => estimatedServings != null || missingMaterials.isNotEmpty;

  /// 在庫に問題があるか。
  bool get hasStockIssue => !isStockAvailable || missingMaterials.isNotEmpty;

  /// 要確認状態か。
  bool get needsAttention => hasStockIssue || !hasRecipe;

  /// コピーを生成する。
  MenuItemViewData copyWith({
    String? id,
    String? name,
    int? price,
    bool? isAvailable,
    bool? isStockAvailable,
    String? categoryId,
    String? categoryName,
    int? displayOrder,
    bool? hasRecipe,
    List<String>? missingMaterials,
    String? description,
    String? imageUrl,
    DateTime? updatedAt,
    int? estimatedServings,
  }) => MenuItemViewData(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    isAvailable: isAvailable ?? this.isAvailable,
    isStockAvailable: isStockAvailable ?? this.isStockAvailable,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    displayOrder: displayOrder ?? this.displayOrder,
    hasRecipe: hasRecipe ?? this.hasRecipe,
    missingMaterials: missingMaterials ?? List<String>.from(this.missingMaterials),
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    updatedAt: updatedAt ?? this.updatedAt,
    estimatedServings: estimatedServings ?? this.estimatedServings,
  );
}

/// メニュー詳細パネルで使用するデータ。
class MenuDetailViewData {
  /// 詳細表示データを生成する。
  const MenuDetailViewData({
    required this.menu,
    required this.recipes,
    required this.availabilityLabel,
    this.maxServings,
  });

  /// メニュー本体情報。
  final MenuItemViewData menu;

  /// レシピ一覧。
  final List<MenuRecipeDetail> recipes;

  /// 可用性表示ラベル。
  final String availabilityLabel;

  /// 最大提供可能数。
  final int? maxServings;

  /// レシピの件数。
  int get recipeCount => recipes.length;

  /// 不足材料があるか。
  bool get hasMissingMaterials => menu.missingMaterials.isNotEmpty;

  /// コピーを生成する。
  MenuDetailViewData copyWith({
    MenuItemViewData? menu,
    List<MenuRecipeDetail>? recipes,
    String? availabilityLabel,
    int? maxServings,
  }) => MenuDetailViewData(
    menu: menu ?? this.menu,
    recipes: recipes ?? List<MenuRecipeDetail>.from(this.recipes),
    availabilityLabel: availabilityLabel ?? this.availabilityLabel,
    maxServings: maxServings ?? this.maxServings,
  );
}

/// メニュー管理画面の状態。
class MenuManagementState {
  /// 画面状態を生成する。
  MenuManagementState({
    required List<MenuCategoryViewData> categories,
    required List<MenuItemViewData> menuItems,
    required this.selectedCategoryId,
    required this.availabilityFilter,
    required this.searchQuery,
    required Set<String> selectedMenuItemIds,
    required this.realtimeEventCount,
    required Set<String> pendingAvailabilityMenuIds,
    required Map<String, String> availabilityErrorMessages,
    this.selectedMenuId,
    this.detail,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isRealtimeConnected = false,
    this.isRefreshingAvailability = false,
    this.errorMessage,
  }) : categories = List<MenuCategoryViewData>.unmodifiable(categories),
       menuItems = List<MenuItemViewData>.unmodifiable(menuItems),
       selectedMenuItemIds = Set<String>.unmodifiable(selectedMenuItemIds),
       pendingAvailabilityMenuIds = Set<String>.unmodifiable(pendingAvailabilityMenuIds),
       availabilityErrorMessages = Map<String, String>.unmodifiable(availabilityErrorMessages);

  /// 初期状態を生成する。
  factory MenuManagementState.initial() => MenuManagementState(
    categories: const <MenuCategoryViewData>[],
    menuItems: const <MenuItemViewData>[],
    selectedCategoryId: null,
    availabilityFilter: MenuAvailabilityFilter.all,
    searchQuery: "",
    selectedMenuItemIds: const <String>{},
    realtimeEventCount: 0,
    pendingAvailabilityMenuIds: const <String>{},
    availabilityErrorMessages: const <String, String>{},
    isLoading: true,
  );

  /// カテゴリ集計一覧。
  final List<MenuCategoryViewData> categories;

  /// メニュー一覧データ。
  final List<MenuItemViewData> menuItems;

  /// 選択中カテゴリID。`null` はすべて。
  final String? selectedCategoryId;

  /// 在庫可用性フィルター。
  final MenuAvailabilityFilter availabilityFilter;

  /// 検索クエリ。
  final String searchQuery;

  /// 選択メニューIDリスト（複数選択用）。
  final Set<String> selectedMenuItemIds;

  /// 現在詳細表示しているメニューID。
  final String? selectedMenuId;

  /// 詳細表示データ。
  final MenuDetailViewData? detail;

  /// ローディング中かどうか。
  final bool isLoading;

  /// 実行中の操作があるか。
  final bool isSubmitting;

  /// リアルタイム接続が有効か。
  final bool isRealtimeConnected;

  /// 在庫可用性の再計算中か。
  final bool isRefreshingAvailability;

  /// 最新リアルタイムイベントのカウンタ。
  final int realtimeEventCount;

  /// エラーメッセージ。
  final String? errorMessage;

  /// 販売状態を更新中のメニューID集合。
  final Set<String> pendingAvailabilityMenuIds;

  /// 販売状態更新に失敗した際の行別エラーメッセージ。
  final Map<String, String> availabilityErrorMessages;

  /// フィルター適用後の一覧。
  List<MenuItemViewData> get filteredMenuItems {
    final Iterable<MenuItemViewData> base = menuItems.where(_matchesCategory).where(_matchesStatus);
    if (searchQuery.trim().isEmpty) {
      return base.toList(growable: false);
    }
    final String normalized = searchQuery.trim().toLowerCase();
    return base
        .where(
          (MenuItemViewData item) =>
              item.name.toLowerCase().contains(normalized) ||
              (item.description != null && item.description!.toLowerCase().contains(normalized)),
        )
        .toList(growable: false);
  }

  /// 指標カード用: 登録メニュー数。
  int get totalMenuCount => menuItems.length;

  /// 指標カード用: 提供可能数。
  int get availableMenuCount => menuItems.where((MenuItemViewData item) => item.isAvailable).length;

  /// 指標カード用: 要確認数。
  int get attentionMenuCount =>
      menuItems.where((MenuItemViewData item) => item.needsAttention).length;

  bool _matchesCategory(MenuItemViewData item) {
    if (selectedCategoryId == null) {
      return true;
    }
    return item.categoryId == selectedCategoryId;
  }

  bool _matchesStatus(MenuItemViewData item) {
    switch (availabilityFilter) {
      case MenuAvailabilityFilter.all:
        return true;
      case MenuAvailabilityFilter.available:
        return item.isAvailable && !item.hasStockIssue;
      case MenuAvailabilityFilter.unavailable:
        return !item.isAvailable || item.hasStockIssue;
      case MenuAvailabilityFilter.attention:
        return item.needsAttention;
    }
  }

  /// 現在詳細を表示しているメニューを取得する。
  MenuItemViewData? get selectedMenu {
    if (selectedMenuId == null) {
      return null;
    }
    for (final MenuItemViewData item in menuItems) {
      if (item.id == selectedMenuId) {
        return item;
      }
    }
    return null;
  }

  /// コピーを生成する。
  MenuManagementState copyWith({
    List<MenuCategoryViewData>? categories,
    List<MenuItemViewData>? menuItems,
    String? selectedCategoryId,
    bool setSelectedCategory = false,
    MenuAvailabilityFilter? availabilityFilter,
    String? searchQuery,
    Set<String>? selectedMenuItemIds,
    String? selectedMenuId,
    bool setSelectedMenu = false,
    MenuDetailViewData? detail,
    bool setDetail = false,
    bool? isLoading,
    bool? isSubmitting,
    bool? isRealtimeConnected,
    bool? isRefreshingAvailability,
    int? realtimeEventCount,
    String? errorMessage,
    Set<String>? pendingAvailabilityMenuIds,
    Map<String, String>? availabilityErrorMessages,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    final bool shouldSetCategory = setSelectedCategory || selectedCategoryId != null;
    final bool shouldSetMenuId = setSelectedMenu || selectedMenuId != null;
    final bool shouldSetDetail = setDetail || detail != null;

    return MenuManagementState(
      categories: categories ?? this.categories,
      menuItems: menuItems ?? this.menuItems,
      selectedCategoryId: shouldSetCategory ? selectedCategoryId : this.selectedCategoryId,
      availabilityFilter: availabilityFilter ?? this.availabilityFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMenuItemIds: selectedMenuItemIds ?? this.selectedMenuItemIds,
      selectedMenuId: clearDetail ? null : (shouldSetMenuId ? selectedMenuId : this.selectedMenuId),
      detail: clearDetail ? null : (shouldSetDetail ? detail : this.detail),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      isRefreshingAvailability: isRefreshingAvailability ?? this.isRefreshingAvailability,
      realtimeEventCount: realtimeEventCount ?? this.realtimeEventCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingAvailabilityMenuIds:
          pendingAvailabilityMenuIds ?? this.pendingAvailabilityMenuIds,
      availabilityErrorMessages:
          availabilityErrorMessages ?? this.availabilityErrorMessages,
    );
  }
}
