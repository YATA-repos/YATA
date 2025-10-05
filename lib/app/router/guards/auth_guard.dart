import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";

import "../../../features/auth/models/auth_state.dart";

/// 認証状態に基づいてルーティングを制御するガード。
///
/// app 層で認証判定を一元化し、`GoRouter` の `redirect` に供給する。
class AuthGuard {
  const AuthGuard._();

  /// 現在の `AuthState` と遷移先から適切なリダイレクト先を返す。
  /// 未認証の場合は `/auth` へ誘導し、認証済みで `/auth` に居る場合は
  /// 既定のメイン画面へ送り返す。
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
