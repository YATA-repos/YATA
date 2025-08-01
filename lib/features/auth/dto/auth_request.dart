import "package:json_annotation/json_annotation.dart";

part "auth_request.g.dart";

/// 認証プロバイダー
enum AuthProvider {
  google("google"),
  email("email");

  const AuthProvider(this.providerName);

  /// プロバイダー名
  final String providerName;

  /// 表示名
  String get displayName {
    switch (this) {
      case AuthProvider.google:
        return "Google";
      case AuthProvider.email:
        return "Email";
    }
  }

  /// アイコン名（UI用）
  String get iconName {
    switch (this) {
      case AuthProvider.google:
        return "google";
      case AuthProvider.email:
        return "email";
    }
  }

  /// OAuth対応プロバイダーかどうか
  bool get isOAuth => this == AuthProvider.google;

  /// 文字列からプロバイダーを取得
  static AuthProvider? fromString(String value) {
    for (final AuthProvider provider in AuthProvider.values) {
      if (provider.providerName == value) {
        return provider;
      }
    }
    return null;
  }
}

/// 認証リクエストDTO
/// 
/// OAuth認証リクエストのパラメータを管理します。
/// 認証プロバイダーや設定情報を含みます。
@JsonSerializable()
class AuthRequest {
  AuthRequest({
    required this.provider,
    required this.redirectTo,
    this.scopes = const <String>["email", "openid"],
    this.state,
    this.queryParams = const <String, String>{},
  });

  /// JSONからインスタンスを作成
  factory AuthRequest.fromJson(Map<String, dynamic> json) => _$AuthRequestFromJson(json);

  /// Google OAuth認証リクエスト
  factory AuthRequest.google({
    required String redirectTo,
    List<String>? scopes,
    String? state,
    Map<String, String>? queryParams,
  }) => AuthRequest(
      provider: AuthProvider.google,
      redirectTo: redirectTo,
      scopes: scopes ?? <String>["email", "openid", "profile"],
      state: state,
      queryParams: queryParams ?? <String, String>{},
    );

  /// 認証プロバイダー
  final AuthProvider provider;

  /// リダイレクト先URL
  final String redirectTo;

  /// OAuth スコープ
  final List<String> scopes;

  /// 状態パラメータ（CSRF対策）
  final String? state;

  /// 追加のクエリパラメータ
  final Map<String, String> queryParams;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthRequestToJson(this);

  /// Supabase OAuth用パラメータに変換
  Map<String, dynamic> toSupabaseOAuthParams() => <String, dynamic>{
      "provider": provider.providerName,
      "options": <String, dynamic>{
        "redirectTo": redirectTo,
        if (scopes.isNotEmpty) "scopes": scopes.join(" "),
        if (state != null) "state": state,
        "queryParams": <String, dynamic>{
          ...queryParams,
        },
      },
    };

  /// デバッグ用文字列表現
  @override
  String toString() => "AuthRequest("
        "provider: ${provider.displayName}, "
        "redirectTo: $redirectTo, "
        "scopes: ${scopes.join(", ")}"
        ")";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthRequest &&
        other.provider == provider &&
        other.redirectTo == redirectTo &&
        other.scopes.toString() == scopes.toString() &&
        other.state == state &&
        other.queryParams.toString() == queryParams.toString();
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
      provider,
      redirectTo,
      Object.hashAll(scopes),
      state,
      Object.hashAll(queryParams.entries.map((MapEntry<String, String> e) => Object.hash(e.key, e.value))),
    ]);
}

/// ログアウトリクエストDTO
@JsonSerializable()
class LogoutRequest {
  LogoutRequest({
    this.allDevices = false,
    this.redirectTo,
  });

  /// JSONからインスタンスを作成
  factory LogoutRequest.fromJson(Map<String, dynamic> json) => _$LogoutRequestFromJson(json);

  /// 全デバイスからログアウトするかどうか
  final bool allDevices;

  /// ログアウト後のリダイレクト先URL
  final String? redirectTo;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$LogoutRequestToJson(this);

  /// Supabase signOut用パラメータに変換
  Map<String, dynamic> toSupabaseSignOutParams() => <String, dynamic>{
      "scope": allDevices ? "global" : "local",
    };

  @override
  String toString() => "LogoutRequest(allDevices: $allDevices, redirectTo: $redirectTo)";
}