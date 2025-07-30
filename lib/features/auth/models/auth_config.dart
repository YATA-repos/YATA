import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:json_annotation/json_annotation.dart";

part "auth_config.g.dart";

/// 認証設定モデル
/// 
/// プラットフォーム別の認証設定を管理します。
/// Callback URLの自動判定やOAuth設定を提供します。
@JsonSerializable()
class AuthConfig {
  AuthConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.callbackUrl,
    required this.platform,
    this.scopes = const <String>["email", "openid"],
  });

  /// JSONからインスタンスを作成
  factory AuthConfig.fromJson(Map<String, dynamic> json) => _$AuthConfigFromJson(json);

  /// 現在のプラットフォーム用の設定を作成
  factory AuthConfig.forCurrentPlatform() => AuthConfig(
      supabaseUrl: _getSupabaseUrl(),
      supabaseAnonKey: _getSupabaseAnonKey(),
      callbackUrl: _getCallbackUrl(),
      platform: _getCurrentPlatform(),
    );

  /// Supabase URL
  final String supabaseUrl;

  /// Supabase Anonymous Key
  final String supabaseAnonKey;

  /// OAuth Callback URL
  final String callbackUrl;

  /// 実行プラットフォーム
  final AuthPlatform platform;

  /// OAuth スコープ
  final List<String> scopes;

  /// JSONに変換
  Map<String, dynamic> toJson() => _$AuthConfigToJson(this);

  /// 現在のプラットフォームを取得
  static AuthPlatform _getCurrentPlatform() {
    if (kIsWeb) {
      return AuthPlatform.web;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return AuthPlatform.android;
        case TargetPlatform.iOS:
          return AuthPlatform.ios;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
          return AuthPlatform.desktop;
        case TargetPlatform.fuchsia:
          return AuthPlatform.other;
      }
    }
  }

  /// プラットフォーム別Callback URL取得
  static String _getCallbackUrl() {
    if (kIsWeb) {
      // Web環境の場合
      if (kDebugMode) {
        // 開発環境
        return dotenv.env["SUPABASE_OAUTH_CALLBACK_URL_DEV"] ?? "http://localhost:8080";
      } else {
        // 本番環境
        return dotenv.env["SUPABASE_OAUTH_CALLBACK_URL_PROD"] ?? "https://example.invalid";
      }
    } else {
      // Desktop/Mobile環境
      // ! これ正当か？
      return "com.example.yata://login";
    }
  }

  /// Supabase URL取得
  static String _getSupabaseUrl() {
    final String? url = dotenv.env["SUPABASE_URL"];
    if (url == null || url.isEmpty) {
      throw AuthConfigException("SUPABASE_URL is not configured");
    }
    return url;
  }

  /// Supabase Anonymous Key取得
  static String _getSupabaseAnonKey() {
    final String? key = dotenv.env["SUPABASE_ANON_KEY"];
    if (key == null || key.isEmpty) {
      throw AuthConfigException("SUPABASE_ANON_KEY is not configured");
    }
    return key;
  }

  /// Google OAuthプロバイダー設定取得
  Map<String, dynamic> get googleOAuthConfig => <String, dynamic>{
    "provider": "google",
    "redirectTo": callbackUrl,
    "scopes": scopes.join(" "),
  };

  /// デバッグ情報を取得
  Map<String, String> get debugInfo => <String, String>{
    "platform": platform.name,
    "callbackUrl": callbackUrl,
    "isWeb": kIsWeb.toString(),
    "isDebug": kDebugMode.toString(),
    "hasSupabaseUrl": supabaseUrl.isNotEmpty.toString(),
    "hasSupabaseKey": supabaseAnonKey.isNotEmpty.toString(),
  };
}

/// 認証プラットフォーム
enum AuthPlatform {
  web,
  android,
  ios,
  desktop,
  other;

  /// プラットフォーム名
  String get displayName {
    switch (this) {
      case AuthPlatform.web:
        return "Web";
      case AuthPlatform.android:
        return "Android";
      case AuthPlatform.ios:
        return "iOS";
      case AuthPlatform.desktop:
        return "Desktop";
      case AuthPlatform.other:
        return "Other";
    }
  }

  /// Deep Link対応プラットフォームかどうか
  bool get supportsDeepLink => this == AuthPlatform.android || this == AuthPlatform.ios || this == AuthPlatform.desktop;
}

/// 認証設定例外
class AuthConfigException implements Exception {
  const AuthConfigException(this.message);

  final String message;

  @override
  String toString() => "AuthConfigException: $message";
}