import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/utils/provider_logger.dart";
import "../../dto/menu_dto.dart";
import "../../models/menu_model.dart";
import "menu_providers.dart";

part "availability_providers.g.dart";

/// 利用可能なメニューアイテムのみを取得するプロバイダー
/// 既存のbulkMenuAvailabilityとmenuItemsを組み合わせ
@riverpod
Future<List<MenuItem>> availableMenuItems(Ref ref, String userId) async {
  try {
    ProviderLogger.debug("AvailabilityProviders", "利用可能メニューアイテム取得を開始");
    // 全メニューアイテムを取得
    final List<MenuItem> allItems = await ref.watch(menuItemsProvider(null).future);

    // 在庫可否情報を取得
    final Map<String, MenuAvailabilityInfo> availabilityMap = await ref.watch(bulkMenuAvailabilityProvider(userId).future);

    // 利用可能なアイテムのみをフィルタリング
    final List<MenuItem> result = allItems.where((MenuItem item) {
      final MenuAvailabilityInfo? availability = availabilityMap[item.id];
      return availability?.isAvailable ?? item.isAvailable;
    }).toList();
    
    ProviderLogger.info("AvailabilityProviders", "利用可能メニューアイテム取得が完了: ${result.length}件");
    return result;
  } catch (e, stackTrace) {
    ProviderLogger.asyncOperationFailed("AvailabilityProviders", "availableMenuItems", e, stackTrace);
    rethrow;
  }
}

/// 在庫不足で利用できないメニューアイテムを取得するプロバイダー
@riverpod
Future<List<MenuItem>> unavailableMenuItemsWithDetails(Ref ref, String userId) async {
  // 全メニューアイテムを取得
  final List<MenuItem> allItems = await ref.watch(menuItemsProvider(null).future);

  // 在庫可否情報を取得
  final Map<String, MenuAvailabilityInfo> availabilityMap = await ref.watch(bulkMenuAvailabilityProvider(userId).future);

  // 利用できないアイテムのみをフィルタリング
  return allItems.where((MenuItem item) {
    final MenuAvailabilityInfo? availability = availabilityMap[item.id];
    return !(availability?.isAvailable ?? item.isAvailable);
  }).toList();
}

/// 利用可能なメニューアイテム数を取得するプロバイダー
@riverpod
Future<int> availableMenuItemCount(Ref ref, String userId) async {
  final List<MenuItem> availableItems = await ref.watch(availableMenuItemsProvider(userId).future);
  return availableItems.length;
}

/// 在庫レベル別にメニューアイテムを分類するプロバイダー
@riverpod
Future<Map<String, List<MenuItem>>> menuItemsByAvailabilityStatus(Ref ref, String userId) async {
  final List<MenuItem> allItems = await ref.watch(menuItemsProvider(null).future);
  final Map<String, MenuAvailabilityInfo> availabilityMap = await ref.watch(bulkMenuAvailabilityProvider(userId).future);

  final Map<String, List<MenuItem>> groupedItems = <String, List<MenuItem>>{
    "available": <MenuItem>[],
    "low_stock": <MenuItem>[],
    "unavailable": <MenuItem>[],
  };

  for (final MenuItem item in allItems) {
    final MenuAvailabilityInfo? availability = availabilityMap[item.id];

    if (availability == null) {
      // 情報がない場合はアイテム自体の状態を使用
      if (item.isAvailable) {
        groupedItems["available"]!.add(item);
      } else {
        groupedItems["unavailable"]!.add(item);
      }
    } else if (availability.isAvailable) {
      // 在庫数に応じて分類
      final int servings = availability.estimatedServings ?? 0;
      if (servings <= 3) {
        groupedItems["low_stock"]!.add(item);
      } else {
        groupedItems["available"]!.add(item);
      }
    } else {
      groupedItems["unavailable"]!.add(item);
    }
  }

  return groupedItems;
}

/// 特定のメニューアイテムの詳細な可否情報を取得するプロバイダー
@riverpod
Future<MenuAvailabilityInfo?> detailedMenuAvailability(
  Ref ref,
  String menuItemId,
  String userId,
) async {
  try {
    return await ref.watch(menuAvailabilityProvider(menuItemId, 1, userId).future);
  } catch (e) {
    return null;
  }
}

/// メニュー可否状態の監視プロバイダー
@riverpod
class AvailabilityMonitor extends _$AvailabilityMonitor {
  @override
  bool build() => false;

  /// 定期監視を開始
  void startMonitoring({Duration interval = AppConfig.stockMonitoringInterval}) {
    if (state) {
      return; // 既に監視中
    }

    state = true;
    _scheduleNextCheck(interval);
  }

  /// 監視を停止
  void stopMonitoring() {
    state = false;
  }

  /// 次のチェックをスケジュール
  void _scheduleNextCheck(Duration interval) {
    if (!state) {
      return;
    }

    // プロバイダーを無効化してリフレッシュ
    Future<void>.delayed(interval, () {
      if (state) {
        ref.invalidate(bulkMenuAvailabilityProvider);
        _scheduleNextCheck(interval);
      }
    });
  }

  /// 手動リフレッシュ
  void refresh() {
    ref..invalidate(bulkMenuAvailabilityProvider)
    ..invalidate(availableMenuItemsProvider)
    ..invalidate(unavailableMenuItemsWithDetailsProvider);
  }
}

/// 利用可能性フィルター設定プロバイダー
@riverpod
class AvailabilityFilter extends _$AvailabilityFilter {
  @override
  Set<String> build() => <String>{"available", "low_stock", "unavailable"};

  /// フィルターにステータスを追加
  void addStatus(String status) {
    state = <String>{...state, status};
  }

  /// フィルターからステータスを削除
  void removeStatus(String status) {
    final Set<String> newState = Set<String>.from(state)
    ..remove(status);
    state = newState;
  }

  /// 利用可能なアイテムのみを表示
  void showAvailableOnly() {
    state = <String>{"available"};
  }

  /// 在庫少のアイテムのみを表示
  void showLowStockOnly() {
    state = <String>{"low_stock"};
  }

  /// 利用不可のアイテムのみを表示
  void showUnavailableOnly() {
    state = <String>{"unavailable"};
  }

  /// 全て表示
  void showAll() {
    state = <String>{"available", "low_stock", "unavailable"};
  }

  /// フィルターをリセット
  void reset() {
    state = <String>{"available", "low_stock", "unavailable"};
  }
}

/// フィルター済みメニューアイテムプロバイダー
@riverpod
Future<List<MenuItem>> filteredMenuItems(Ref ref, String userId) async {
  final Set<String> filter = ref.watch(availabilityFilterProvider);
  final Map<String, List<MenuItem>> groupedItems = await ref.watch(menuItemsByAvailabilityStatusProvider(userId).future);

  final List<MenuItem> filteredItems = <MenuItem>[];

  for (final String status in filter) {
    final List<MenuItem> items = groupedItems[status] ?? <MenuItem>[];
    filteredItems.addAll(items);
  }

  return filteredItems;
}

/// 在庫警告が必要なメニューアイテム数プロバイダー
@riverpod
Future<int> lowStockMenuItemCount(Ref ref, String userId) async {
  final Map<String, List<MenuItem>> groupedItems = await ref.watch(menuItemsByAvailabilityStatusProvider(userId).future);
  return groupedItems["low_stock"]?.length ?? 0;
}

/// カテゴリー別利用可能アイテム数プロバイダー
@riverpod
Future<Map<String, int>> availableItemCountByCategory(Ref ref, String userId) async {
  final List<MenuCategory> categories = await ref.watch(menuCategoriesProvider.future);
  final Map<String, int> counts = <String, int>{};

  for (final MenuCategory category in categories) {
    final List<MenuItem> categoryItems = await ref.watch(availableMenuItemsProvider(userId).future);
    final int categoryAvailableItems = categoryItems
        .where((MenuItem item) => item.categoryId == category.id)
        .length;
    counts[category.id!] = categoryAvailableItems;
  }

  return counts;
}
