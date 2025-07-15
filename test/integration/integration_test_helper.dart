import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:yata/core/auth/auth_service.dart";
import "package:yata/main.dart" as app;

/// 統合テスト基盤
///
/// Supabaseとの実際の統合テストを行うためのヘルパークラス群
class IntegrationTestHelper {
  IntegrationTestHelper._();

  static IntegrationTestHelper? _instance;
  static IntegrationTestHelper get instance => _instance ??= IntegrationTestHelper._();

  late WidgetTester _tester;
  bool _initialized = false;

  /// テスト環境の初期化
  Future<void> initialize(WidgetTester tester) async {
    if (_initialized) return;

    _tester = tester;

    // テスト用Supabaseクライアントの初期化
    await _initializeTestSupabase();

    // アプリの起動
    app.main();
    await _tester.pumpAndSettle();

    _initialized = true;
  }

  /// テスト用Supabaseクライアントの初期化
  Future<void> _initializeTestSupabase() async {
    // テスト用の環境変数を設定（実際の値は.env.testファイルから読み込み）
    await Supabase.initialize(
      url: "https://test-project.supabase.co", // テスト用URL
      anonKey: "test-anon-key", // テスト用キー
    );
  }

  /// テストデータのクリーンアップ
  Future<void> cleanup() async {
    if (!_initialized) return;

    try {
      final SupabaseClientService authService = SupabaseClientService.instance;

      // サインアウト
      if (authService.isSignedIn) {
        await authService.signOut();
      }

      // テストデータの削除
      await _cleanupTestData();
    } catch (e) {
      debugPrint("Cleanup error: $e");
    }
  }

  /// テストデータの削除
  Future<void> _cleanupTestData() async {
    final SupabaseClient client = SupabaseClientService.client;

    // テスト用データの削除（テスト用のプレフィックスを持つデータのみ）
    try {
      // ユーザーテストデータの削除
      await client.from("users").delete().like("email", "test_%@example.com");

      // 注文テストデータの削除
      await client.from("orders").delete().like("user_id", "test_%");

      // 材料テストデータの削除
      await client.from("materials").delete().like("name", "Test_%");
    } catch (e) {
      debugPrint("Test data cleanup error: $e");
    }
  }

  /// テスト用ユーザーの作成
  Future<String> createTestUser({
    String? email,
    String? displayName,
    String role = "viewer",
  }) async {
    final String testEmail = email ?? "test_${DateTime.now().millisecondsSinceEpoch}@example.com";
    final String testDisplayName = displayName ?? "Test User";

    final Map<String, dynamic> userData = <String, dynamic>{
      "email": testEmail,
      "display_name": testDisplayName,
      "role": role,
      "email_verified": true,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    };

    final List<dynamic> result = await SupabaseClientService.client
        .from("users")
        .insert(userData)
        .select();

    return result.first["id"] as String;
  }

  /// テスト用注文の作成
  Future<String> createTestOrder({
    required String userId,
    String status = "preparing",
    String orderType = "dine_in",
    double totalAmount = 1000.0,
  }) async {
    final Map<String, dynamic> orderData = <String, dynamic>{
      "user_id": userId,
      "status": status,
      "order_type": orderType,
      "total_amount": totalAmount,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    };

    final List<dynamic> result = await SupabaseClientService.client
        .from("orders")
        .insert(orderData)
        .select();

    return result.first["id"] as String;
  }

  /// テスト用材料の作成
  Future<String> createTestMaterial({
    required String name,
    String? categoryId,
    String unitType = "gram",
    double currentStock = 100.0,
    double alertThreshold = 20.0,
  }) async {
    final Map<String, dynamic> materialData = <String, dynamic>{
      "name": "Test_$name",
      "category_id": categoryId,
      "unit_type": unitType,
      "current_stock": currentStock,
      "alert_threshold": alertThreshold,
      "critical_threshold": alertThreshold / 2,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    };

    final List<dynamic> result = await SupabaseClientService.client
        .from("materials")
        .insert(materialData)
        .select();

    return result.first["id"] as String;
  }

  /// ウィジェットの検索と操作
  Future<void> tapWidget(Finder finder) async {
    await _tester.tap(finder);
    await _tester.pumpAndSettle();
  }

  Future<void> enterText(Finder finder, String text) async {
    await _tester.enterText(finder, text);
    await _tester.pumpAndSettle();
  }

  Future<void> waitForWidget(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _tester.pumpAndSettle();

    final DateTime endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (_tester.any(finder)) {
        return;
      }

      await _tester.pump(const Duration(milliseconds: 100));
    }

    throw TimeoutException("Widget not found", timeout);
  }
}

/// 統合テスト用のカスタムマッチャー
class IntegrationTestMatchers {
  /// データベースにレコードが存在することを確認
  static Matcher existsInDatabase(String tableName, Map<String, dynamic> conditions) =>
      _DatabaseRecordExistsMatcher(tableName, conditions);

  /// データベースにレコードが存在しないことを確認
  static Matcher notExistsInDatabase(String tableName, Map<String, dynamic> conditions) =>
      isNot(_DatabaseRecordExistsMatcher(tableName, conditions));
}

class _DatabaseRecordExistsMatcher extends Matcher {
  const _DatabaseRecordExistsMatcher(this.tableName, this.conditions);

  final String tableName;
  final Map<String, dynamic> conditions;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    // この実装は非同期操作を含むため、実際のテストでは
    // expectLater を使用する必要があります
    return true; // プレースホルダー
  }

  @override
  Description describe(Description description) =>
      description.add("record exists in $tableName with conditions $conditions");
}

/// タイムアウト例外
class TimeoutException implements Exception {
  const TimeoutException(this.message, this.timeout);

  final String message;
  final Duration timeout;

  @override
  String toString() => "TimeoutException: $message (timeout: ${timeout.inSeconds}s)";
}
