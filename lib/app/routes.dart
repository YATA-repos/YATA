import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../features/analytics/presentation/screens/analytics_screen.dart";
import "../features/auth/presentation/screens/login_screen.dart";
import "../features/dashboard/presentation/screens/dashboard_screen.dart";
import "../features/inventory/presentation/screens/detailed_inventory_screen.dart";
import "../features/menu/presentation/screens/menu_management_screen.dart";
import "../features/order/presentation/screens/order_detail_screen.dart";
import "../features/order/presentation/screens/order_history_screen.dart";
import "../features/order/presentation/screens/order_status_screen.dart";
import "../routing/guards/auth_guard.dart";

/// アプリケーション全体のルーティング設定
///
/// Go Routerを使用してページ遷移を管理します。
/// 認証ガードにより保護されたルートと、ログイン機能を提供します。
class AppRouter {
  AppRouter._();

  /// メインルーター設定を取得
  /// 
  /// 認証ガードの統合にはWidgetRefが必要なため、
  /// アプリケーション初期化時にRefを渡して構築します。
  static GoRouter getRouter(WidgetRef ref) => GoRouter(
    initialLocation: "/",
    redirect: (BuildContext context, GoRouterState state) => 
        AuthGuard.guardRedirect(ref, state),
    routes: <RouteBase>[
      // 認証関連ルート
      GoRoute(
        path: "/login",
        name: "login",
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      // ダッシュボード（ホーム）
      GoRoute(
        path: "/",
        name: "dashboard",
        builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
      ),

      // 注文履歴
      GoRoute(
        path: "/orders",
        name: "orders",
        builder: (BuildContext context, GoRouterState state) => const OrderHistoryScreen(),
        routes: <RouteBase>[
          // 注文詳細
          GoRoute(
            path: "/:orderId",
            name: "order-detail",
            builder: (BuildContext context, GoRouterState state) {
              final String? orderId = state.pathParameters["orderId"];
              if (orderId == null) {
                // orderIdが取得できない場合は注文一覧にリダイレクト
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go("/orders");
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return OrderDetailScreen(orderId: orderId);
            },
          ),
        ],
      ),

      // 注文状況
      GoRoute(
        path: "/order-status",
        name: "order-status",
        builder: (BuildContext context, GoRouterState state) => const OrderStatusScreen(),
      ),

      // 売上分析
      GoRoute(
        path: "/analytics",
        name: "analytics",
        builder: (BuildContext context, GoRouterState state) => const AnalyticsScreen(),
      ),

      // 詳細在庫管理
      GoRoute(
        path: "/inventory",
        name: "inventory",
        builder: (BuildContext context, GoRouterState state) => const DetailedInventoryScreen(),
      ),

      // メニュー管理
      GoRoute(
        path: "/menu",
        name: "menu",
        builder: (BuildContext context, GoRouterState state) => const MenuManagementScreen(),
      ),
    ],

    // エラーページの設定
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text("エラー")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text("ページが見つかりません", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? "不明なエラーが発生しました",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go("/"), child: const Text("ホームに戻る")),
          ],
        ),
      ),
    ),
  );
}
