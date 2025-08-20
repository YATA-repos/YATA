import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/logging/yata_logger.dart";
import "../../../models/auth_state.dart";

/// 認証状態(State)のプロバイダー
/// テストでは初期状態の読み出しのみを行うため、最小実装とする
final StateProvider<AuthState> authStateNotifierProvider =
    StateProvider<AuthState>((Ref ref) => AuthState.initial());

/// 現在のユーザーIDを公開するProvider
final Provider<String?> currentUserIdProvider = Provider<String?>((Ref ref) {
  try {
    final AuthState state = ref.watch(authStateNotifierProvider);
    
    // 認証状態のログ記録
    if (state.isAuthenticated && state.userId != null) {
      YataLogger.debug("auth_providers", "認証済みユーザー: userId=${state.userId}");
    } else if (!state.isAuthenticated) {
      YataLogger.debug("auth_providers", "未認証状態");
    } else {
      // 認証済みなのにuserIdがnullの異常状態
      YataLogger.warning("auth_providers", "認証済み状態ですがユーザーIDが取得できません");
    }
    
    return state.userId;
  } catch (error, stackTrace) {
    YataLogger.error(
      "auth_providers",
      "ユーザーID取得中にエラーが発生しました",
      error,
      stackTrace,
    );
    return null;
  }
});

