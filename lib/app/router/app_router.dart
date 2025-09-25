import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/inventory/presentation/pages/inventory_management_page.dart";
import "../../features/order/presentation/pages/order_history_page.dart";
import "../../features/order/presentation/pages/order_management_page.dart";

/// アプリ全体のルーター設定
class AppRouter {
  const AppRouter._();

  static GoRouter getRouter(WidgetRef ref) => GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: "/",
        name: "home",
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
    ],
    // TODO: 認証ガードやリダイレクトはここに設定
  );
}
