import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "integration_test_helper.dart";

/// 統合テスト基盤設定
///
/// 全ての統合テストで共通して使用される設定とセットアップ
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Integration Test Setup", () {
    late IntegrationTestHelper helper;

    setUpAll(() async {
      // テスト環境の初期化
      helper = IntegrationTestHelper.instance;

      // システムUI設定（テスト中のバックグラウンド動作を制御）
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: <SystemUiOverlay>[]);
    });

    setUp(() async {
      // 各テスト前のクリーンアップ
      await helper.cleanup();
    });

    tearDown(() async {
      // 各テスト後のクリーンアップ
      await helper.cleanup();
    });

    tearDownAll(() async {
      // 最終クリーンアップ
      await helper.cleanup();

      // システムUI設定を元に戻す
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    });

    testWidgets("Integration test setup validation", (WidgetTester tester) async {
      await helper.initialize(tester);

      // 基本的なアプリ起動テスト
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
