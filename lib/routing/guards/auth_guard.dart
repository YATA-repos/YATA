import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/utils/logger_mixin.dart";
import "../../features/auth/models/user_model.dart";
import "../../features/auth/presentation/providers/auth_provider.dart";
import "../../features/auth/services/permission_service.dart";
import "../route_constants.dart";

/// 認証ガードクラス
///
/// ルーティング時の認証チェックロジックを提供します。
class AuthGuard {
  AuthGuard._();

  static final _AuthGuardLogger _logger = _AuthGuardLogger();
  static final PermissionService _permissionService = PermissionService();

  /// 指定されたルートへのアクセス権限をチェック
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  /// [route] チェック対象のルート
  ///
  /// Returns: アクセス可能な場合はtrue
  static bool canAccess(WidgetRef ref, String route) {
    final AsyncValue<bool> authState = ref.read(authStateProvider);

    // 認証状態の読み込み中は保留
    if (authState.isLoading) {
      return false;
    }

    // 認証エラー時は拒否
    if (authState.hasError) {
      _logger.logWarning("Access denied due to authentication error for route: $route");
      return false;
    }

    final bool isAuthenticated = authState.value ?? false;

    // 認証が不要なルートは常にアクセス可能
    if (!AppRoutes.requiresAuth(route)) {
      return true;
    }

    // 認証が必要なルートは認証済みユーザーのみアクセス可能
    if (!isAuthenticated) {
      return false;
    }

    // ロールベースアクセス制御
    final AsyncValue<UserModel?> userProfile = ref.read(currentUserProvider);
    if (userProfile.isLoading) {
      return false;
    }

    if (userProfile.hasError || userProfile.value == null) {
      _logger.logWarning("Access denied due to user profile error for route: $route");
      return false;
    }

    final UserRole userRole = userProfile.value!.role;
    final bool hasPermission = _permissionService.canAccessRoute(route, userRole);

    if (!hasPermission) {
      _logger.logWarning(
        "Access denied due to insufficient permissions for route: $route, "
        "userRole: ${userRole.displayName}",
      );
    }

    return hasPermission;
  }

  /// 認証が必要なルートへのアクセス時のリダイレクト先を決定
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  /// [targetRoute] アクセス先のルート
  ///
  /// Returns: リダイレクト先のルート（nullの場合はリダイレクトなし）
  static String? getRedirectRoute(WidgetRef ref, String targetRoute) {
    final AsyncValue<bool> authState = ref.read(authStateProvider);

    // 認証状態の読み込み中はスプラッシュ画面へ
    if (authState.isLoading) {
      return targetRoute != AppRoutes.splash ? AppRoutes.splash : null;
    }

    // 認証エラー時はログイン画面へ
    if (authState.hasError) {
      _logger.logWarning("Redirecting to login due to authentication error. Target: $targetRoute");
      return _shouldRedirectToLogin(targetRoute) ? AppRoutes.login : null;
    }

    final bool isAuthenticated = authState.value ?? false;

    // 認証済みユーザーの処理
    if (isAuthenticated) {
      return _getAuthenticatedUserRedirect(targetRoute);
    }

    // 未認証ユーザーの処理
    return _getUnauthenticatedUserRedirect(targetRoute);
  }

  /// 認証済みユーザーのリダイレクト処理
  static String? _getAuthenticatedUserRedirect(String targetRoute) {
    // スプラッシュまたはログイン画面にいる場合はホームへ
    if (targetRoute == AppRoutes.splash || targetRoute == AppRoutes.login) {
      return AppRoutes.home;
    }
    return null;
  }

  /// 未認証ユーザーのリダイレクト処理
  static String? _getUnauthenticatedUserRedirect(String targetRoute) {
    // 認証が必要なルートへのアクセスはログイン画面へ
    if (AppRoutes.requiresAuth(targetRoute)) {
      return AppRoutes.login;
    }
    return null;
  }

  /// ログイン画面へのリダイレクトが必要かどうかを判定
  static bool _shouldRedirectToLogin(String targetRoute) =>
      targetRoute != AppRoutes.login && targetRoute != AppRoutes.splash;

  /// 特定のアクションへの権限をチェック
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  /// [action] チェック対象のアクション
  ///
  /// Returns: 権限がある場合はtrue
  static bool hasPermission(WidgetRef ref, String action) {
    final AsyncValue<bool> authState = ref.read(authStateProvider);

    // 認証状態のチェック
    if (authState.isLoading || authState.hasError || !(authState.value ?? false)) {
      return false;
    }

    // ユーザープロファイルの取得
    final AsyncValue<UserModel?> userProfile = ref.read(currentUserProvider);
    if (userProfile.isLoading || userProfile.hasError || userProfile.value == null) {
      return false;
    }

    final UserRole userRole = userProfile.value!.role;
    final bool hasPermission = _permissionService.canPerformAction(action, userRole);

    if (!hasPermission) {
      _logger.logWarning(
        "Permission denied for action: $action, userRole: ${userRole.displayName}",
      );
    }

    return hasPermission;
  }

  /// 管理者権限をチェック
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  ///
  /// Returns: 管理者権限がある場合はtrue
  static bool isAdmin(WidgetRef ref) {
    final AsyncValue<UserModel?> userProfile = ref.read(currentUserProvider);
    if (userProfile.isLoading || userProfile.hasError || userProfile.value == null) {
      return false;
    }

    return userProfile.value!.role.isAdmin;
  }

  /// マネージャー権限をチェック
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  ///
  /// Returns: マネージャー権限がある場合はtrue
  static bool isManager(WidgetRef ref) {
    final AsyncValue<UserModel?> userProfile = ref.read(currentUserProvider);
    if (userProfile.isLoading || userProfile.hasError || userProfile.value == null) {
      return false;
    }

    return userProfile.value!.role.isManager;
  }

  /// スタッフ権限をチェック
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  ///
  /// Returns: スタッフ権限がある場合はtrue
  static bool isStaff(WidgetRef ref) {
    final AsyncValue<UserModel?> userProfile = ref.read(currentUserProvider);
    if (userProfile.isLoading || userProfile.hasError || userProfile.value == null) {
      return false;
    }

    return userProfile.value!.role.isStaff;
  }

  /// 認証状態の詳細情報を取得
  ///
  /// [ref] Riverpodのウィジェットリファレンス
  ///
  /// Returns: 認証状態の詳細情報
  static AuthGuardResult getAuthStatus(WidgetRef ref) {
    final AsyncValue<bool> authState = ref.read(authStateProvider);

    if (authState.isLoading) {
      return const AuthGuardResult(isAuthenticated: false, isLoading: true, errorMessage: null);
    }

    if (authState.hasError) {
      return AuthGuardResult(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: authState.error.toString(),
      );
    }

    return AuthGuardResult(
      isAuthenticated: authState.value ?? false,
      isLoading: false,
      errorMessage: null,
    );
  }
}

/// 認証ガードの結果を表すデータクラス
class AuthGuardResult {
  const AuthGuardResult({
    required this.isAuthenticated,
    required this.isLoading,
    required this.errorMessage,
  });

  /// 認証済みかどうか
  final bool isAuthenticated;

  /// 認証状態の読み込み中かどうか
  final bool isLoading;

  /// エラーメッセージ（エラーがない場合はnull）
  final String? errorMessage;

  /// エラーがあるかどうか
  bool get hasError => errorMessage != null;

  /// 認証が完了しているかどうか（読み込み中でない）
  bool get isCompleted => !isLoading;

  @override
  String toString() =>
      "AuthGuardResult{"
      "isAuthenticated: $isAuthenticated, "
      "isLoading: $isLoading, "
      "errorMessage: $errorMessage"
      "}";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthGuardResult &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => isAuthenticated.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;
}

/// 権限定数クラス（将来の拡張用）
class Permissions {
  Permissions._();

  /// 基本的なアクセス権限
  static const String basic = "basic";

  /// 管理者権限
  static const String admin = "admin";

  /// 在庫管理権限
  static const String inventory = "inventory";

  /// メニュー管理権限
  static const String menu = "menu";

  /// 注文管理権限
  static const String order = "order";

  /// 分析データアクセス権限
  static const String analytics = "analytics";

  /// すべての権限リスト
  static const List<String> all = <String>[basic, admin, inventory, menu, order, analytics];
}

/// 認証ガードログ用クラス
class _AuthGuardLogger with LoggerMixin {
  // LoggerMixin のメソッドが利用可能
}
