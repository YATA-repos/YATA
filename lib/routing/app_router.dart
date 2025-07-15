import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../features/analytics/presentation/screens/analytics_screen.dart";
import "../features/analytics/presentation/screens/inventory_analytics_screen.dart";
import "../features/analytics/presentation/screens/sales_analytics_screen.dart";
import "../features/auth/presentation/screens/login_screen.dart";
import "../features/auth/presentation/screens/splash_screen.dart";
import "../features/dashboard/presentation/screens/dashboard_screen.dart";
import "../features/inventory/presentation/screens/inventory_screen.dart";
import "../features/inventory/presentation/screens/material_detail_screen.dart";
import "../features/menu/presentation/screens/menu_detail_screen.dart";
import "../features/menu/presentation/screens/menu_edit_screen.dart";
import "../features/menu/presentation/screens/menu_screen.dart";
import "../features/order/presentation/screens/cart_screen.dart";
import "../features/order/presentation/screens/order_create_screen.dart";
import "../features/order/presentation/screens/order_detail_screen.dart";
import "../features/order/presentation/screens/order_list_screen.dart";
import "../features/settings/presentation/screens/profile_screen.dart";
import "../features/settings/presentation/screens/settings_screen.dart";
import "../features/stock/presentation/screens/purchase_screen.dart";
import "../shared/layouts/adaptive_layout.dart";
import "../shared/layouts/tab_scaffold.dart";
import "route_constants.dart";

/// アプリケーションのルート定義を管理するクラス
class AppRouter {
  AppRouter._();

  /// 全てのルート定義
  static List<RouteBase> get routes => <RouteBase>[
    // スプラッシュ画面（初期化処理）
    GoRoute(
      path: AppRoutes.splash,
      name: "splash",
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),

    // ログイン画面
    GoRoute(
      path: AppRoutes.login,
      name: "login",
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),

    // メインシェル（タブ付きナビゲーション）
    StatefulShellRoute.indexedStack(
      builder:
          (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
              AdaptiveLayout(child: TabScaffold(navigationShell: navigationShell)),
      branches: <StatefulShellBranch>[
        // ホーム/注文タブ
        _buildHomeBranch(),

        // 在庫管理タブ
        _buildInventoryBranch(),

        // メニュータブ
        _buildMenuBranch(),

        // 分析タブ
        _buildAnalyticsBranch(),

        // 設定タブ
        _buildSettingsBranch(),
      ],
    ),
  ];

  /// ホーム/注文管理ブランチの構築
  static StatefulShellBranch _buildHomeBranch() => StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: "home",
        builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
        routes: <RouteBase>[
          // 注文一覧
          GoRoute(
            path: "orders",
            name: "orders",
            builder: (BuildContext context, GoRouterState state) => const OrderListScreen(),
            routes: <RouteBase>[
              // 注文詳細
              GoRoute(
                path: ":orderId",
                name: "orderDetail",
                builder: (BuildContext context, GoRouterState state) {
                  final String orderId = state.pathParameters["orderId"]!;
                  return OrderDetailScreen(orderId: orderId);
                },
              ),

              // 注文作成
              GoRoute(
                path: "create",
                name: "orderCreate",
                builder: (BuildContext context, GoRouterState state) => const OrderCreateScreen(),
              ),
            ],
          ),

          // カート
          GoRoute(
            path: "cart",
            name: "cart",
            builder: (BuildContext context, GoRouterState state) => const CartScreen(),
          ),
        ],
      ),
    ],
  );

  /// 在庫管理ブランチの構築
  static StatefulShellBranch _buildInventoryBranch() => StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.inventory,
        name: "inventory",
        builder: (BuildContext context, GoRouterState state) => const InventoryScreen(),
        routes: <RouteBase>[
          // 材料詳細
          GoRoute(
            path: ":materialId",
            name: "materialDetail",
            builder: (BuildContext context, GoRouterState state) {
              final String materialId = state.pathParameters["materialId"]!;
              return MaterialDetailScreen(materialId: materialId);
            },
          ),

          // 仕入れ
          GoRoute(
            path: "purchase",
            name: "purchase",
            builder: (BuildContext context, GoRouterState state) => const PurchaseScreen(),
          ),
        ],
      ),
    ],
  );

  /// メニューブランチの構築
  static StatefulShellBranch _buildMenuBranch() => StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.menu,
        name: "menu",
        builder: (BuildContext context, GoRouterState state) => const MenuScreen(),
        routes: <RouteBase>[
          // メニュー詳細
          GoRoute(
            path: ":menuId",
            name: "menuDetail",
            builder: (BuildContext context, GoRouterState state) {
              final String menuId = state.pathParameters["menuId"]!;
              return MenuDetailScreen(menuId: menuId);
            },
            routes: <RouteBase>[
              // メニュー編集
              GoRoute(
                path: "edit",
                name: "menuEdit",
                builder: (BuildContext context, GoRouterState state) {
                  final String menuId = state.pathParameters["menuId"]!;
                  return MenuEditScreen(menuId: menuId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  /// 分析ブランチの構築
  static StatefulShellBranch _buildAnalyticsBranch() => StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.analytics,
        name: "analytics",
        builder: (BuildContext context, GoRouterState state) => const AnalyticsScreen(),
        routes: <RouteBase>[
          // 売上分析
          GoRoute(
            path: "sales",
            name: "salesAnalytics",
            builder: (BuildContext context, GoRouterState state) => const SalesAnalyticsScreen(),
          ),

          // 在庫分析
          GoRoute(
            path: "inventory",
            name: "inventoryAnalytics",
            builder: (BuildContext context, GoRouterState state) =>
                const InventoryAnalyticsScreen(),
          ),
        ],
      ),
    ],
  );

  /// 設定ブランチの構築
  static StatefulShellBranch _buildSettingsBranch() => StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.settings,
        name: "settings",
        builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
        routes: <RouteBase>[
          // プロフィール
          GoRoute(
            path: "profile",
            name: "profile",
            builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
