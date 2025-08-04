# YATA パフォーマンス回帰テストシステム

## 概要

YATAプロジェクトのパフォーマンス品質を継続的に監視し、性能劣化を早期検出するための包括的なテストシステムです。

## 🎯 主な機能

- **📊 パフォーマンス計測**: メモリ使用量、実行時間、UI描画性能の自動測定
- **🚨 回帰検出**: ベースラインとの比較による性能劣化の自動検出
- **📈 継続的監視**: CI/CD統合による自動実行とアラート
- **📋 詳細レポート**: JSON、JUnit形式での結果出力
- **🎨 監視ダッシュボード**: UI経由でのリアルタイム監視

## 📁 ディレクトリ構造

```
test/performance/
├── README.md                          # このファイル
├── run_performance_tests.dart          # メインテスト実行スクリプト
├── helpers/                           # テストヘルパー
│   ├── performance_test_helper.dart    # 基本パフォーマンステストヘルパー
│   └── performance_baseline.dart      # ベースライン管理
├── benchmarks/                        # 個別ベンチマークテスト
│   ├── provider_performance_test.dart  # プロバイダーパフォーマンステスト
│   └── ui_performance_test.dart        # UI描画パフォーマンステスト
└── integration/                       # 統合パフォーマンステスト
    └── (今後拡張予定)
```

## 🚀 使用方法

### 基本的な実行

```bash
# 完全なパフォーマンス回帰テスト実行
make performance-test

# 高速テスト（基本チェックのみ）
make performance-test-quick

# ベースライン更新（慎重に実行）
make performance-baseline-update
```

### 直接実行

```bash
# メインテストランナー実行
dart test/performance/run_performance_tests.dart

# オプション付き実行
dart test/performance/run_performance_tests.dart \
  --regression-threshold=25.0 \
  --no-update-baseline

# 個別テストファイル実行
flutter test test/performance/benchmarks/provider_performance_test.dart
```

### コマンドラインオプション

- `--regression-threshold=<数値>`: 回帰検出の閾値（％）
- `--no-update-baseline`: ベースライン更新を無効化
- `--no-junit`: JUnitレポート生成を無効化
- `--no-detailed-report`: 詳細JSONレポート生成を無効化

## 📊 パフォーマンス指標と閾値

### 基本閾値

| 項目 | 警告閾値 | 危険閾値 | 説明 |
|------|----------|----------|------|
| メモリ使用量 | 50MB | 100MB | プロセス全体のメモリ使用量 |
| 応答時間 | 1000ms | 3000ms | API・処理レスポンス時間 |
| UI描画時間 | 16ms | 33ms | 60FPS/30FPS基準 |
| プロバイダー初期化 | 500ms | 1500ms | Riverpodプロバイダー初期化時間 |

### 回帰検出

- **デフォルト閾値**: 20%の性能劣化でアラート
- **ベースライン比較**: 過去の実行結果との自動比較
- **複合判定**: 実行時間とメモリ使用量の両方を考慮

## 🎨 UI監視ダッシュボード

アプリ内の分析画面で、パフォーマンス監視カードを使用してリアルタイム監視が可能です。

```dart
// 分析画面への統合例
PerformanceMonitoringCard()
```

### ダッシュボード機能

- ✅ **リアルタイム結果表示**: 最新のテスト結果を表示
- 🚀 **ワンクリック実行**: UI経由でのテスト実行
- 📊 **ベースライン管理**: 安全な確認プロセス付きベースライン更新
- 🚨 **回帰アラート**: 視覚的な警告表示

## 🔄 CI/CD統合

### GitHub Actions

自動実行がセットアップされています：

- **プッシュ時**: `main`、`dev`ブランチへのプッシュで自動実行
- **プルリクエスト**: パフォーマンス影響の事前チェック
- **定期実行**: 毎日午前2時（JST）に自動実行
- **ベースライン更新**: `main`ブランチでのテスト成功時に自動更新

### 設定ファイル

```yaml
# .github/workflows/performance_tests.yml
name: Performance Regression Tests
on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]
  schedule:
    - cron: '0 17 * * *'  # 毎日実行
```

## 📈 レポート形式

### 1. JUnitレポート（CI/CD統合用）

```xml
<!-- performance_test_results.xml -->
<testsuite name="PerformanceTests" tests="10" failures="0" time="2.345">
  <testcase name="auth_provider_initialization" time="0.050"/>
  <!-- ... -->
</testsuite>
```

### 2. 詳細JSONレポート

```json
{
  "totalTests": 10,
  "passedTests": 10,
  "failedTests": 0,
  "regressionCount": 0,
  "executionTimeMs": 2345,
  "success": true,
  "results": [...],
  "regressions": [],
  "timestamp": "2025-08-03T12:00:00.000Z"
}
```

### 3. ベースラインファイル

```json
{
  "auth_provider_initialization": {
    "testName": "auth_provider_initialization",
    "executionTimeMs": 50,
    "memoryUsageMB": 1.0,
    "lastUpdated": "2025-08-03T12:00:00.000Z",
    "sampleCount": 15
  }
}
```

## 🔧 カスタマイズ

### 新しいテストの追加

1. **個別テストファイルの作成**:
```dart
// test/performance/benchmarks/my_feature_test.dart
testWidgets('My Feature Performance', (WidgetTester tester) async {
  final result = await PerformanceTestHelper.measurePerformance(
    'my_feature_test',
    () async {
      // テスト対象の処理
    },
    expectedMaxDuration: 1000,
    memoryThreshold: 5.0,
  );
  
  expect(result.success, isTrue);
});
```

2. **テストランナーへの統合**:
```dart
// run_performance_tests.dart内でテストスイートに追加
case 'my_feature_performance':
  await _runMyFeaturePerformanceTests();
  break;
```

### 閾値のカスタマイズ

```dart
// helpers/performance_test_helper.dart
class PerformanceTestHelper {
  // 閾値を調整
  static const double memoryWarningThreshold = 75.0; // 変更例
  static const int responseTimeWarningThreshold = 800; // 変更例
}
```

## 🚨 トラブルシューティング

### よくある問題

#### 1. テスト実行失敗

```bash
# 依存関係の問題
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 権限の問題
chmod +x test/performance/run_performance_tests.dart
```

#### 2. メモリ測定の精度

```dart
// Web環境では制限あり
static int _getMemoryUsage() {
  if (kIsWeb) {
    return 0; // Web環境では簡易値
  }
  return ProcessInfo.currentRss; // ネイティブ環境
}
```

#### 3. CI/CD環境での実行

```yaml
# GitHub Actionsでの環境設定
- name: Flutter環境をセットアップ
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'
    channel: 'stable'
    cache: true
```

### パフォーマンスデータファイル

- `performance_baseline.json`: ベースライン値
- `performance_results.json`: 実行結果
- `performance_detailed_report.json`: 詳細レポート
- `performance_test_results.xml`: JUnitレポート

### クリーンアップ

```bash
# パフォーマンスデータの初期化
make clean-performance-data

# または手動削除
rm -f performance_*.json performance_*.xml
```

## 📚 技術詳細

### アーキテクチャ

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Test Runner       │────│  Performance Helper │────│   Baseline Manager  │
│                     │    │                     │    │                     │
│ - 実行制御          │    │ - 測定              │    │ - ベースライン管理  │
│ - 結果集約          │    │ - 閾値チェック      │    │ - 回帰検出          │
│ - レポート生成      │    │ - メモリリーク検出  │    │ - データ永続化      │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
            │                           │                           │
            ▼                           ▼                           ▼
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Individual Tests  │    │    UI Dashboard     │    │   CI/CD Integration │
│                     │    │                     │    │                     │
│ - Provider Tests    │    │ - リアルタイム監視  │    │ - 自動実行          │
│ - UI Tests          │    │ - 手動実行          │    │ - アラート          │
│ - Memory Leak Tests │    │ - 結果表示          │    │ - レポート配信      │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### 依存関係

- **既存ログシステム**: `ProviderLogger`との統合
- **パフォーマンス監視**: `PerformanceMonitor`プロバイダーとの連携
- **テストフレームワーク**: Flutter標準のテストインフラ
- **CI/CD**: GitHub Actions、Make統合

## 🎯 今後の拡張予定

- [ ] **より詳細なメトリクス**: CPU使用率、ネットワーク使用量
- [ ] **トレンド分析**: 時系列でのパフォーマンス推移
- [ ] **自動最適化提案**: パフォーマンス改善案の自動生成
- [ ] **比較分析**: ブランチ間、バージョン間の比較
- [ ] **カスタムメトリクス**: ビジネス固有の性能指標

---

**作成日**: 2025-08-03  
**バージョン**: 1.0.0  
**メンテナー**: YATA開発チーム