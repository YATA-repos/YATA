// ignore_for_file: always_put_control_body_on_new_line

class AppRoutes {
  AppRoutes._();

  // 認証関連
  static const String splash = "/splash";
  static const String login = "/login";

  // メインタブ（StatefulShellRoute）
  static const String home = "/";
  static const String orders = "/orders";
  static const String inventory = "/inventory";
  static const String menu = "/menu";
  static const String analytics = "/analytics";
  static const String settings = "/settings";

  // 注文関連サブルート
  static const String orderDetail = "/orders/:orderId";
  static const String orderCreate = "/orders/create";
  static const String cart = "/cart";

  // 在庫関連サブルート
  static const String materialDetail = "/inventory/:materialId";
  static const String purchase = "/inventory/purchase";

  // メニュー関連サブルート
  static const String menuDetail = "/menu/:menuId";
  static const String menuEdit = "/menu/:menuId/edit";

  // 分析関連サブルート
  static const String salesAnalytics = "/analytics/sales";
  static const String inventoryAnalytics = "/analytics/inventory";

  // 設定関連サブルート
  static const String profile = "/settings/profile";

  // タブのインデックス定数
  static const Map<String, int> tabIndices = <String, int>{
    home: 0,
    orders: 0, // ホーム/注文一覧は同じタブ
    inventory: 1,
    menu: 2,
    analytics: 3,
    settings: 4,
  };

  // ルート名からタブインデックスを取得
  static int getTabIndex(String route) {
    // ルートパスからベースパスを抽出
    final String basePath = _extractBasePath(route);
    return tabIndices[basePath] ?? 0;
  }

  // ベースパスを抽出（パラメータを除去）
  static String _extractBasePath(String route) {
    if (route.startsWith("/orders")) return orders;
    if (route.startsWith("/inventory")) return inventory;
    if (route.startsWith("/menu")) return menu;
    if (route.startsWith("/analytics")) return analytics;
    if (route.startsWith("/settings")) return settings;
    return home;
  }

  // 認証が必要なルートかどうかを判定
  static bool requiresAuth(String route) => route != splash && route != login;

  // ルートの表示名を取得（デバッグ用）
  static String getDisplayName(String route) {
    switch (route) {
      case splash:
        return "スプラッシュ";
      case login:
        return "ログイン";
      case home:
        return "ホーム";
      case orders:
        return "注文一覧";
      case inventory:
        return "在庫管理";
      case menu:
        return "メニュー";
      case analytics:
        return "分析";
      case settings:
        return "設定";
      default:
        return route;
    }
  }
}
