import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../core/utils/logger_mixin.dart";
import "../../features/auth/presentation/providers/auth_provider.dart";
import "../app_router.dart";
import "../route_constants.dart";
import "../route_error_screen.dart";

part "router_provider.g.dart";

/// アプリケーションのルーター設定を提供するProvider
///
/// 認証状態の変更を監視し、適切なリダイレクト処理を行います。
@riverpod
GoRouter appRouter(Ref ref) {
  // 認証状態を監視
  final AsyncValue<bool> authState = ref.watch(authStateProvider);
  final _RouterLogger logger = _RouterLogger();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,

    // エラーページの設定
    errorBuilder: (BuildContext context, GoRouterState state) {
      if (state.error != null) {
        logger.logError("Router navigation error occurred", state.error);
      }
      return const RouteErrorScreen();
    },

    // リダイレクトロジック
    redirect: (BuildContext context, GoRouterState state) =>
        _handleRedirect(location: state.uri.toString(), authState: authState),

    // ルート定義
    routes: AppRouter.routes,
  );
}

/// リダイレクトロジックを処理する内部関数
///
/// [location] 現在のルート位置
/// [authState] 現在の認証状態
///
/// Returns: リダイレクト先のパス（nullの場合はリダイレクトなし）
String? _handleRedirect({required String location, required AsyncValue<bool> authState}) {
  // 認証状態の読み込み中はスプラッシュ画面を表示
  if (authState.isLoading) {
    if (location != AppRoutes.splash) {
      return AppRoutes.splash;
    }
    return null;
  }

  // 認証状態のエラー時はログイン画面へ
  if (authState.hasError) {
    if (location != AppRoutes.login && location != AppRoutes.splash) {
      return AppRoutes.login;
    }
    return null;
  }

  final bool isAuthenticated = authState.value ?? false;

  // 認証済みユーザーのリダイレクト処理
  if (isAuthenticated) {
    // スプラッシュまたはログイン画面にいる場合はホームへ
    if (location == AppRoutes.splash || location == AppRoutes.login) {
      return AppRoutes.home;
    }
    return null;
  }

  // 未認証ユーザーのリダイレクト処理
  if (!isAuthenticated) {
    // 認証が必要なルートへのアクセスはログイン画面へ
    if (AppRoutes.requiresAuth(location)) {
      return AppRoutes.login;
    }
    return null;
  }

  return null;
}

/// ナビゲーション状態を管理するProvider
@riverpod
class NavigationState extends _$NavigationState {
  @override
  NavigationData build() => const NavigationData(currentTab: 0, canPop: false);

  /// 現在のタブを更新
  void updateTab(int index) {
    state = state.copyWith(currentTab: index);
  }

  /// Pop可能状態を更新
  void updateCanPop(bool canPop) {
    state = state.copyWith(canPop: canPop);
  }
}

/// ナビゲーション状態を保持するデータクラス
class NavigationData {
  const NavigationData({required this.currentTab, required this.canPop});

  /// 現在のタブインデックス
  final int currentTab;

  /// 戻るボタンが有効かどうか
  final bool canPop;

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
  String toString() => "NavigationData{currentTab: $currentTab, canPop: $canPop}";
}

/// ルーターログ用クラス
class _RouterLogger with LoggerMixin {
  // LoggerMixin のメソッドが利用可能
}
