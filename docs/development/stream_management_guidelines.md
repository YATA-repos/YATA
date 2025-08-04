# Stream管理ガイドライン

## 概要

このガイドラインは、YATAプロジェクトでのStream（ストリーム）の適切な使用方法とメモリリーク防止のベストプラクティスを提供します。

## 目次

1. [Stream Manager Mixinの使用](#stream-manager-mixinの使用)
2. [メモリリーク防止](#メモリリーク防止)
3. [Riverpodでのストリーム管理](#riverpodでのストリーム管理)
4. [パフォーマンス監視](#パフォーマンス監視)
5. [トラブルシューティング](#トラブルシューティング)

---

## Stream Manager Mixinの使用

### 基本的な使用方法

YATAプロジェクトでは、`StreamSubscription`と`StreamController`の安全な管理のために、専用のMixinを提供しています。

#### StreamManagerMixin

`StreamSubscription`を管理する場合：

```dart
import "package:yata/core/utils/stream_manager_mixin.dart";

class MyService with StreamManagerMixin {
  void startListening() {
    final StreamSubscription<int> subscription = someStream.listen((int data) {
      // データ処理
    });
    
    // 管理対象に追加（デバッグ情報付き）
    addSubscription(
      subscription,
      debugName: "my_data_stream",
      source: "MyService",
    );
  }
  
  void dispose() {
    // 全てのSubscriptionを安全に破棄
    disposeStreams();
  }
}
```

#### StreamControllerManagerMixin

`StreamController`を管理する場合：

```dart
class MyService with StreamControllerManagerMixin {
  late final StreamController<String> _controller;
  
  MyService() {
    _controller = StreamController<String>.broadcast();
    
    // 管理対象に追加
    addController(
      _controller,
      debugName: "my_event_controller",
      source: "MyService",
    );
  }
  
  void dispose() {
    // 全てのControllerを安全に破棄
    disposeControllers();
  }
}
```

#### ResourceManagerMixin

両方を使用する場合：

```dart
class MyComplexService with ResourceManagerMixin {
  void initialize() {
    // StreamController作成
    final StreamController<Event> eventController = StreamController<Event>();
    addController(eventController, debugName: "events", source: "MyComplexService");
    
    // StreamSubscription作成
    final StreamSubscription<Data> dataSubscription = dataStream.listen(handleData);
    addSubscription(dataSubscription, debugName: "data", source: "MyComplexService");
  }
  
  void dispose() {
    // 全リソースを統合破棄
    disposeAll();
  }
}
```

---

## メモリリーク防止

### 重要な原則

1. **必ずdisposeを呼ぶ**: すべてのStreamリソースは適切に破棄する
2. **ライフサイクル管理**: オブジェクトの寿命に合わせてリソース管理を行う
3. **監視機能の活用**: メモリリーク検出機能を使用する

### メモリリーク検出機能

Stream Manager Mixinには自動的なメモリリーク検出機能が組み込まれています：

```dart
class MyService with ResourceManagerMixin {
  void checkMemoryHealth() {
    // メモリリーク警告チェック
    if (hasAnyMemoryLeak) {
      final List<String> warnings = allMemoryLeakWarnings;
      for (final String warning in warnings) {
        print("🚨 メモリリーク警告: $warning");
      }
    }
    
    // デバッグ情報を取得
    final Map<String, dynamic> debugInfo = getAllResourceDebugInfo();
    print("リソース状況: ${debugInfo['total_resources']}個のアクティブリソース");
  }
}
```

### 警告閾値

- **StreamSubscription**: 10個以上でWarning、20個以上でCritical
- **StreamController**: 5個以上でWarning、10個以上でCritical
- **長時間実行**: 5分以上アクティブなリソースで警告

---

## Riverpodでのストリーム管理

### 安全なStreamプロバイダーの実装

RiverpodでStreamプロバイダーを実装する際は、適切なキャンセレーション処理を実装してください：

```dart
@riverpod
Stream<List<Data>> myDataStream(Ref ref, String userId) async* {
  // キャンセレーション用のCompleter
  final Completer<void> cancelCompleter = Completer<void>();
  
  // ref.onDispose でキャンセレーションを設定
  ref.onDispose(() {
    if (!cancelCompleter.isCompleted) {
      cancelCompleter.complete();
    }
  });

  // 適切なキャンセレーション対応ループ
  while (!cancelCompleter.isCompleted) {
    try {
      // キャンセレーションかタイムアウトのいずれかを待機
      await Future.any(<Future<void>>[
        Future<void>.delayed(const Duration(seconds: 10)),
        cancelCompleter.future,
      ]);

      // キャンセルされた場合はループを終了
      if (cancelCompleter.isCompleted) {
        break;
      }

      // データ取得・配信
      final List<Data> data = await fetchData(userId);
      yield data;
    } catch (e) {
      // エラーハンドリング
      if (e is StateError && cancelCompleter.isCompleted) {
        break; // 正常なキャンセル
      }
      yield <Data>[]; // エラー時は空リスト
    }
  }
  
  // クリーンアップ処理
  await cleanup();
}
```

### 危険なパターン（避けるべき）

```dart
// ❌ 危険: 永続的な無限ループ
@riverpod
Stream<Data> badStream(Ref ref) async* {
  while (true) { // キャンセレーション機能なし
    await Future.delayed(const Duration(seconds: 5));
    yield await fetchData();
  }
}

// ❌ 危険: リソースリークリスク
class BadService {
  final StreamController<Data> _controller = StreamController<Data>();
  
  // disposeメソッドなし = メモリリーク
}
```

---

## パフォーマンス監視

### テストでの監視

```dart
test("Streamパフォーマンス監視", () async {
  final MyService service = MyService();
  
  // パフォーマンス測定
  final PerformanceTestResult result = await PerformanceTestHelper.measurePerformance(
    "stream_operation",
    () async {
      await service.performStreamOperations();
    },
    expectedMaxDuration: 1000, // 1秒以内
    memoryThreshold: 5.0, // 5MB以内
  );
  
  expect(result.success, true);
  
  // メモリリークテスト
  final MemoryLeakTestResult leakResult = await PerformanceTestHelper.testMemoryLeak(
    "service_memory_leak",
    () async {
      final MyService testService = MyService();
      await testService.initialize();
      testService.dispose();
    },
    () async {
      // クリーンアップ
    },
    maxMemoryLeakMB: 1.0,
  );
  
  expect(leakResult.passed, true);
});
```

### 本番環境での監視

```dart
class ProductionService with ResourceManagerMixin {
  Timer? _healthCheckTimer;
  
  void startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (hasAnyMemoryLeak) {
        // ログシステムに警告出力
        YataLogger.warning(
          "Production",
          "メモリリーク検出",
          details: getAllResourceDebugInfo(),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.disposeAll();
  }
}
```

---

## トラブルシューティング

### よくある問題と解決方法

#### 1. "Critical: XX個のアクティブなSubscriptionが検出されました"

**原因**: StreamSubscriptionが適切に破棄されていない

**解決方法**:
```dart
// addSubscriptionで追加したリソースを確実に破棄
@override
void dispose() {
  disposeStreams(); // または disposeAll()
  super.dispose();
}
```

#### 2. "Warning: XX個の長時間実行中のStreamControllerが検出されました"

**原因**: StreamControllerが長時間開いたまま

**解決方法**:
```dart
// 適切なライフサイクル管理
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with StreamControllerManagerMixin {
  @override
  void dispose() {
    disposeControllers(); // Widget破棄時にController破棄
    super.dispose();
  }
}
```

#### 3. Riverpodストリームが停止しない

**原因**: `ref.onDispose`でのクリーンアップ不足

**解決方法**:
```dart
@riverpod
Stream<Data> myStream(Ref ref) async* {
  final Completer<void> cancelCompleter = Completer<void>();
  
  ref.onDispose(() {
    if (!cancelCompleter.isCompleted) {
      cancelCompleter.complete();
    }
  });
  
  // 適切なキャンセレーション処理実装
}
```

### デバッグ支援

Stream Manager Mixinのデバッグ情報を活用：

```dart
void debugStreamHealth() {
  final Map<String, dynamic> debugInfo = getAllResourceDebugInfo();
  
  print("=== Stream健全性レポート ===");
  print("総リソース数: ${debugInfo['total_resources']}");
  print("アクティブSubscription: ${debugInfo['streams']['active_subscriptions']}");
  print("アクティブController: ${debugInfo['controllers']['active_controllers']}");
  print("メモリリーク: ${debugInfo['has_any_leak']}");
  
  if (debugInfo['all_warnings'].isNotEmpty) {
    print("警告:");
    for (final String warning in debugInfo['all_warnings']) {
      print("  - $warning");
    }
  }
}
```

---

## ベストプラクティス サマリー

### ✅ 推奨事項

1. **常にMixinを使用**: `StreamManagerMixin`、`StreamControllerManagerMixin`、`ResourceManagerMixin`を活用
2. **デバッグ情報を付与**: `addSubscription`、`addController`でdebugNameとsourceを指定
3. **適切なdispose**: オブジェクトのライフサイクル終了時に必ず呼び出し
4. **Riverpodでのキャンセレーション**: `ref.onDispose`と`Completer`を使用した安全な実装
5. **定期的な健全性チェック**: メモリリーク検出機能を活用した監視

### ❌ 避けるべき事項

1. **手動でのStream管理**: 直接的なcancel()やclose()呼び出し
2. **無限ループ**: キャンセレーション機能のないwhile(true)
3. **disposeの忘れ**: リソースの破棄漏れ
4. **複数のMixin使用**: 単一クラスで複数のStream管理Mixinを使用
5. **警告の無視**: メモリリーク警告を放置

---

## 参考資料

- [core/utils/stream_manager_mixin.dart](../../lib/core/utils/stream_manager_mixin.dart) - Mixin実装
- [test/performance/benchmarks/stream_memory_leak_test.dart](../../test/performance/benchmarks/stream_memory_leak_test.dart) - テスト例
- [Dart StreamSubscription](https://api.dart.dev/stable/dart-async/StreamSubscription-class.html)
- [Dart StreamController](https://api.dart.dev/stable/dart-async/StreamController-class.html)
- [Riverpod StreamProvider](https://riverpod.dev/docs/providers/stream_provider)