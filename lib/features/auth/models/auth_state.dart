import "package:json_annotation/json_annotation.dart";

import "user_profile.dart";

part "auth_state.g.dart";

/// 認証状態モデル
///
/// 現在の認証状態とユーザー情報を管理します。
/// Riverpodプロバイダーで使用されます。
@JsonSerializable()
class AuthState {
  AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
    this.lastLoginAt,
  });

  /// JSONからインスタンスを作成
  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);

  /// 初期状態（未認証）
  factory AuthState.initial() => AuthState(status: AuthStatus.unauthenticated);

  /// 認証中状態
  factory AuthState.loading() => AuthState(status: AuthStatus.authenticating, isLoading: true);

  /// 認証成功状態
  factory AuthState.authenticated(UserProfile user) =>
      AuthState(status: AuthStatus.authenticated, user: user, lastLoginAt: DateTime.now());

  /// 認証エラー状態
  factory AuthState.error(String error) => AuthState(status: AuthStatus.error, error: error);

  /// 認証状態
  final AuthStatus status;

  /// ユーザー情報
  final UserProfile? user;

  /// エラーメッセージ
  final String? error;

  /// ローディング状態
  final bool isLoading;

  /// 最終ログイン日時
  final DateTime? lastLoginAt;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthStateToJson(this);

  /// 認証済みかどうか
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  /// 認証中かどうか
  bool get isAuthenticating => status == AuthStatus.authenticating || isLoading;

  /// エラー状態かどうか
  bool get hasError => status == AuthStatus.error && error != null;

  /// ユーザーIDを取得
  String? get userId => user?.id;

  /// ユーザー名を取得
  String? get userName => user?.displayName ?? user?.email;

  /// 状態をコピーして新しいインスタンスを作成
  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? error,
    bool? isLoading,
    DateTime? lastLoginAt,
    bool clearError = false,
    bool clearUser = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    error: clearError ? null : (error ?? this.error),
    isLoading: isLoading ?? this.isLoading,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  /// デバッグ用文字列表現
  @override
  String toString() =>
      "AuthState("
      "status: $status, "
      "isAuthenticated: $isAuthenticated, "
      "isLoading: $isLoading, "
      "hasError: $hasError, "
      "userId: $userId"
      ")";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.error == error &&
        other.isLoading == isLoading &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[status, user, error, isLoading, lastLoginAt]);
}

/// 認証ステータス
enum AuthStatus {
  /// 未認証
  unauthenticated,

  /// 認証中
  authenticating,

  /// 認証済み
  authenticated,

  /// 認証エラー
  error;

  /// ステータス名
  String get displayName {
    switch (this) {
      case AuthStatus.unauthenticated:
        return "未認証";
      case AuthStatus.authenticating:
        return "認証中";
      case AuthStatus.authenticated:
        return "認証済み";
      case AuthStatus.error:
        return "認証エラー";
    }
  }

  /// アクティブなステータスかどうか
  bool get isActive => this == AuthStatus.authenticated;

  /// ローディング状態かどうか
  bool get isLoading => this == AuthStatus.authenticating;
}
