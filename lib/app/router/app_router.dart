import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/order/presentation/pages/order_management_page.dart";
import "../../features/order/presentation/pages/order_history_page.dart";

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
    ],
    // TODO: 認証ガードやリダイレクトはここに設定
  );
}
