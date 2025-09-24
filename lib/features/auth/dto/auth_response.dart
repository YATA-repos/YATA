import "package:json_annotation/json_annotation.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../models/user_profile.dart";

part "auth_response.g.dart";

/// 認証レスポンスDTO
///
/// OAuth認証の結果を管理します。
/// ユーザー情報、セッション情報、エラー情報を含みます。
@JsonSerializable()
class AuthResponse {
  AuthResponse({
    required this.success,
    this.user,
    this.session,
    this.error,
    this.errorDescription,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSONからインスタンスを作成
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);

  /// 認証成功レスポンス
  factory AuthResponse.success({required UserProfile user, AuthSession? session}) =>
      AuthResponse(success: true, user: user, session: session);

  /// 認証失敗レスポンス
  factory AuthResponse.failure({required String error, String? errorDescription}) =>
      AuthResponse(success: false, error: error, errorDescription: errorDescription);

  /// Supabase AuthResponse から作成
  factory AuthResponse.fromSupabase(dynamic supabaseResponse) {
    try {
      if (supabaseResponse.user != null && supabaseResponse.session != null) {
        return AuthResponse.success(
          user: UserProfile.fromSupabaseUser(supabaseResponse.user as User),
          session: AuthSession.fromSupabase(supabaseResponse.session),
        );
      } else {
        return AuthResponse.failure(
          error: "authentication_failed",
          errorDescription: "No user or session data received",
        );
      }
    } catch (e) {
      return AuthResponse.failure(
        error: "parse_error",
        errorDescription: "Failed to parse Supabase response: $e",
      );
    }
  }

  /// 認証成功フラグ
  final bool success;

  /// ユーザー情報
  final UserProfile? user;

  /// セッション情報
  final AuthSession? session;

  /// エラーコード
  final String? error;

  /// エラー詳細説明
  final String? errorDescription;

  /// レスポンス作成日時
  final DateTime timestamp;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  /// 認証成功かどうか
  bool get isSuccess => success && user != null;

  /// 認証失敗かどうか
  bool get isFailure => !success || error != null;

  /// アクセストークンを取得
  String? get accessToken => session?.accessToken;

  /// リフレッシュトークンを取得
  String? get refreshToken => session?.refreshToken;

  /// セッション有効期限を取得
  DateTime? get expiresAt => session?.expiresAt;

  /// デバッグ用文字列表現
  @override
  String toString() {
    if (isSuccess) {
      return "AuthResponse.success(user: ${user?.email}, hasSession: ${session != null})";
    } else {
      return "AuthResponse.failure(error: $error, description: $errorDescription)";
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthResponse &&
        other.success == success &&
        other.user == user &&
        other.session == session &&
        other.error == error &&
        other.errorDescription == errorDescription;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[success, user, session, error, errorDescription]);
}

/// 認証セッション情報
@JsonSerializable()
class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.expiresAt,
    this.refreshToken,
    this.user,
    this.providerToken,
    this.providerRefreshToken,
  });

  /// JSONからインスタンスを作成
  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

  /// Supabase Session から作成
  factory AuthSession.fromSupabase(dynamic supabaseSession) => AuthSession(
    accessToken: supabaseSession.accessToken as String,
    tokenType: supabaseSession.tokenType as String? ?? "bearer",
    expiresIn: supabaseSession.expiresIn as int? ?? 3600,
    expiresAt: supabaseSession.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch((supabaseSession.expiresAt as int) * 1000)
        : DateTime.now().add(const Duration(seconds: 3600)),
    refreshToken: supabaseSession.refreshToken as String?,
    user: supabaseSession.user != null
        ? UserProfile.fromSupabaseUser(supabaseSession.user as User)
        : null,
    providerToken: supabaseSession.providerToken as String?,
    providerRefreshToken: supabaseSession.providerRefreshToken as String?,
  );

  /// アクセストークン
  final String accessToken;

  /// トークンタイプ（通常は "bearer"）
  final String tokenType;

  /// 有効期限（秒）
  final int expiresIn;

  /// 有効期限日時
  final DateTime expiresAt;

  /// リフレッシュトークン
  final String? refreshToken;

  /// ユーザー情報
  final UserProfile? user;

  /// プロバイダートークン（Google等）
  final String? providerToken;

  /// プロバイダーリフレッシュトークン
  final String? providerRefreshToken;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthSessionToJson(this);

  /// セッションが有効かどうか
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// セッションの残り時間（秒）
  int get remainingSeconds {
    final int remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// セッションが期限切れ間近かどうか（5分以内）
  bool get isExpiringSoon => remainingSeconds <= 300;

  /// Authorizationヘッダー用の値
  String get authorizationHeader => "$tokenType $accessToken";

  @override
  String toString() =>
      "AuthSession("
      "tokenType: $tokenType, "
      "expiresAt: $expiresAt, "
      "isValid: $isValid, "
      "hasRefreshToken: ${refreshToken != null}"
      ")";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthSession &&
        other.accessToken == accessToken &&
        other.tokenType == tokenType &&
        other.expiresAt == expiresAt &&
        other.refreshToken == refreshToken &&
        other.user == user;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[accessToken, tokenType, expiresAt, refreshToken, user]);
}
