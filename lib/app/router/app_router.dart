import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/analytics/presentation/pages/sales_analytics_page.dart";
import "../../features/auth/models/auth_state.dart";
import "../../features/auth/presentation/pages/auth_page.dart";
import "../../features/auth/presentation/providers/auth_providers.dart";
import "guards/auth_guard.dart";
import "../../features/inventory/presentation/pages/inventory_management_page.dart";
import "../../features/menu/presentation/pages/menu_management_page.dart";
import "../../features/order/presentation/pages/order_history_page.dart";
import "../../features/order/presentation/pages/order_management_page.dart";

/// アプリ全体のルーター設定
class AppRouter {
  const AppRouter._();

  static GoRouter getRouter(WidgetRef ref) {
    final AuthState authState = ref.watch(authStateNotifierProvider);

    return GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: "/auth",
          name: "auth",
          builder: (BuildContext context, GoRouterState state) => const AuthPage(),
        ),
        GoRoute(
          path: "/",
          name: "root",
          redirect: (BuildContext context, GoRouterState state) => "/order",
        ),
        GoRoute(
          path: "/order",
          name: "order",
          builder: (BuildContext context, GoRouterState state) => const OrderManagementPage(),
        ),
        GoRoute(
          path: "/history",
          name: "history",
          builder: (BuildContext context, GoRouterState state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: "/inventory",
          name: "inventory",
          builder: (BuildContext context, GoRouterState state) => const InventoryManagementPage(),
        ),
        GoRoute(
          path: "/menu",
          name: "menu",
          builder: (BuildContext context, GoRouterState state) => const MenuManagementPage(),
        ),
        GoRoute(
          path: "/analytics",
          name: "analytics",
          builder: (BuildContext context, GoRouterState state) => const SalesAnalyticsPage(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) =>
          AuthGuard.redirect(context, state, authState),
    );
  }
}
