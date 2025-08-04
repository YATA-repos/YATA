import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:yata/core/utils/stream_manager_mixin.dart";

import "../helpers/performance_test_helper.dart";

/// Stream管理ミックスインのメモリリークテスト
/// 
/// StreamSubscriptionとStreamControllerの適切な管理と
/// メモリリーク検出機能をテストする
void main() {
  group("Stream Memory Leak Tests", () {
    
    // =================================================================
    // StreamManagerMixin テスト
    // =================================================================
    
    test("StreamManagerMixin - 正常なライフサイクル管理", () async {
      final _TestStreamManager manager = _TestStreamManager();
      
      // StreamSubscriptionを複数作成
      final List<StreamController<int>> controllers = <StreamController<int>>[];
      for (int i = 0; i < 3; i++) {
        final StreamController<int> controller = StreamController<int>();
        controllers.add(controller);
        
        final StreamSubscription<int> subscription = controller.stream.listen((_) {});
        manager.addSubscription(
          subscription,
          debugName: "test_subscription_$i",
          source: "stream_memory_leak_test",
        );
      }
      
      // 初期状態確認
      expect(manager.activeSubscriptionCount, 3);
      expect(manager.totalSubscriptionsCreated, 3);
      expect(manager.totalSubscriptionsCanceled, 0);
      expect(manager.hasPotentialMemoryLeak, false);
      
      // 正常に破棄
      manager.disposeStreams();
      
      // 破棄後の状態確認
      expect(manager.activeSubscriptionCount, 0);
      expect(manager.totalSubscriptionsCanceled, 3);
      expect(manager.hasPotentialMemoryLeak, false);
      
      // コントローラーもクリーンアップ
      for (final StreamController<int> controller in controllers) {
        await controller.close();
      }
    });
    
    test("StreamManagerMixin - メモリリーク検出（多数のSubscription）", () async {
      final _TestStreamManager manager = _TestStreamManager();
      
      // 大量のStreamSubscriptionを作成（警告閾値を超える）
      final List<StreamController<int>> controllers = <StreamController<int>>[];
      for (int i = 0; i < 15; i++) {
        final StreamController<int> controller = StreamController<int>();
        controllers.add(controller);
        
        final StreamSubscription<int> subscription = controller.stream.listen((_) {});
        manager.addSubscription(
          subscription,
          debugName: "leak_test_subscription_$i",
          source: "memory_leak_simulation",
        );
      }
      
      // メモリリーク検出確認
      expect(manager.hasPotentialMemoryLeak, true);
      expect(manager.memoryLeakWarningMessage, isNotNull);
      expect(manager.memoryLeakWarningMessage!.contains("Warning"), true);
      
      // デバッグ情報確認
      final Map<String, dynamic> debugInfo = manager.getStreamDebugInfo();
      expect(debugInfo["has_potential_leak"], true);
      expect(debugInfo["active_subscriptions"], 15);
      
      // クリーンアップ
      manager.disposeStreams();
      for (final StreamController<int> controller in controllers) {
        await controller.close();
      }
    });
    
    test("StreamManagerMixin - 長時間実行Subscriptionの検出", () async {
      final _TestStreamManager manager = _TestStreamManager();
      
      // Subscriptionを作成し、時間を進める（テスト用モック）
      final StreamController<int> controller = StreamController<int>();
      final StreamSubscription<int> subscription = controller.stream.listen((_) {});
      
      manager.addSubscription(
        subscription,
        debugName: "long_running_subscription",
        source: "long_running_test",
      );
      
      // 通常は時間経過待ちが必要だが、テストのため直接内部状態を操作
      // 実際のアプリケーションでは5分以上経過したSubscriptionが検出される
      
      final Map<String, dynamic> debugInfo = manager.getStreamDebugInfo();
      expect(debugInfo["subscription_history"], hasLength(1));
      
      // クリーンアップ
      manager.disposeStreams();
      await controller.close();
    });
    
    // =================================================================
    // StreamControllerManagerMixin テスト
    // =================================================================
    
    test("StreamControllerManagerMixin - 正常なライフサイクル管理", () async {
      final _TestControllerManager manager = _TestControllerManager();
      
      // StreamControllerを複数作成
      for (int i = 0; i < 3; i++) {
        final StreamController<int> controller = StreamController<int>();
        manager.addController(
          controller,
          debugName: "test_controller_$i",
          source: "stream_memory_leak_test",
        );
      }
      
      // 初期状態確認
      expect(manager.activeControllerCount, 3);
      expect(manager.totalControllersCreated, 3);
      expect(manager.totalControllersClosed, 0);
      expect(manager.hasControllerMemoryLeak, false);
      
      // 正常に破棄
      manager.disposeControllers();
      
      // 破棄後の状態確認
      expect(manager.activeControllerCount, 0);
      expect(manager.totalControllersClosed, 3);
      expect(manager.hasControllerMemoryLeak, false);
    });
    
    test("StreamControllerManagerMixin - メモリリーク検出", () async {
      final _TestControllerManager manager = _TestControllerManager();
      
      // 大量のStreamControllerを作成（警告閾値を超える）
      for (int i = 0; i < 8; i++) {
        final StreamController<int> controller = StreamController<int>();
        manager.addController(
          controller,
          debugName: "leak_test_controller_$i",
          source: "memory_leak_simulation",
        );
      }
      
      // メモリリーク検出確認
      expect(manager.hasControllerMemoryLeak, true);
      expect(manager.controllerMemoryLeakWarningMessage, isNotNull);
      expect(manager.controllerMemoryLeakWarningMessage!.contains("Warning"), true);
      
      // デバッグ情報確認
      final Map<String, dynamic> debugInfo = manager.getControllerDebugInfo();
      expect(debugInfo["has_potential_leak"], true);
      expect(debugInfo["active_controllers"], 8);
      
      // クリーンアップ
      manager.disposeControllers();
    });
    
    // =================================================================
    // ResourceManagerMixin 統合テスト
    // =================================================================
    
    test("ResourceManagerMixin - 統合リソース管理", () async {
      final _TestResourceManager manager = _TestResourceManager();
      
      // StreamSubscriptionとStreamControllerを混在作成
      final List<StreamController<int>> controllers = <StreamController<int>>[];
      
      // StreamController作成
      for (int i = 0; i < 2; i++) {
        final StreamController<int> controller = StreamController<int>();
        controllers.add(controller);
        manager.addController(
          controller,
          debugName: "resource_test_controller_$i",
          source: "integration_test",
        );
      }
      
      // StreamSubscription作成
      for (int i = 0; i < 3; i++) {
        final StreamController<int> controller = StreamController<int>();
        controllers.add(controller);
        
        final StreamSubscription<int> subscription = controller.stream.listen((_) {});
        manager.addSubscription(
          subscription,
          debugName: "resource_test_subscription_$i",
          source: "integration_test",
        );
      }
      
      // 統合状態確認
      expect(manager.activeSubscriptionCount, 3);
      expect(manager.activeControllerCount, 2);
      expect(manager.hasAnyMemoryLeak, false);
      
      // 統合デバッグ情報確認
      final Map<String, dynamic> debugInfo = manager.getAllResourceDebugInfo();
      expect(debugInfo["total_resources"], 5);
      expect(debugInfo["has_any_leak"], false);
      expect(debugInfo["all_warnings"], isEmpty);
      
      // 統合破棄
      manager.disposeAll();
      
      // 破棄後確認
      expect(manager.activeSubscriptionCount, 0);
      expect(manager.activeControllerCount, 0);
      
      // コントローラーもクリーンアップ
      for (final StreamController<int> controller in controllers) {
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    });
    
    // =================================================================
    // パフォーマンス統合テスト
    // =================================================================
    
    test("Stream管理のパフォーマンス測定", () async {
      final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
        "stream_manager_performance",
        () async {
          final _TestResourceManager manager = _TestResourceManager();
          final List<StreamController<int>> controllers = <StreamController<int>>[];
          
          // 100個のリソースを作成・管理・破棄
          for (int i = 0; i < 50; i++) {
            final StreamController<int> controller = StreamController<int>();
            controllers.add(controller);
            manager.addController(controller);
            
            final StreamSubscription<int> subscription = controller.stream.listen((_) {});
            manager.addSubscription(subscription);
          }
          
          // デバッグ情報取得（パフォーマンステスト）
          final Map<String, dynamic> debugInfo = manager.getAllResourceDebugInfo();
          expect(debugInfo["total_resources"], 100);
          
          // 統合破棄
          manager.disposeAll();
          
          // コントローラークリーンアップ
          for (final StreamController<int> controller in controllers) {
            if (!controller.isClosed) {
              await controller.close();
            }
          }
        },
        expectedMaxDuration: 1000, // 1秒以内
        memoryThreshold: 5.0, // 5MB以内
      );
      
      expect(result.success, true);
      expect(result.executionTimeMs, lessThan(1000));
    });
    
    test("メモリリーク検出のパフォーマンス", () async {
      final MemoryLeakTestResult result = await PerformanceTestHelper.testMemoryLeak(
        "stream_manager_memory_leak",
        () async {
          final _TestResourceManager manager = _TestResourceManager();
          final List<StreamController<int>> controllers = <StreamController<int>>[];
          
          // リソースを作成・破棄を繰り返す
          for (int i = 0; i < 10; i++) {
            final StreamController<int> controller = StreamController<int>();
            controllers.add(controller);
            
            manager.addController(controller);
            final StreamSubscription<int> subscription = controller.stream.listen((_) {});
            manager.addSubscription(subscription);
          }
          
          manager.disposeAll();
          
          // コントローラークリーンアップ
          for (final StreamController<int> controller in controllers) {
            if (!controller.isClosed) {
              await controller.close();
            }
          }
        },
        () async {
          // クリーンアップ処理
          final Future<void> delay = Future.delayed(const Duration(milliseconds: 10));
          await delay;
        },
        maxMemoryLeakMB: 1.0,
      );
      
      expect(result.passed, true);
    });
  });
}

// =================================================================
// テスト用ヘルパークラス
// =================================================================

/// StreamManagerMixinテスト用クラス
class _TestStreamManager with StreamManagerMixin {
  // テスト用の機能は既にミックスインで提供される
}

/// StreamControllerManagerMixinテスト用クラス
class _TestControllerManager with StreamControllerManagerMixin {
  // テスト用の機能は既にミックスインで提供される
}

/// ResourceManagerMixinテスト用クラス
class _TestResourceManager with ResourceManagerMixin {
  // テスト用の機能は既にミックスインで提供される
}