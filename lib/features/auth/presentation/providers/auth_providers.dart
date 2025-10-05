import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../app/wiring/provider.dart";
import "../../../../core/contracts/logging/logger.dart";
import "../../models/auth_state.dart";
import "../controllers/auth_controller.dart";

/// 認証状態(State)のStateNotifierプロバイダー。
final StateNotifierProvider<AuthController, AuthState> authStateNotifierProvider =
    StateNotifierProvider<AuthController, AuthState>(
      (Ref ref) => AuthController(
        logger: ref.read(loggerProvider),
        authService: ref.read(authServiceProvider),
      ),
      name: "authStateNotifierProvider",
    );

/// 現在のユーザーIDを公開するProvider
final Provider<String?> currentUserIdProvider = Provider<String?>((Ref ref) {
  try {
    final AuthState state = ref.watch(authStateNotifierProvider);
    final LoggerContract logger = ref.read(loggerProvider);

    // 認証状態のログ記録
    if (state.isAuthenticated && state.userId != null) {
      logger.d("認証済みユーザー: userId=${state.userId}", tag: "auth_providers");
    } else if (!state.isAuthenticated) {
      logger.d("未認証状態", tag: "auth_providers");
    } else {
      // 認証済みなのにuserIdがnullの異常状態
      logger.w("認証済み状態ですがユーザーIDが取得できません", tag: "auth_providers");
    }

    return state.userId;
  } catch (error, stackTrace) {
    final LoggerContract logger = ref.read(loggerProvider);
    logger.e("ユーザーID取得中にエラーが発生しました", error: error, st: stackTrace, tag: "auth_providers");
    return null;
  }
});
