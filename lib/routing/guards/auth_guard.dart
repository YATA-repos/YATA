import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/auth/models/auth_state.dart";
import "../../features/auth/presentation/providers/auth_providers.dart";

/// 認証ガード
/// 
/// GoRouterのredirect機能を使用して認証状態をチェックし、
/// 未認証ユーザーをログイン画面にリダイレクトします。
class AuthGuard {
  AuthGuard._();

  /// 認証が必要なパスのリスト
  static const List<String> _protectedPaths = <String>[
    "/",                 // ダッシュボード
    "/orders",           // 注文履歴
    "/order-status",     // 注文状況
    "/analytics",        // 売上分析
    "/inventory",        // 詳細在庫管理
  ];

  /// パブリックパス（認証不要）のリスト
  static const List<String> _publicPaths = <String>[
    "/login",            // ログイン画面
    "/auth/callback",    // OAuth認証コールバック
  ];

  /// 指定されたパスが保護されているかチェック
  static bool _isProtectedPath(String path) {
    // 完全一致チェック
    if (_protectedPaths.contains(path)) {
      return true;
    }

    // パターンマッチング（注文詳細など）
    for (final String protectedPath in _protectedPaths) {
      if (protectedPath == "/orders" && path.startsWith("/orders/")) {
        return true; // 注文詳細ページ
      }
    }

    return false;
  }

  /// 指定されたパスがパブリックかチェック
  static bool _isPublicPath(String path) => _publicPaths.any((String publicPath) => path.startsWith(publicPath));

  /// 認証ガードのリダイレクトロジック
  /// 
  /// GoRouterのredirectに渡す関数です。
  /// 認証状態に基づいて適切なリダイレクトを行います。
  static String? guardRedirect(WidgetRef ref, GoRouterState state) {
    final String location = state.matchedLocation;
    final AuthState authState = ref.watch(authStateNotifierProvider);

    // 認証処理中の場合は現在の場所を維持
    if (authState.isAuthenticating) {
      return null;
    }

    // パブリックパスの場合
    if (_isPublicPath(location)) {
      // 既に認証済みでログイン画面にいる場合はダッシュボードにリダイレクト
      if (authState.isAuthenticated && location == "/login") {
        return "/";
      }
      // その他のパブリックパスはそのまま通す
      return null;
    }

    // 保護されたパスの場合
    if (_isProtectedPath(location)) {
      // 未認証の場合はログイン画面にリダイレクト
      if (!authState.isAuthenticated) {
        return "/login";
      }
      // 認証済みの場合はそのまま通す
      return null;
    }

    // その他のパス（存在しないパスなど）はそのまま通す
    // GoRouterのerrorBuilderで処理される
    return null;
  }

  /// 認証後のリダイレクト先を決定
  /// 
  /// ログイン成功後にユーザーを適切なページにリダイレクトします。
  static String getPostAuthRedirect(String? intendedPath) {
    // 意図されたパスがある場合はそこにリダイレクト
    if (intendedPath != null && 
        intendedPath.isNotEmpty && 
        _isProtectedPath(intendedPath)) {
      return intendedPath;
    }

    // デフォルトはダッシュボード
    return "/";
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> getDebugInfo() => <String, dynamic>{
      "protectedPaths": _protectedPaths,
      "publicPaths": _publicPaths,
    };
}