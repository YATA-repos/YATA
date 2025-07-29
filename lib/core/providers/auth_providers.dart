import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../auth/auth_service.dart";

part "auth_providers.g.dart";

/// SupabaseClientService プロバイダー
/// 既存の認証サービスをRiverpodで利用可能にする
@riverpod
SupabaseClientService supabaseClientService(Ref ref) => SupabaseClientService.instance;

/// Supabaseクライアントプロバイダー
/// Supabaseクライアントインスタンスを提供
@riverpod
SupabaseClient supabaseClient(Ref ref) => SupabaseClientService.client;

/// 現在のユーザープロバイダー
/// ログイン済みのユーザー情報を取得
@riverpod
User? currentUser(Ref ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
}

/// 認証状態プロバイダー
/// ユーザーのログイン状態を監視
@riverpod
Stream<AuthState> authStateStream(Ref ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}

/// ユーザーIDプロバイダー
/// 現在のユーザーIDを取得（ログイン状態に応じて）
@riverpod
String? currentUserId(Ref ref) {
  final User? user = ref.watch(currentUserProvider);
  return user?.id;
}

/// ユーザー表示名プロバイダー
/// 現在のユーザーの表示名を取得
@riverpod
String? currentUserDisplayName(Ref ref) {
  final User? user = ref.watch(currentUserProvider);
  return user?.userMetadata?["display_name"] as String? ??
      user?.userMetadata?["name"] as String? ??
      user?.email;
}

/// ログイン状態プロバイダー
/// ユーザーがログインしているかどうかを判定
@riverpod
bool isLoggedIn(Ref ref) {
  final User? user = ref.watch(currentUserProvider);
  return user != null;
}

/// UI状態管理：認証エラー
@riverpod
class AuthError extends _$AuthError {
  @override
  String? build() => null;

  /// エラーを設定
  void setError(String error) {
    state = error;
  }

  /// エラーをクリア
  void clearError() {
    state = null;
  }
}

/// UI状態管理：認証ローディング状態
@riverpod
class AuthLoading extends _$AuthLoading {
  @override
  bool build() => false;

  /// ローディング状態を設定
  void setLoading(bool loading) {
    state = loading;
  }
}

/// セッション管理プロバイダー
/// セッションの有効性とリフレッシュを管理
@riverpod
class SessionManager extends _$SessionManager {
  @override
  Session? build() {
    final SupabaseClient client = ref.watch(supabaseClientProvider);
    return client.auth.currentSession;
  }

  /// セッションをリフレッシュ
  Future<void> refreshSession() async {
    final SupabaseClient client = ref.watch(supabaseClientProvider);
    try {
      await client.auth.refreshSession();
      // セッションが更新されたら状態を更新
      final Session? newSession = client.auth.currentSession;
      state = newSession;
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError("セッションの更新に失敗しました: $e");
    }
  }

  /// セッションの有効性をチェック
  bool isSessionValid() {
    if (state == null) {
      return false;
    }

    final int? expiresAt = state!.expiresAt;
    if (expiresAt == null) {
      return true; // 有効期限がない場合は有効
    }

    // 現在時刻より30秒後に期限切れになる場合は無効と判定
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt > now + 30;
  }

  /// セッションをクリア
  void clearSession() {
    state = null;
  }
}

/// ユーザープロファイル管理プロバイダー
/// ユーザーの追加情報を管理
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Map<String, dynamic>? build() {
    final User? user = ref.watch(currentUserProvider);
    return user?.userMetadata;
  }

  /// プロファイルを更新
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final SupabaseClient client = ref.watch(supabaseClientProvider);
    try {
      ref.read(authLoadingProvider.notifier).setLoading(true);

      final UserResponse response = await client.auth.updateUser(UserAttributes(data: updates));

      if (response.user != null) {
        state = response.user!.userMetadata;
      }
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError("プロファイルの更新に失敗しました: $e");
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }
}
