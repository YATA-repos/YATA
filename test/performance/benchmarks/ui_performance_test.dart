import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/shared/widgets/buttons/app_button.dart";
import "package:yata/shared/widgets/cards/app_card.dart";
import "package:yata/shared/widgets/forms/app_text_field.dart";

import "../helpers/performance_test_helper.dart";

/// UI描画パフォーマンステスト
/// 
/// ウィジェットの描画時間、アニメーション性能、
/// 大量データ表示の性能を検証する
void main() {
  group("UI Performance Tests", () {
    // =================================================================
    // 基本ウィジェット描画パフォーマンステスト
    // =================================================================

    testWidgets("AppButtonの描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "app_button_rendering",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 基本ボタンの描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppButton(
                    text: "テストボタン",
                    onPressed: () {},
                  ),
                ),
              ),
            );
          },
          
          // ボタン状態変更
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppButton(
                    text: "ローディング中",
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
              ),
            );
          },
          
          // 無効状態ボタン
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppButton(
                    text: "無効ボタン",
                    isEnabled: false,
                    onPressed: () {},
                  ),
                ),
              ),
            );
          },
        ],
      );

      expect(result.passed, isTrue,
          reason: "UI描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    testWidgets("AppTextFieldの描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "app_text_field_rendering",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 基本テキストフィールド描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppTextField(
                    labelText: "テストフィールド",
                    onChanged: (String value) {},
                  ),
                ),
              ),
            );
          },
          
          // エラー状態の描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppTextField(
                    labelText: "エラーフィールド",
                    errorText: "エラーが発生しました",
                    onChanged: (String value) {},
                  ),
                ),
              ),
            );
          },
          
          // テキスト入力シミュレーション
          (WidgetTester tester) async {
            await tester.enterText(
              find.byType(TextField),
              "パフォーマンステスト用の長いテキスト入力をシミュレートします"
            );
          },
        ],
      );

      expect(result.passed, isTrue,
          reason: "UI描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    testWidgets("BaseCardの描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "base_card_rendering",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 基本カード描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppCard(
                    title: "テストカード",
                    child: SizedBox(
                      height: 100,
                      child: Text("カード内容"),
                    ),
                  ),
                ),
              ),
            );
          },
          
          // 複雑な内容のカード
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: AppCard(
                    title: "複雑なカード",
                    child: Column(
                      children: List<Widget>.generate(10, (int index) => 
                        ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text("アイテム $index"),
                          subtitle: Text("詳細情報 $index"),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ],
        expectedMaxRenderTimeMs: PerformanceTestHelper.uiRenderCriticalThreshold,
      );

      expect(result.passed, isTrue,
          reason: "UI描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    // =================================================================
    // 大量データ表示パフォーマンステスト
    // =================================================================

    testWidgets("DataTableの大量データ描画パフォーマンス", (WidgetTester tester) async {
      // 大量データの準備
      final List<DataRow> largeDataSet = List<DataRow>.generate(100, (int index) => 
        DataRow(cells: <DataCell>[
          DataCell(Text("ID: $index")),
          DataCell(Text("名前: アイテム$index")),
          DataCell(Text("価格: ${(index * 100).toString()}円")),
          DataCell(Text("在庫: ${(index % 50).toString()}")),
        ])
      );

      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "data_table_large_dataset",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 大量データテーブル描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("名前")),
                        DataColumn(label: Text("価格")),
                        DataColumn(label: Text("在庫")),
                      ],
                      rows: largeDataSet,
                    ),
                  ),
                ),
              ),
            );
          },
          
          // スクロール操作
          (WidgetTester tester) async {
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, -500),
            );
          },
          
          // 高速スクロール
          (WidgetTester tester) async {
            await tester.fling(
              find.byType(SingleChildScrollView),
              const Offset(0, -1000),
              1000,
            );
          },
        ],
        expectedMaxRenderTimeMs: 100, // 大量データのため100ms許容
      );

      expect(result.passed, isTrue,
          reason: "大量データ描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    // =================================================================
    // リスト表示パフォーマンステスト
    // =================================================================

    testWidgets("大量リストアイテム描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "large_list_rendering",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 大量リスト描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ListView.builder(
                    itemCount: 500,
                    itemBuilder: (BuildContext context, int index) => ListTile(
                      leading: CircleAvatar(child: Text("$index")),
                      title: Text("アイテム $index"),
                      subtitle: Text("サブタイトル $index\n詳細情報がここに表示されます"),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          
          // リストスクロール
          (WidgetTester tester) async {
            await tester.drag(
              find.byType(ListView),
              const Offset(0, -1000),
            );
          },
          
          // 高速スクロール
          (WidgetTester tester) async {
            await tester.fling(
              find.byType(ListView),
              const Offset(0, -2000),
              2000,
            );
          },
        ],
        expectedMaxRenderTimeMs: 150, // 大量リストのため150ms許容
      );

      expect(result.passed, isTrue,
          reason: "大量リスト描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    // =================================================================
    // プロバイダー統合UI パフォーマンステスト
    // =================================================================

    testWidgets("Riverpodプロバイダー統合UI描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "riverpod_integrated_ui_rendering",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // プロバイダー使用UI描画
          (WidgetTester tester) async {
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  home: Scaffold(
                    body: Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) => Column(
                          children: <Widget>[
                            AppButton(
                              text: "プロバイダーボタン",
                              onPressed: () {
                                // プロバイダー状態更新をシミュレート
                              },
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              labelText: "プロバイダーフィールド",
                              onChanged: (String value) {
                                // プロバイダー状態更新をシミュレート
                              },
                            ),
                            const SizedBox(height: 20),
                            AppCard(
                              title: "プロバイダーカード",
                              child: SizedBox(
                                height: 100,
                                child: Text("プロバイダー統合コンテンツ"),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                ),
              ),
            );
          },
          
          // ボタンタップ（状態変更）
          (WidgetTester tester) async {
            await tester.tap(find.byType(AppButton));
          },
          
          // テキスト入力（状態変更）
          (WidgetTester tester) async {
            await tester.enterText(
              find.byType(TextField),
              "プロバイダー統合テスト"
            );
          },
        ],
        expectedMaxRenderTimeMs: PerformanceTestHelper.uiRenderCriticalThreshold,
      );

      expect(result.passed, isTrue,
          reason: "Riverpod統合UI描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    // =================================================================
    // アニメーションパフォーマンステスト
    // =================================================================

    testWidgets("アニメーション描画パフォーマンス", (WidgetTester tester) async {
      final UIPerformanceTestResult result = await PerformanceTestHelper.testUIPerformance(
        "animation_rendering_performance",
        () => tester,
        <Future<void> Function(WidgetTester p1)>[
          // 基本アニメーション
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (BuildContext context, double value, Widget? child) => Transform.scale(
                        scale: value,
                        child: Container(
                          width: 200,
                          height: 200,
                          color: Colors.blue,
                          child: Center(
                            child: const Text("アニメーション"),
                          ),
                        ),
                      ),
                  ),
                ),
              ),
            );
          },
          
          // アニメーション進行
          (WidgetTester tester) async {
            await tester.pump(const Duration(milliseconds: 250));
          },
          
          // アニメーション完了
          (WidgetTester tester) async {
            await tester.pump(const Duration(milliseconds: 250));
          },
        ],
        expectedMaxRenderTimeMs: PerformanceTestHelper.uiRenderCriticalThreshold,
      );

      expect(result.passed, isTrue,
          reason: "アニメーション描画パフォーマンス基準未達: 最大描画時間 ${result.maxRenderTimeMs}ms");
    });

    // =================================================================
    // テスト完了後の処理
    // =================================================================

    tearDownAll(() async {
      debugPrint("🎨 UI描画パフォーマンステスト完了");
      debugPrint("📊 描画時間基準:");
      debugPrint("  - 警告閾値: ${PerformanceTestHelper.uiRenderWarningThreshold}ms (60FPS基準)");
      debugPrint("  - 危険閾値: ${PerformanceTestHelper.uiRenderCriticalThreshold}ms (30FPS基準)");
      debugPrint("📈 詳細結果: performance_results.json");
    });
  });
}