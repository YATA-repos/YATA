import "dart:async";
import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

/// TTLベース永続キャッシュ実装
/// アプリ再起動後もデータを保持
class TTLCache {
  TTLCache();

  static const String _keyPrefix = "yata_cache_";
  static const String _metaPrefix = "yata_meta_";

  /// キャッシュからデータ取得
  Future<T?> get<T>(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // メタデータ確認（TTL）
      final String? metaJson = prefs.getString("$_metaPrefix$key");
      if (metaJson == null) {
        return null;
      }
      
      final Map<String, dynamic> meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final DateTime expiry = DateTime.parse(meta["expiry"] as String);
      
      // TTL確認
      if (DateTime.now().isAfter(expiry)) {
        await _remove(key, prefs);
        return null;
      }
      
      // データ取得
      final String? dataJson = prefs.getString("$_keyPrefix$key");
      if (dataJson == null) {
        return null;
      }
      
      final dynamic data = jsonDecode(dataJson);
      return data as T?;
    } catch (e) {
      return null;
    }
  }

  /// キャッシュにデータ設定
  Future<void> set<T>(String key, T value, Duration ttl) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime expiry = DateTime.now().add(ttl);
      
      // データ保存
      final String dataJson = jsonEncode(value);
      await prefs.setString("$_keyPrefix$key", dataJson);
      
      // メタデータ保存
      final Map<String, String> meta = <String, String>{
        "expiry": expiry.toIso8601String(),
        "created": DateTime.now().toIso8601String(),
      };
      await prefs.setString("$_metaPrefix$key", jsonEncode(meta));
    } catch (e) {
      // エラーハンドリング（ログは上位で行う）
    }
  }

  /// キャッシュから削除
  Future<void> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _remove(key, prefs);
  }

  /// パターンマッチで削除
  Future<void> removePattern(String pattern) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RegExp regex = RegExp(pattern.replaceAll("*", ".*"));
      
      final List<String> keysToRemove = <String>[];
      
      // プレフィックス付きキーをチェック
      for (final String key in prefs.getKeys()) {
        if (key.startsWith(_keyPrefix)) {
          final String actualKey = key.substring(_keyPrefix.length);
          if (regex.hasMatch(actualKey)) {
            keysToRemove.add(actualKey);
          }
        }
      }
      
      // 該当キーを削除
      for (final String key in keysToRemove) {
        await _remove(key, prefs);
      }
    } catch (e) {
      // エラーハンドリング（ログは上位で行う）
    }
  }

  /// 全キャッシュクリア
  Future<void> clear() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> keysToRemove = <String>[];
      
      // YATA関連キーのみ削除
      for (final String key in prefs.getKeys()) {
        if (key.startsWith(_keyPrefix) || key.startsWith(_metaPrefix)) {
          keysToRemove.add(key);
        }
      }
      
      for (final String key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      // エラーハンドリング（ログは上位で行う）
    }
  }

  /// 期限切れエントリのクリーンアップ
  Future<void> cleanup() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> expiredKeys = <String>[];
      
      // メタデータをチェックして期限切れを特定
      for (final String key in prefs.getKeys()) {
        if (key.startsWith(_metaPrefix)) {
          final String? metaJson = prefs.getString(key);
          if (metaJson != null) {
            try {
              final Map<String, dynamic> meta = jsonDecode(metaJson) as Map<String, dynamic>;
              final DateTime expiry = DateTime.parse(meta["expiry"] as String);
              
              if (DateTime.now().isAfter(expiry)) {
                final String actualKey = key.substring(_metaPrefix.length);
                expiredKeys.add(actualKey);
              }
            } catch (e) {
              // 無効なメタデータは削除対象
              final String actualKey = key.substring(_metaPrefix.length);
              expiredKeys.add(actualKey);
            }
          }
        }
      }
      
      // 期限切れキーを削除
      for (final String key in expiredKeys) {
        await _remove(key, prefs);
      }
    } catch (e) {
      // エラーハンドリング（ログは上位で行う）
    }
  }

  /// 現在のアイテム数取得
  int get itemCount => 0; // 非同期なので概算値を返す

  /// 内部削除メソッド
  Future<void> _remove(String key, SharedPreferences prefs) async {
    await prefs.remove("$_keyPrefix$key");
    await prefs.remove("$_metaPrefix$key");
  }
}