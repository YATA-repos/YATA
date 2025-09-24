import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart" hide AuthException;

import "../../core/base/base_error_msg.dart";
import "../../core/constants/exceptions/auth/auth_exception.dart";
import "../../core/constants/log_enums/auth.dart";
import "../logging/logger.dart" as log;

/// Supabaseクライアント管理サービス
///
/// Supabaseクライアントの初期化と基本操作を提供します。
/// 既存実装からSupabaseクライアント管理を抽出した軽量版です。
class SupabaseClientService {
  SupabaseClientService._();

  static SupabaseClientService? _instance;
  static SupabaseClient? _client;

  /// シングルトンインスタンス取得
  static SupabaseClientService get instance {
    _instance ??= SupabaseClientService._();
    return _instance!;
  }

  /// Supabaseクライアント取得
  static SupabaseClient get client {
    if (_client == null) {
      throw AuthException.initializationFailed(
        "Supabase client is not initialized. Call initialize() first.",
      );
    }
    return _client!;
  }

  /// 環境変数からSupabase URL取得
  static String get _supabaseUrl {
    final String? url = dotenv.env["SUPABASE_URL"];
    if (url == null || url.isEmpty) {
      throw AuthException.initializationFailed("SUPABASE_URL is not set in environment variables");
    }
    return url;
  }

  /// 環境変数からSupabase Anonymous Key取得
  static String get _supabaseAnonKey {
    final String? key = dotenv.env["SUPABASE_ANON_KEY"];
    if (key == null || key.isEmpty) {
      throw AuthException.initializationFailed(
        "SUPABASE_ANON_KEY is not set in environment variables",
      );
    }
    return key;
  }

  /// Supabaseクライアント初期化
  ///
  /// アプリケーション起動時に一度だけ呼び出してください。
  static Future<void> initialize() async {
    if (_client != null) {
      log.i("Client already initialized, skipping", tag: "SupabaseClientService");
      return;
    }

    try {
      log.i("Starting Supabase client initialization", tag: "SupabaseClientService");

      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

      _client = Supabase.instance.client;
      log.i(AuthInfo.clientInitialized.message, tag: "SupabaseClientService");
    } catch (e) {
      log.e(
        AuthError.initializationFailed.withParams(<String, String>{"error": e.toString()}),
        error: e,
        tag: "SupabaseClientService",
      );
      throw AuthException.initializationFailed(e.toString());
    }
  }

  /// Supabase接続テスト
  ///
  /// Returns: 接続成功時はtrue
  static Future<bool> testConnection() async {
    try {
      // 簡単な接続テスト
      await _client?.from("test").select().limit(1).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      // テーブルが存在しないエラーも接続成功とみなす
      if (e is PostgrestException && e.code == "PGRST116") {
        return true;
      }
      log.e("Connection test failed: $e", tag: "SupabaseClientService");
      return false;
    }
  }

  /// クライアント初期化済みチェック
  static bool get isInitialized => _client != null;

  /// クライアント終了処理
  static Future<void> dispose() async {
    _client = null;
    _instance = null;
  }
}
