import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yata/features/auth/models/auth_state.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/inventory/presentation/providers/inventory_providers.dart";
import "package:yata/features/inventory/services/inventory_service.dart";
import "package:yata/features/menu/presentation/providers/menu_providers.dart";
import "package:yata/features/menu/services/menu_service.dart";
import "package:yata/features/order/presentation/providers/order_providers.dart";
import "package:yata/features/order/services/order_service.dart";
import "package:yata/shared/providers/development_providers.dart";

import "../helpers/performance_baseline.dart";
import "../helpers/performance_test_helper.dart";

/// プロバイダーのパフォーマンステスト
/// 
/// Riverpodプロバイダーの初期化、状態変更、
/// メモリリークの検証を行う
void main() {
  group("Provider Performance Tests", () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =================================================================
    // プロバイダー初期化パフォーマンステスト
    // =================================================================

    test("認証プロバイダー初期化パフォーマンス", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "auth_provider_initialization",
        () async {
          // 認証プロバイダーの初期化
          final AuthState authState = container.read(authStateNotifierProvider);
          
          // 初期化処理を待機
          final Future<void> delay1 = Future.delayed(const Duration(milliseconds: 10));
          await delay1;
          
          // 状態確認
          expect(authState, isNotNull);
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
        memoryThreshold: 1.0, // 1MB以内
      );

      // ベースラインとの比較
      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "auth_provider_initialization",
        result,
      );

      // 回帰がある場合はテスト失敗
      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      // ベースライン更新（テスト成功時のみ）
      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("auth_provider_initialization", result);
      }
    });

    test("在庫管理プロバイダー初期化パフォーマンス", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "inventory_provider_initialization",
        () async {
          // 在庫管理プロバイダーの初期化
          final InventoryService inventoryService = container.read(inventoryServiceProvider);
          
          // 初期化処理を待機
          final Future<void> delay2 = Future.delayed(const Duration(milliseconds: 10));
          await delay2;
          
          // 状態確認
          expect(inventoryService, isNotNull);
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
        memoryThreshold: 2.0, // 2MB以内
      );

      // ベースラインとの比較
      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "inventory_provider_initialization",
        result,
      );

      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("inventory_provider_initialization", result);
      }
    });

    test("注文管理プロバイダー初期化パフォーマンス", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "order_provider_initialization",
        () async {
          // 注文管理プロバイダーの初期化
          final OrderService orderService = container.read(orderServiceProvider);
          
          // 初期化処理を待機
          final Future<void> delay11 = Future.delayed(const Duration(milliseconds: 10));
          await delay11;
          
          // 状態確認
          expect(orderService, isNotNull);
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
        memoryThreshold: 1.5, // 1.5MB以内
      );

      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "order_provider_initialization",
        result,
      );

      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("order_provider_initialization", result);
      }
    });

    test("メニュー管理プロバイダー初期化パフォーマンス", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "menu_provider_initialization",
        () async {
          // メニュー管理プロバイダーの初期化
          final MenuService menuService = container.read(menuServiceProvider);
          
          // 初期化処理を待機
          final Future<void> delay12 = Future.delayed(const Duration(milliseconds: 10));
          await delay12;
          
          // 状態確認
          expect(menuService, isNotNull);
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
        memoryThreshold: 1.0, // 1MB以内
      );

      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "menu_provider_initialization",
        result,
      );

      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("menu_provider_initialization", result);
      }
    });

    test("パフォーマンス監視プロバイダー初期化", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "performance_monitor_initialization",
        () async {
          // パフォーマンス監視プロバイダーの初期化
          final PerformanceMetrics performanceState = container.read(performanceMonitorProvider);
          
          // 初期化処理を待機
          final Future<void> delay5 = Future.delayed(const Duration(milliseconds: 50));
          await delay5;
          
          // 状態確認
          expect(performanceState, isNotNull);
          expect(performanceState.lastUpdated, isNull); // 初期状態
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitWarningThreshold,
        memoryThreshold: 0.5, // 0.5MB以内
      );

      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "performance_monitor_initialization",
        result,
      );

      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("performance_monitor_initialization", result);
      }
    });

    // =================================================================
    // プロバイダーメモリリークテスト
    // =================================================================

    test("認証プロバイダーメモリリークテスト", () async {
      final MemoryLeakTestResult result = await PerformanceTestHelper.testMemoryLeak(
        "auth_provider_memory_leak",
        () async {
          // プロバイダーコンテナ作成
          final ProviderContainer testContainer = ProviderContainer();
          
          // 認証プロバイダー使用
          final AuthState authState = testContainer.read(authStateNotifierProvider);
          expect(authState, isNotNull);
          
          // 重い処理をシミュレート
          final Future<void> delay6 = Future.delayed(const Duration(milliseconds: 10));
          await delay6;
          
          // コンテナ破棄
          testContainer.dispose();
        },
        () async {
          // クリーンアップ処理
          final Future<void> delay7 = Future.delayed(const Duration(milliseconds: 10));
          await delay7;
        },
        iterations: 20,
        maxMemoryLeakMB: 2.0, // 2MB以内のリーク許容
      );

      expect(result.passed, isTrue,
          reason: "メモリリーク検出: ${result.memoryLeakMB.toStringAsFixed(2)}MB");
    });

    test("在庫管理プロバイダーメモリリークテスト", () async {
      final MemoryLeakTestResult result = await PerformanceTestHelper.testMemoryLeak(
        "inventory_provider_memory_leak",
        () async {
          final ProviderContainer testContainer = ProviderContainer();
          
          // 在庫管理プロバイダー使用
          final InventoryService inventoryService = testContainer.read(inventoryServiceProvider);
          expect(inventoryService, isNotNull);
          
          final Future<void> delay8 = Future.delayed(const Duration(milliseconds: 10));
          await delay8;
          testContainer.dispose();
        },
        () async {
          final Future<void> delay9 = Future.delayed(const Duration(milliseconds: 10));
          await delay9;
        },
        iterations: 15,
        maxMemoryLeakMB: 3.0, // より多くのデータを扱うため3MB許容
      );

      expect(result.passed, isTrue,
          reason: "メモリリーク検出: ${result.memoryLeakMB.toStringAsFixed(2)}MB");
    });

    // =================================================================
    // 複数プロバイダー同時初期化テスト
    // =================================================================

    test("複数プロバイダー同時初期化パフォーマンス", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "multiple_providers_initialization",
        () async {
          // 複数のプロバイダーを同時に初期化
          final List<Future<void>> futures = <Future<void>>[
            Future(() async {
              final AuthState authState = container.read(authStateNotifierProvider);
              expect(authState, isNotNull);
            }),
            Future(() async {
              final InventoryService inventoryService = container.read(inventoryServiceProvider);
              expect(inventoryService, isNotNull);
            }),
            Future(() async {
              final OrderService orderService = container.read(orderServiceProvider);
              expect(orderService, isNotNull);
            }),
            Future(() async {
              final MenuService menuService = container.read(menuServiceProvider);
              expect(menuService, isNotNull);
            }),
          ];
          
          // 全てのプロバイダー初期化を待機
          await Future.wait(futures);
          
          // 追加の安定化時間
          final Future<void> delay10 = Future.delayed(const Duration(milliseconds: 50));
          await delay10;
        },
        expectedMaxDuration: PerformanceTestHelper.providerInitCriticalThreshold,
        memoryThreshold: 5.0, // 複数プロバイダーのため5MB許容
      );

      final RegressionDetectionResult regressionResult = await PerformanceBaseline.detectRegression(
        "multiple_providers_initialization",
        result,
      );

      expect(regressionResult.hasRegression, isFalse,
          reason: "パフォーマンス回帰検出: ${regressionResult.reason}");

      if (result.success && !regressionResult.hasRegression) {
        await PerformanceBaseline.updateBaseline("multiple_providers_initialization", result);
      }
    });

    // =================================================================
    // テスト完了後の処理
    // =================================================================

    tearDownAll(() async {
      // 全テスト結果をまとめて保存
      // 注意: この実装では個別の結果を保存していないため、
      // 実際の運用では結果リストを管理する必要がある
      
      print("🎯 プロバイダーパフォーマンステスト完了");
      print("📊 ベースラインファイル: performance_baseline.json");
      print("📈 詳細結果: performance_results.json");
    });
  });
}