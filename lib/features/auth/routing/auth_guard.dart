import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";

import "../models/auth_state.dart";

/// GoRouter用の認証ガード。
class AuthGuard {
  const AuthGuard._();

  /// 現在の認証状態に基づいてリダイレクト先を判断する。
  static String? redirect(BuildContext context, GoRouterState state, AuthState authState) {
    final String location = state.matchedLocation;
    final bool navigatingToAuth = location == "/auth";

    if (authState.isAuthenticating) {
      return null;
    }

    if (!authState.isAuthenticated) {
      return navigatingToAuth ? null : "/auth";
    }

    if (authState.isAuthenticated && navigatingToAuth) {
      return "/order";
    }

    return null;
  }
}
