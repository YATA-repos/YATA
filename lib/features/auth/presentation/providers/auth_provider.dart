import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart" as supabase;

import "../../../../core/auth/auth_service.dart";
import "../../models/user_model.dart";
import "../../repositories/user_repository.dart";
import "../../services/auth_service.dart" as feature_auth;

part "auth_provider.g.dart";

/// Supabase認証サービスのProvider
@riverpod
SupabaseClientService authService(Ref ref) => SupabaseClientService.instance;

/// 現在のユーザー情報を取得するProvider
@Riverpod(keepAlive: false)
Future<UserModel?> currentUser(Ref ref) async {
  final SupabaseClientService supabaseService = ref.watch(authServiceProvider);
  if (!supabaseService.isSignedIn) {
    return null;
  }

  final UserRepository userRepository = UserRepository();
  final feature_auth.AuthService authService = feature_auth.AuthService(
    supabaseAuthService: supabaseService,
    userRepository: userRepository,
  );

  return authService.getCurrentUser();
}

/// 認証状態を管理するProvider
///
/// ユーザーがログインしているかどうかを監視します。
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<bool> build() async {
    final SupabaseClientService supabaseAuthService = ref.watch(authServiceProvider);

    // 認証状態の変更を監視
    ref.listen(authStateChangesProvider, (
      AsyncValue<supabase.User?>? previous,
      AsyncValue<supabase.User?> next,
    ) {
      next.whenData((supabase.User? user) {
        // ユーザーがnullでない場合は認証済み
        state = AsyncData<bool>(user != null);
      });
    });

    // 初期状態での認証確認
    return supabaseAuthService.isSignedIn;
  }

  /// Google認証でサインイン
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading<bool>();
    try {
      final SupabaseClientService supabaseService = ref.read(authServiceProvider);
      final UserRepository userRepository = UserRepository();
      final feature_auth.AuthService authService = feature_auth.AuthService(
        supabaseAuthService: supabaseService,
        userRepository: userRepository,
      );

      final UserModel? user = await authService.signInWithGoogle();

      if (user != null) {
        // 認証成功時は状態更新を待つ
        // authStateChangesProviderが自動的に状態を更新
        state = const AsyncData<bool>(true);
      } else {
        state = const AsyncData<bool>(false);
      }
    } catch (e, st) {
      state = AsyncError<bool>(e, st);
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      final SupabaseClientService authService = ref.read(authServiceProvider);
      await authService.signOut();
      // authStateChangesProviderが自動的に状態を更新
    } catch (e, st) {
      state = AsyncError<bool>(e, st);
    }
  }

  /// 認証コールバック処理
  Future<void> handleAuthCallback(String callbackUrl) async {
    try {
      final SupabaseClientService authService = ref.read(authServiceProvider);
      final supabase.User? user = await authService.handleAuthCallback(callbackUrl);

      // ユーザー情報が取得できた場合は認証成功
      state = AsyncData<bool>(user != null);
    } catch (e, st) {
      state = AsyncError<bool>(e, st);
    }
  }
}

/// 認証状態の変更を監視するProvider
///
/// Supabaseの認証状態変更をStreamで提供します。
@Riverpod(keepAlive: false)
Stream<supabase.User?> authStateChanges(Ref ref) {
  final SupabaseClientService authService = ref.watch(authServiceProvider);

  // ProviderがDispose時にStreamが自動的に破棄されるようにRiverpodのautoDisposeを利用
  ref.onDispose(() {
    // 必要に応じて追加のクリーンアップ処理をここに記述
  });

  return authService.authStateChanges.map((supabase.AuthState state) => state.session?.user);
}

/// 現在のSupabaseユーザー情報を取得するProvider
@Riverpod(keepAlive: false)
supabase.User? currentSupabaseUser(Ref ref) {
  final SupabaseClientService authService = ref.watch(authServiceProvider);
  return authService.currentUser;
}

/// 現在のセッション情報を取得するProvider
@Riverpod(keepAlive: false)
supabase.Session? currentSession(Ref ref) {
  final SupabaseClientService authService = ref.watch(authServiceProvider);
  return authService.currentSession;
}
