import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "navigation_provider.g.dart";

/// ナビゲーション状態を管理するProvider
@riverpod
class NavigationState extends _$NavigationState {
  @override
  NavigationData build() => const NavigationData(currentTab: 0, canPop: false);

  /// 現在のタブを更新
  void updateTab(int index) {
    if (index >= 0 && index <= 4) {
      state = state.copyWith(currentTab: index);
    }
  }

  /// Pop可能状態を更新
  void updateCanPop(bool canPop) {
    state = state.copyWith(canPop: canPop);
  }

  /// タブを次に進める
  void nextTab() {
    final int nextIndex = (state.currentTab + 1) % 5;
    updateTab(nextIndex);
  }

  /// タブを前に戻す
  void previousTab() {
    final int previousIndex = state.currentTab == 0 ? 4 : state.currentTab - 1;
    updateTab(previousIndex);
  }

  /// ホームタブに戻る
  void goToHome() {
    updateTab(0);
  }
}

/// ナビゲーション状態を保持するデータクラス
class NavigationData {
  const NavigationData({required this.currentTab, required this.canPop});

  /// 現在のタブインデックス（0: ホーム, 1: 在庫, 2: メニュー, 3: 分析, 4: 設定）
  final int currentTab;

  /// 戻るボタンが有効かどうか
  final bool canPop;

  /// タブ名を取得
  String get currentTabName {
    switch (currentTab) {
      case 0:
        return "ホーム";
      case 1:
        return "在庫";
      case 2:
        return "メニュー";
      case 3:
        return "分析";
      case 4:
        return "設定";
      default:
        return "ホーム";
    }
  }

  /// タブがホームかどうか
  bool get isHomeTab => currentTab == 0;

  /// タブが在庫かどうか
  bool get isInventoryTab => currentTab == 1;

  /// タブがメニューかどうか
  bool get isMenuTab => currentTab == 2;

  /// タブが分析かどうか
  bool get isAnalyticsTab => currentTab == 3;

  /// タブが設定かどうか
  bool get isSettingsTab => currentTab == 4;

  NavigationData copyWith({int? currentTab, bool? canPop}) =>
      NavigationData(currentTab: currentTab ?? this.currentTab, canPop: canPop ?? this.canPop);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationData &&
          runtimeType == other.runtimeType &&
          currentTab == other.currentTab &&
          canPop == other.canPop;

  @override
  int get hashCode => currentTab.hashCode ^ canPop.hashCode;

  @override
  String toString() => "NavigationData{currentTab: $currentTab ($currentTabName), canPop: $canPop}";
}

/// 現在のタブインデックスのみを取得するProvider
@riverpod
int currentTabIndex(Ref ref) => ref.watch(navigationStateProvider).currentTab;

/// ナビゲーション履歴を管理するProvider
@riverpod
class NavigationHistory extends _$NavigationHistory {
  @override
  List<int> build() => <int>[0]; // 初期はホームタブ

  /// 新しいタブを履歴に追加
  void push(int tabIndex) {
    state = <int>[...state, tabIndex];
  }

  /// 履歴から最後のタブを削除して返す
  int? pop() {
    if (state.length <= 1) {
      return null;
    }

    final List<int> newState = <int>[...state];
    final int lastTab = newState.removeLast();
    state = newState;
    return lastTab;
  }

  /// 履歴をクリア
  void clear() {
    state = <int>[0]; // ホームタブのみ残す
  }

  /// 特定のタブまでの履歴をクリア
  void clearToTab(int tabIndex) {
    final int index = state.lastIndexOf(tabIndex);
    if (index != -1) {
      state = state.sublist(0, index + 1);
    }
  }
}

/// ナビゲーション状態変更の監視Provider
@riverpod
class NavigationNotifier extends _$NavigationNotifier {
  @override
  void build() {
    // ナビゲーション状態の変更を監視
    ref.listen(navigationStateProvider, (NavigationData? previous, NavigationData next) {
      if (previous?.currentTab != next.currentTab) {
        _onTabChanged(previous?.currentTab, next.currentTab);
      }
    });
  }

  /// タブが変更された時の処理
  void _onTabChanged(int? previousTab, int currentTab) {
    // 履歴に新しいタブを追加
    if (previousTab != null && previousTab != currentTab) {
      ref.read(navigationHistoryProvider.notifier).push(currentTab);
    }
  }
}

/// ナビゲーション関連のユーティリティProvider
@riverpod
NavigationUtils navigationUtils(Ref ref) => NavigationUtils(ref);

/// ナビゲーション関連のユーティリティクラス
class NavigationUtils {
  NavigationUtils(this.ref);

  final Ref ref;

  /// タブの表示名を取得
  String getTabName(int index) {
    switch (index) {
      case 0:
        return "ホーム";
      case 1:
        return "在庫";
      case 2:
        return "メニュー";
      case 3:
        return "分析";
      case 4:
        return "設定";
      default:
        return "ホーム";
    }
  }

  /// タブのアイコン名を取得（Lucide Icons用）
  String getTabIconName(int index) {
    switch (index) {
      case 0:
        return "home";
      case 1:
        return "package";
      case 2:
        return "menu-square";
      case 3:
        return "bar-chart-3";
      case 4:
        return "settings";
      default:
        return "home";
    }
  }

  /// 現在のタブから他のタブに移動可能かどうかを判定
  bool canNavigateToTab(int targetTab) {
    final int currentTab = ref.read(currentTabIndexProvider);

    // 同じタブには移動不可
    if (currentTab == targetTab) {
      return false;
    }

    // 基本的にすべてのタブに移動可能
    return true;
  }

  /// ナビゲーション状態をリセット
  void resetNavigation() {
    ref.read(navigationStateProvider.notifier).updateTab(0);
    ref.read(navigationHistoryProvider.notifier).clear();
  }
}
