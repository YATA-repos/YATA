# OMPerfログレベル準拠問題解決計画（2025-10-13）

**この問題は解決済み**

## 背景
- OMPerfログのみがアプリのログレベル設定に従っておらず、グローバルログレベルが`fatal`に設定されているにもかかわらず`debug`レベルのOMPerfログが出力されている。
- この問題により、運用環境でのログレベル制御がOMPerfに対して機能せず、不要なログが出力される可能性がある。

## 根本原因
`OrderManagementTracer._applyLoggerTagLevel()`メソッドが、OMPerfトレーシングが有効な場合に強制的に`"omperf"`タグのログレベルを`debug`に設定している。

```dart
static void _applyLoggerTagLevel(bool enabled) {
  if (enabled) {
    log.setTagLevel(_logTag, log_level.LogLevel.debug);  // ← 問題の箇所
  } else {
    log.clearTagLevel(_logTag);
  }
  _lastLoggerEnabled = enabled;
}
```

このため、グローバルログレベルが`fatal`でもOMPerfログは`debug`レベルで出力される。

## 問題点
- ログレベル設定の意図がOMPerfに対して無視される
- 運用環境でのログ制御が不完全になる
- トレーシング有効/無効とログレベルが混同される

## 解決策
OMPerfが有効な場合でも、ログレベルを強制的に設定せず、ロガーの通常のレベルチェックに任せる。

### 1. `_applyLoggerTagLevel`メソッドの削除
`OrderManagementTracer`からタグレベルの強制設定を削除し、OMPerfログをグローバルログレベルに従わせる。

### 2. トレーシング有効/無効の分離
- トレーシングの有効/無効：パフォーマンス計測の実行可否
- ログレベル：出力されるログのレベル制御

### 3. ログレベルの尊重
OMPerfログは`debug`レベルで出力されるため、グローバルログレベルが`debug`以上の場合のみ出力されるようになる。

## 実装変更
### `lib/features/order/presentation/performance/order_management_tracing.dart`
```dart
// 削除するメソッド
static void _applyLoggerTagLevel(bool enabled) {
  // このメソッド全体を削除
}

// _syncLoggerTagLevel も削除または変更
static void _syncLoggerTagLevel() {
  // 何もしない、またはトレーシング状態の追跡のみ
  _lastLoggerEnabled = _computeIsEnabled();
}
```

### `isEnabled`プロパティの変更
```dart
static bool get isEnabled {
  final bool enabled = _computeIsEnabled();
  // ログレベルの設定は行わない
  return enabled;
}
```

## 影響評価
### ポジティブ影響
- ログレベル設定がOMPerfに対して正しく機能する
- 運用環境でのログ制御が統一される
- 不要なログ出力が抑制される

### ネガティブ影響
- OMPerfトレーシングが有効でも、ログレベルが`info`以上の場合、OMPerfログが出力されなくなる
- パフォーマンス分析時にログレベルを`debug`に変更する必要が生じる

### 緩和策
- ドキュメントに「OMPerfログを確認するにはログレベルを`debug`に設定してください」と明記
- 設定UIにOMPerfログレベルの注記を追加

## テスト
- グローバルログレベルが`fatal`の場合、OMPerfログが出力されないことを確認
- グローバルログレベルが`debug`の場合、OMPerfログが出力されることを確認
- トレーシング有効/無効がログ出力に影響しないことを確認

## 関連ドキュメント
- `docs/plan/order/2025-10-10-order-management-performance-logging-plan.md`
- `docs/survey/order_survey/2025-10-10-omperf-log-sink-status.md`