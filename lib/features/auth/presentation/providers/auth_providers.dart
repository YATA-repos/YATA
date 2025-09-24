import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/logging/compat.dart" as log;
import "../../models/auth_state.dart";

/// 認証状態(State)のプロバイダー
/// テストでは初期状態の読み出しのみを行うため、最小実装とする
final StateProvider<AuthState> authStateNotifierProvider = StateProvider<AuthState>(
  (Ref ref) => AuthState.initial(),
);

/// 現在のユーザーIDを公開するProvider
final Provider<String?> currentUserIdProvider = Provider<String?>((Ref ref) {
  try {
    final AuthState state = ref.watch(authStateNotifierProvider);

    // 認証状態のログ記録
    if (state.isAuthenticated && state.userId != null) {
      log.d("認証済みユーザー: userId=${state.userId}", tag: "auth_providers");
    } else if (!state.isAuthenticated) {
      log.d("未認証状態", tag: "auth_providers");
    } else {
      // 認証済みなのにuserIdがnullの異常状態
      log.w("認証済み状態ですがユーザーIDが取得できません", tag: "auth_providers");
    }

    return state.userId;
  } catch (error, stackTrace) {
    log.e("ユーザーID取得中にエラーが発生しました", error: error, st: stackTrace, tag: "auth_providers");
    return null;
  }
});
