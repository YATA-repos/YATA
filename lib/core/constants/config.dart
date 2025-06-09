import "package:flutter_dotenv/flutter_dotenv.dart";

/// 主にdotenvから値を取得するためのクラス
class Config {
  /// dotenvをloadする
  static Future<void> load() async {
    await dotenv.load();
  }

  // Supabaseの各種定数の取得

  static String get supabaseUrl => dotenv.env["SUPABASE_URL"] ?? "";
  static String get supabaseAnonKey => dotenv.env["SUPABASE_ANON_KEY"] ?? "";
  static String get supabaseAuthCallbackUrl =>
      dotenv.env["SUPABASE_AUTH_CALLBACK_URL"] ?? "";
}
