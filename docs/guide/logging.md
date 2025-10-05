# ロギングライブラリ 使用ガイド

このドキュメントでは、YATAプロジェクトのロギングライブラリ（`lib/infrastructure/logging/`）の使用方法について説明します。

## 目次

1. [概要](#概要)
2. [基本的な使い方](#基本的な使い方)
3. [ログレベル](#ログレベル)
4. [タグ機能](#タグ機能)
5. [フィールド機能](#フィールド機能)
6. [遅延評価](#遅延評価)
7. [コンテキスト機能](#コンテキスト機能)
8. [設定](#設定)
9. [PII（個人情報）マスキング](#pii個人情報マスキング)
10. [例外ログ](#例外ログ)
11. [高度な機能](#高度な機能)

## 概要

このロギングライブラリは以下の機能を提供します：

- **色付きコンソール出力**: 開発時の可読性向上
- **NDJSON ファイル出力**: 本番環境での調査性向上（NDJSON: Newline Delimited JSON - 各行が1つのJSONオブジェクト）
- **PII マスキング**: 個人情報（Personal Identifiable Information）の漏洩リスク最小化
- **非同期処理**: UI パフォーマンスの維持
- **遅延評価**: 不要な計算の回避
- **コンテキスト**: リクエスト追跡
- **レート制限**: ログ量の制御
- **クラッシュキャプチャ**: 未処理例外の自動収集

## 基本的な使い方

### インポート

```dart
import 'package:yata/infrastructure/logging/logging.dart';
```

### 基本的なログ出力

各ログレベルの詳細仕様は `reference/logging-api.md` のトップレベル関数を参照してください。

```dart
// レベル別の出力
t('トレース情報');        // trace
d('デバッグ情報');        // debug
i('一般的な情報');        // info
w('警告メッセージ');      // warn
e('エラーメッセージ');    // error
f('致命的エラー');        // fatal
```

## ログレベル

ログレベルの完全なAPI仕様は `reference/logging-api.md` の LogLevel 列挙型を参照してください。

ログレベルは以下の6段階があります（重要度順）：

1. `trace` - 詳細なトレース情報（最も詳細）
2. `debug` - デバッグ情報
3. `info` - 一般的な情報（デフォルト）
4. `warn` - 警告
5. `error` - エラー
6. `fatal` - 致命的エラー（最も重要）

### 動的レベル変更

```dart
// グローバルレベルの変更
setGlobalLevel(LogLevel.debug);

// タグ別レベルの設定
setTagLevel('api', LogLevel.warn);

// タグレベルのクリア
clearTagLevel('api');
```

## タグ機能

タグを使用してログを分類できます。

### 基本的なタグ使用

withTag関数の詳細仕様は `reference/logging-api.md` の設定関数セクションを参照してください。

```dart
// 直接指定
i('ユーザーログイン', tag: 'auth');
e('API呼び出し失敗', tag: 'api');

// タグ付きロガーの作成
final authLogger = withTag('auth');
authLogger.i('パスワード変更完了');
authLogger.w('無効なトークン');
```

### トレーシングユーティリティ (`context_utils.dart`)

`lib/infra/logging/context_utils.dart` には、`LogContext` を一貫して扱うためのヘルパーがまとまっています。代表的なキーは `LogContextKeys` に定義されており、以下のような標準化された snake_case キーを使用します。

- `flow_id`: ビジネスフロー全体を関連付ける ID。
- `span_id` / `parent_span_id`: サービス／UI層でのステップを表すスパン ID。
- `span_name`: スパンの論理名（例: `controller.checkout`）。
- `operation`: 構造化フィールドと揃えた業務アクション名。
- `request_id`, `user_id`, `source` など、追跡に必要な補助情報。

`traceAsync` / `traceSync` を使うと、これらの値を自動で付与しながらゾーンコンテキストを生成できます。Riverpod やサービス層での利用例は次の通りです。

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yata/infra/logging/context_utils.dart';
import 'package:yata/infra/logging/logging.dart';

final checkoutProvider = FutureProvider.autoDispose((ref) async {
  return traceAsync('order.checkout.ui', (trace) async {
    final fields = LogFieldsBuilder.operation('order.checkout')
      .withFlow(flowId: trace.flowId, requestId: trace.context[LogContextKeys.requestId] as String?)
      .withActor(userId: trace.context[LogContextKeys.userId] as String?);

    i('UI checkout started', tag: 'OrderManagementController', fields: fields.started().build());

    return ref.read(orderManagementServiceProvider).checkoutCart(/* ... */);
  }, attributes: <String, Object?>{
    LogContextKeys.source: 'OrderManagementController',
  });
});
```

サービス層では同じ `traceAsync` を呼び出すだけで、UI から渡された `flow_id` や `request_id` が自動的に引き継がれます。`LogFieldsBuilder.withFlow` を併用すると、構造化フィールドにも同じ ID が入り、Kibana/BigQuery などでの横断追跡が容易になります。

```dart
Future<OrderCheckoutResult> checkoutCart(/* ... */) {
  return traceAsync('order.checkout', (trace) async {
    final builder = LogFieldsBuilder.operation('order.checkout')
      .withFlow(flowId: trace.flowId, requestId: trace.context[LogContextKeys.requestId] as String?)
      .withActor(userId: userId);

    log.i('Started cart checkout process', tag: loggerComponent, fields: builder.started().build());
    // ... ビジネスロジック ...
  }, attributes: <String, Object?>{
    LogContextKeys.source: loggerComponent,
    LogContextKeys.userId: userId,
  });
}
```

UI トレーサ（`OrderManagementTracer.traceAsync` など）も内部で `traceAsync` を利用するようになり、Timeline Task とログ両方に同一の `flow_id` / `span_id` が表示されます。長時間処理（例: リアルタイム同期、夜間バッチ）では、最初の入口で `traceAsync` を呼び出し、必要に応じて `LogTrace.child(...)` でサブスパンを切っておくと、後段のログからも容易に辿れるようになります。

### 推奨タグ

プロジェクトでは以下のタグを推奨しています：

- `ui` - UI層のイベント
- `api` - API呼び出し関連
- `repo` - リポジトリ層
- `db` - データベース操作
- `auth` - 認証関連
- `logger` - ロガー内部メタ情報

## フィールド機能

構造化されたデータをログに追加できます。

```dart
// 基本的なフィールド
i('ユーザー作成', fields: {
  'userId': 'u_123',
  'email': 'user@example.com',
  'role': 'customer',
});

// ネストしたフィールド
d('リクエスト処理', fields: {
  'request': {
    'method': 'POST',
    'path': '/api/users',
    'duration': 150,
  },
  'response': {
    'status': 200,
    'size': 1024,
  },
});
```

### 標準フィールドビルダーの活用

主要イベントでは `LogFieldsBuilder` を使って標準フィールドを組み立てると、検索性とレビューの統一感が高まります。フィールド一覧は `docs/standards/logging-structured-fields.md` を参照してください。

```dart
final fields = LogFieldsBuilder.operation("order.checkout")
  .withActor(userId: userId)
  .withResource(type: "order", id: orderId)
  .started()
  .addMetadata({
    "cart_id": cartId,
    "item_count": cartItems.length,
  });

log.i("Started cart checkout", tag: loggerComponent, fields: fields);
```

`started() / succeeded() / failed()` といったメソッドで `stage` と `result.status` が自動的に整形されるため、クエリや可視化の軸として再利用しやすくなります。

## 遅延評価

パフォーマンスを向上させるため、重い処理は遅延評価を使用します。遅延評価により、ログレベルによってフィルタリングされるログの場合、不要な計算処理をスキップできます。

```dart
// メッセージの遅延評価
d(() => 'Heavy calculation result: ${expensiveCalculation()}');

// フィールドの遅延評価
i('処理完了', fields: () => {
  'result': buildComplexReport(),
  'metrics': collectMetrics(),
});

// ログレベルによるフィルタリングで、不要な処理をスキップ
// DEBUGレベルが無効な場合、expensiveCalculation()は実行されない
// これにより本番環境でのパフォーマンス低下を防げます
```

## コンテキスト機能

リクエストや処理の追跡にコンテキストを使用します。

```dart
// コンテキストを設定して実行
runWithContext({
  'requestId': 'req_123',
  'sessionId': 'sess_456',
  'screen': 'LoginScreen',
}, () {
  // この中で出力されるログには自動的にコンテキストが付与される
  i('ログイン処理開始');
  
  // ネストしたコンテキスト（マージされる）
  runWithContext({
    'userId': 'u_789',
  }, () {
    i('認証成功'); // requestId, sessionId, screen, userIdがすべて含まれる
  });
});
```

## 設定

LogConfigの完全な設定項目は `reference/logging-api.md` の LogConfig クラスを参照してください。

### デフォルト設定の使用

```dart
// 通常は設定不要（適切なデフォルト値が設定済み）
void main() {
  runApp(MyApp());
}
```

### カスタム設定

```dart
// 設定をカスタマイズする場合
final customConfig = LogConfig.defaults().copyWith(
  globalLevel: LogLevel.info,
  fileEnabled: true,
  consoleUseColor: true,
  piiMaskingEnabled: true,
  queueCapacity: 1000,
);

// カスタム設定の適用例（実際の適用方法は実装により異なる）
```

## PII（個人情報）マスキング

PII マスキングの詳細仕様とカスタマイズ方法は `reference/logging-api.md` の PII マスキングセクションを参照してください。

個人情報は自動的にマスクされます。

### 自動マスキング対象

- メールアドレス
- 電話番号
- IPアドレス
- クレジットカード番号
- JWT トークン
- 日本の郵便番号

### マスキング例

```dart
// 入力
i('ユーザー登録', fields: {
  'email': 'user@example.com',
  'phone': '090-1234-5678',
  'ip': '192.168.1.1',
});

// 出力（マスクされる）
// {"lvl":"info","msg":"ユーザー登録","fields":{"email":"[REDACTED]","phone":"[REDACTED]","ip":"[REDACTED]"}}
```

### 許可リスト

特定のフィールドをマスキングから除外する場合：

```dart
// 設定で許可リストを指定（実装詳細は要確認）
// allowListKeys: ['publicData', 'category']
```

## 例外ログ

例外の詳細情報をログに記録できます。

```dart
try {
  riskyOperation();
} catch (error, stackTrace) {
  // エラーとスタックトレースを含むログ
  e('操作が失敗しました', 
    error: error, 
    st: stackTrace, 
    tag: 'operation',
    fields: {'operation': 'riskyOperation', 'userId': 'u_123'});
}

// 致命的エラーの場合
try {
  criticalOperation();
} catch (error, stackTrace) {
  f('致命的エラーが発生', 
    error: error, 
    st: stackTrace, 
    tag: 'critical');
}
```

### 自動クラッシュキャプチャ

未処理例外を自動的にキャプチャします：

```dart
void main() {
  // クラッシュキャプチャを有効化
  installCrashCapture(rethrowOnError: true);
  
  runApp(MyApp());
}
```

## 高度な機能

### 統計情報の取得

統計情報の詳細プロパティは `reference/logging-api.md` の LoggerStats クラスを参照してください。

```dart
// 現在の統計を取得
final stats = logger.stats;
print('キューの長さ: ${stats.queueLength}');
print('ドロップされたログ数: ${stats.droppedSinceStart}');

// 統計の変化を監視
onStats().listen((stats) {
  print('統計更新: $stats');
});
```

### ログの終了とフラッシュ

```dart
// アプリ終了時にログをフラッシュ
await flushAndClose(timeout: Duration(seconds: 5));
```

### 一時的な設定変更

🚧 **開発中機能** - Phase 2で実装予定

```dart
// 一時的に設定を変更
final result = logger.withTempConfig(() {
  // この中では一時的にデバッグレベルが有効
  d('一時的なデバッグ情報');
  return performOperation();
}, (config) => config.copyWith(globalLevel: LogLevel.debug));
```

## ベストプラクティス

### 1. 適切なログレベルの使用

- `trace`: 詳細なフロー追跡（通常は無効）
- `debug`: 開発時のデバッグ情報
- `info`: 重要なビジネスイベント
- `warn`: 問題の可能性があるが動作は継続
- `error`: エラーだが復旧可能
- `fatal`: 致命的エラー、アプリ停止の可能性

### 2. タグの一貫性

```dart
// 機能ごとにタグを統一
final authLogger = withTag('auth');
final apiLogger = withTag('api');
final uiLogger = withTag('ui');
```

### 3. 遅延評価の活用

```dart
// 重い処理は遅延評価を使用
d(() => 'Heavy data: ${serializeComplexObject(data)}');

// 単純な文字列は直接指定
i('Simple message');
```

### 4. 構造化ログの活用

```dart
// 検索・分析しやすい構造化ログ
i('API呼び出し完了', fields: {
  'endpoint': '/api/users',
  'method': 'GET',
  'duration': 150,
  'status': 200,
  'userId': 'u_123',
});
```

### 5. コンテキストの適切な使用

```dart
// 画面遷移時
runWithContext({'screen': 'ProductListScreen'}, () {
  // 画面内の処理
});

// API呼び出し時
runWithContext({'requestId': generateRequestId()}, () {
  // API関連の処理
});
```

## 標準フィールドでの検索例

以下は構造化フィールドを活用した代表的なクエリ例です。環境に合わせてタグや期間を加えてください。

### Kibana (KQL)

```text
fields.operation: "order.checkout" and fields.result.status: "failure"
```

```text
fields.flow_id: flow_supabase_sync_* and fields.stage: "started"
```

### Supabase (SQL / Log Explorer)

```sql
select *
from logs
where tag = 'OrderManagementService'
  and fields->>'operation' = 'order.checkout'
  and fields->'result'->>'status' = 'success'
order by ts desc
limit 50;
```

```sql
select *
from logs
where fields->>'request_id' = 'req_01H9X7V6J3'
order by ts;
```

### フィールド欠損チェック

```text
not fields.operation or not fields.result.status
```

上記のようなクエリをダッシュボードのテンプレートに追加しておくと、標準フィールドの抜け漏れ検知やフロー単位の調査が容易になります。

## トラブルシューティング

### よくある問題

1. **ログが出力されない**
   - ログレベルの設定を確認
   - `consoleEnabled` / `fileEnabled` の設定を確認

2. **パフォーマンスの問題**
   - 遅延評価を使用しているか確認
   - キューの容量設定を確認

3. **ファイル出力されない**
   - ファイルの権限を確認
   - ディスクの容量を確認

### デバッグ方法

```dart
// ロガーの統計情報を確認
print('Logger stats: ${logger.stats}');

// 設定内容を確認
print('Logger config: ${logger.config}');
```