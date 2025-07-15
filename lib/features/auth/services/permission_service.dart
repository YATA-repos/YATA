import "../../../core/utils/logger_mixin.dart";
import "../models/user_model.dart";

/// 権限管理サービス
class PermissionService with LoggerMixin {
  @override
  String get loggerComponent => "PermissionService";

  /// ルート別権限マップ
  static const Map<String, UserRole> routePermissions = <String, UserRole>{
    "/analytics": UserRole.manager,
    "/inventory": UserRole.staff,
    "/menu": UserRole.staff,
    "/orders": UserRole.staff,
    "/business": UserRole.manager,
    "/dashboard": UserRole.staff,
  };

  /// アクション別権限マップ
  static const Map<String, UserRole> actionPermissions = <String, UserRole>{
    "delete_order": UserRole.manager,
    "modify_menu": UserRole.staff,
    "view_analytics": UserRole.manager,
    "manage_inventory": UserRole.staff,
    "view_business_operations": UserRole.manager,
    "edit_business_hours": UserRole.manager,
    "manage_users": UserRole.admin,
    "view_system_logs": UserRole.admin,
    "export_data": UserRole.manager,
    "import_data": UserRole.manager,
  };

  /// 指定されたルートにアクセス可能かどうかを確認
  bool canAccessRoute(String route, UserRole userRole) {
    final UserRole? requiredRole = routePermissions[route];
    if (requiredRole == null) {
      // 制限なしの場合は全ユーザーがアクセス可能
      logDebug("Route $route has no access restrictions");
      return true;
    }

    final bool hasAccess = userRole.canAccess(requiredRole);
    logDebug(
      "Route access check: $route, userRole: ${userRole.displayName}, "
      "required: ${requiredRole.displayName}, hasAccess: $hasAccess",
    );

    return hasAccess;
  }

  /// 指定されたアクションを実行可能かどうかを確認
  bool canPerformAction(String action, UserRole userRole) {
    final UserRole? requiredRole = actionPermissions[action];
    if (requiredRole == null) {
      // 制限なしの場合は全ユーザーが実行可能
      logDebug("Action $action has no restrictions");
      return true;
    }

    final bool hasPermission = userRole.canAccess(requiredRole);
    logDebug(
      "Action permission check: $action, userRole: ${userRole.displayName}, "
      "required: ${requiredRole.displayName}, hasPermission: $hasPermission",
    );

    return hasPermission;
  }

  /// 複数のアクションに対する権限を一括チェック
  Map<String, bool> checkMultipleActions(List<String> actions, UserRole userRole) {
    final Map<String, bool> results = <String, bool>{};

    for (final String action in actions) {
      results[action] = canPerformAction(action, userRole);
    }

    logDebug("Bulk action check completed for ${actions.length} actions");
    return results;
  }

  /// データアクセス権限の確認（リソース所有者チェック）
  bool canAccessResource(String resourceOwnerId, String currentUserId, UserRole userRole) {
    // 管理者は全てのリソースにアクセス可能
    if (userRole == UserRole.admin) {
      return true;
    }

    // 店舗管理者は同じ店舗のリソースにアクセス可能（今回は簡易的にユーザーIDで判定）
    if (userRole == UserRole.manager) {
      // 実際の実装では、店舗IDやテナントIDで判定すべき
      return true;
    }

    // その他のユーザーは自分のリソースのみアクセス可能
    final bool canAccess = resourceOwnerId == currentUserId;
    logDebug(
      "Resource access check: owner=$resourceOwnerId, current=$currentUserId, "
      "role=${userRole.displayName}, canAccess=$canAccess",
    );

    return canAccess;
  }

  /// ユーザーの最小権限レベルを確認
  bool hasMinimumRole(UserRole userRole, UserRole minimumRole) => userRole.canAccess(minimumRole);

  /// 権限エラーメッセージを生成
  String generatePermissionErrorMessage(String action, UserRole userRole, UserRole requiredRole) =>
      "アクション「$action」を実行する権限がありません。"
      "現在の権限: ${userRole.displayName}、 "
      "必要な権限: ${requiredRole.displayName}";

  /// ルート別のエラーメッセージを生成
  String generateRouteErrorMessage(String route, UserRole userRole, UserRole requiredRole) =>
      "ページ「$route」にアクセスする権限がありません。"
      "現在の権限: ${userRole.displayName}、 "
      "必要な権限: ${requiredRole.displayName}";
}
