import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../integration_test_helper.dart";

/// 認証機能の統合テスト
///
/// 実際のSupabaseとの連携を含む認証フローのテスト
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Authentication Integration Tests", () {
    late IntegrationTestHelper helper;

    setUpAll(() async {
      helper = IntegrationTestHelper.instance;
    });

    setUp(() async {
      await helper.cleanup();
    });

    tearDown(() async {
      await helper.cleanup();
    });

    testWidgets("User can sign in and sign out", (WidgetTester tester) async {
      await helper.initialize(tester);

      // テスト用ユーザーの作成
      await helper.createTestUser(
        email: "test_auth_user@example.com",
        displayName: "Test Auth User",
        role: "admin",
      );

      // ログイン画面への遷移
      await helper.tapWidget(find.byKey(const Key("login_button")));
      await helper.waitForWidget(find.byKey(const Key("email_field")));

      // ログイン情報の入力
      await helper.enterText(find.byKey(const Key("email_field")), "test_auth_user@example.com");
      await helper.enterText(find.byKey(const Key("password_field")), "test_password");

      // ログインボタンのタップ
      await helper.tapWidget(find.byKey(const Key("sign_in_button")));

      // ダッシュボード画面への遷移を確認
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));
      expect(find.byKey(const Key("dashboard_screen")), findsOneWidget);

      // ユーザー情報の表示確認
      expect(find.text("Test Auth User"), findsOneWidget);

      // サインアウトの実行
      await helper.tapWidget(find.byKey(const Key("profile_menu")));
      await helper.waitForWidget(find.byKey(const Key("sign_out_button")));
      await helper.tapWidget(find.byKey(const Key("sign_out_button")));

      // ログイン画面への遷移を確認
      await helper.waitForWidget(find.byKey(const Key("login_screen")));
      expect(find.byKey(const Key("login_screen")), findsOneWidget);
    });

    testWidgets("Session refresh works correctly", (WidgetTester tester) async {
      await helper.initialize(tester);

      // テスト用ユーザーでログイン
      await helper.createTestUser(
        email: "test_session_user@example.com",
        displayName: "Test Session User",
      );

      // ログイン処理（省略形）
      await _performLogin(helper, "test_session_user@example.com");

      // セッション情報の取得
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));

      // アプリをバックグラウンドに移動（セッション期限切れをシミュレート）
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        "flutter/lifecycle",
        const StandardMethodCodec().encodeMethodCall(const MethodCall("AppLifecycleState.paused")),
        (ByteData? data) {},
      );

      // 一定時間待機
      await tester.pump(const Duration(seconds: 2));

      // アプリをフォアグラウンドに復帰
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        "flutter/lifecycle",
        const StandardMethodCodec().encodeMethodCall(const MethodCall("AppLifecycleState.resumed")),
        (ByteData? data) {},
      );

      // セッションリフレッシュ後もダッシュボードが表示されることを確認
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));
      expect(find.byKey(const Key("dashboard_screen")), findsOneWidget);
    });

    testWidgets("Concurrent authentication requests are handled correctly", (
      WidgetTester tester,
    ) async {
      await helper.initialize(tester);

      await helper.createTestUser(
        email: "test_concurrent_user@example.com",
        displayName: "Test Concurrent User",
      );

      // ログイン処理
      await _performLogin(helper, "test_concurrent_user@example.com");
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));

      // 複数のAPI呼び出しを同時実行（セッションリフレッシュが同時に発生）
      final List<Future<void>> concurrentTasks = <Future<void>>[
        helper.tapWidget(find.byKey(const Key("inventory_tab"))),
        helper.tapWidget(find.byKey(const Key("orders_tab"))),
        helper.tapWidget(find.byKey(const Key("analytics_tab"))),
      ];

      // 同時実行の完了を待機
      await Future.wait(concurrentTasks);

      // アプリが正常に動作していることを確認
      expect(find.byKey(const Key("dashboard_screen")), findsOneWidget);

      // セッション状態が一貫していることを確認
      expect(find.text("Test Concurrent User"), findsOneWidget);
    });

    testWidgets("Authentication state persists across app restarts", (WidgetTester tester) async {
      await helper.initialize(tester);

      await helper.createTestUser(
        email: "test_persistence_user@example.com",
        displayName: "Test Persistence User",
      );

      // ログイン処理
      await _performLogin(helper, "test_persistence_user@example.com");
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));

      // アプリの再起動をシミュレート
      await tester.pumpWidget(Container()); // 空のウィジェット
      await tester.pumpAndSettle();

      // アプリの再初期化
      await helper.initialize(tester);

      // 自動ログイン状態の確認
      await helper.waitForWidget(find.byKey(const Key("dashboard_screen")));
      expect(find.byKey(const Key("dashboard_screen")), findsOneWidget);
      expect(find.text("Test Persistence User"), findsOneWidget);
    });
  });
}

/// ログイン処理のヘルパー関数
Future<void> _performLogin(IntegrationTestHelper helper, String email) async {
  await helper.tapWidget(find.byKey(const Key("login_button")));
  await helper.waitForWidget(find.byKey(const Key("email_field")));

  await helper.enterText(find.byKey(const Key("email_field")), email);
  await helper.enterText(find.byKey(const Key("password_field")), "test_password");

  await helper.tapWidget(find.byKey(const Key("sign_in_button")));
}
