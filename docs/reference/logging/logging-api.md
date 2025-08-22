# ロギングライブラリ APIリファレンス

このドキュメントでは、YATAプロジェクトのロギングライブラリ（`lib/infrastructure/logging/`）の詳細なAPIリファレンスを提供します。

## 目次

1. [トップレベル関数](#トップレベル関数)
2. [Logger クラス](#logger-クラス)
3. [LogEvent クラス](#logevent-クラス)
4. [LogLevel 列挙型](#loglevel-列挙型)
5. [LogConfig クラス](#logconfig-クラス)
6. [コンテキスト機能](#コンテキスト機能)
7. [PII マスキング](#pii-マスキング)
8. [ポリシー設定](#ポリシー設定)
9. [フォーマッター](#フォーマッター)
10. [シンク](#シンク)

## トップレベル関数

実際の使用例とベストプラクティスは `guide/logging.md` を参照してください。

### ログ出力関数

#### `t(Object msgOrThunk, {String? tag, Object? fields})`
トレースレベルのログを出力します。

**パラメータ:**
- `msgOrThunk`: メッセージ文字列または遅延評価関数 `() => String`
- `tag`: ログのタグ（オプション）
- `fields`: 追加フィールド `Map<String, dynamic>` または遅延評価関数（オプション）

**使用例:**
```dart
t('詳細なトレース情報');
t(() => 'Heavy trace: ${expensiveOperation()}');
t('API呼び出し', tag: 'api', fields: {'endpoint': '/users'});
```

#### `d(Object msgOrThunk, {String? tag, Object? fields})`
デバッグレベルのログを出力します。

**パラメータ:** `t()` と同じ

**使用例:**
```dart
d('デバッグ情報');
d('変数の値', fields: {'value': someVariable});
```

#### `i(Object msgOrThunk, {String? tag, Object? fields})`
インフォレベルのログを出力します。

**パラメータ:** `t()` と同じ

**使用例:**
```dart
i('処理が完了しました');
i('ユーザーログイン', tag: 'auth', fields: {'userId': 'u_123'});
```

#### `w(Object msgOrThunk, {String? tag, Object? fields})`
警告レベルのログを出力します。

**パラメータ:** `t()` と同じ

**使用例:**
```dart
w('非推奨のAPIを使用');
w('リトライ回数上限', fields: {'retryCount': 3});
```

#### `e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields})`
エラーレベルのログを出力します。

**パラメータ:**
- `msgOrThunk`: メッセージ文字列または遅延評価関数
- `error`: エラーオブジェクト（オプション）
- `st`: スタックトレース（オプション）
- `tag`: ログのタグ（オプション）
- `fields`: 追加フィールド（オプション）

**使用例:**
```dart
e('処理中にエラーが発生');
e('API呼び出し失敗', error: exception, st: stackTrace, tag: 'api');
```

#### `f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields})`
致命的エラーレベルのログを出力します。

**パラメータ:** `e()` と同じ

**使用例:**
```dart
f('致命的なエラーが発生', error: fatalException, st: stackTrace);
```

### 設定関数

実際の使用例とベストプラクティスは `guide/logging.md` のタグ機能セクションを参照してください。

#### `Logger withTag(String tag)`
指定されたタグを持つLoggerインスタンスを返します。

**パラメータ:**
- `tag`: ログのタグ

**戻り値:** `Logger` インスタンス

**使用例:**
```dart
final authLogger = withTag('auth');
authLogger.i('認証成功');
```

#### `void setGlobalLevel(LogLevel level)`
グローバルログレベルを設定します。

**パラメータ:**
- `level`: 設定するログレベル

#### `void setTagLevel(String tag, LogLevel level)`
特定のタグに対するログレベルを設定します。

**パラメータ:**
- `tag`: タグ名
- `level`: ログレベル

#### `void clearTagLevel(String tag)`
特定のタグのログレベル設定をクリアします。

**パラメータ:**
- `tag`: タグ名

### 高度な機能

#### `Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)})`
ログキューをフラッシュし、すべてのシンクを閉じます。

**パラメータ:**
- `timeout`: タイムアウト期間

#### `void installCrashCapture({bool? rethrowOnError})`
未処理例外の自動キャプチャを有効にします。

**パラメータ:**
- `rethrowOnError`: エラーを再スローするかどうか（デフォルト: `true`）

#### `Stream<LoggerStats> onStats()`
ロガーの統計情報ストリームを返します。

**戻り値:** `Stream<LoggerStats>`

#### `LoggerStats get stats`
現在のロガー統計情報を取得します。

**戻り値:** `LoggerStats`

## Logger クラス

実践的な使用方法は `guide/logging.md` のタグ機能セクションを参照してください。

### コンストラクタ

`Logger` クラスは直接インスタンス化できません。`withTag()` 関数を使用してください。

### メソッド

#### `Logger withTag(String tag)`
新しいタグを持つLoggerインスタンスを返します。

#### `void log(LogLevel level, Object msgOrThunk, {String? tag, Object? fields, Object? error, StackTrace? st})`
指定されたレベルでログを出力します。

**パラメータ:**
- `level`: ログレベル
- `msgOrThunk`: メッセージまたは遅延評価関数
- `tag`: タグ（オプション）
- `fields`: フィールド（オプション）
- `error`: エラー（オプション）
- `st`: スタックトレース（オプション）

#### ショートハンドメソッド

- `void t(Object msgOrThunk, {String? tag, Object? fields})`
- `void d(Object msgOrThunk, {String? tag, Object? fields})`
- `void i(Object msgOrThunk, {String? tag, Object? fields})`
- `void w(Object msgOrThunk, {String? tag, Object? fields})`
- `void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields})`
- `void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields})`

### 設定管理メソッド

#### `LogConfig get config`
現在の設定を取得します。

#### `void setGlobalLevel(LogLevel level)`
グローバルレベルを設定します。

#### `void setTagLevel(String tag, LogLevel level)`
タグ別レベルを設定します。

#### `void clearTagLevel(String tag)`
タグ別レベル設定をクリアします。

#### `T withTempConfig<T>(T Function() body, LogConfig Function(LogConfig) mutate)`
一時的に設定を変更して処理を実行します。

**パラメータ:**
- `body`: 実行する処理
- `mutate`: 設定変更関数

**戻り値:** `body` の戻り値

## LogEvent クラス

ログパイプラインを通過するイミュータブルなイベントデータです。

### プロパティ

#### `DateTime ts`
ログのタイムスタンプ（UTC）

#### `LogLevel lvl`
ログレベル

#### `String? tag`
ログのタグ（オプション）

#### `String msg`
ログメッセージ

#### `Map<String, dynamic>? fields`
構造化フィールド（オプション）

#### `Map<String, String>? err`
エラー情報 `{type: String, message: String}`（オプション）

#### `String? st`
スタックトレース文字列（オプション）

#### `Map<String, dynamic>? ctx`
ログコンテキスト（オプション）

#### `String eventId`
短いイベントID（12文字の16進数）

### メソッド

#### `LogEvent copyWith({...})`
一部のプロパティを変更したコピーを作成します。

#### `Map<String, dynamic> toJson()`
JSON形式の辞書に変換します。

#### `String toNdjson()`
NDJSON形式の文字列に変換します。

## LogLevel 列挙型

ログの重要度レベルを表します。

### 値

- `LogLevel.trace` - トレース（最も詳細）
- `LogLevel.debug` - デバッグ
- `LogLevel.info` - 情報
- `LogLevel.warn` - 警告
- `LogLevel.error` - エラー
- `LogLevel.fatal` - 致命的エラー（最も重要）

### 拡張メソッド

#### `String get name`
レベル名を小文字で取得します。

**戻り値:** `"trace"`, `"debug"`, `"info"`, `"warn"`, `"error"`, `"fatal"`

#### `String get labelUpper`
レベル名を大文字で取得します。

**戻り値:** `"TRACE"`, `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`, `"FATAL"`

## LogConfig クラス

設定のベストプラクティスと実際の使用例は `guide/logging.md` の設定セクションを参照してください。

ロガーの設定を管理するクラスです。

### 主要プロパティ

#### `LogLevel globalLevel`
グローバルログレベル
- デバッグビルド: `DEBUG`
- リリースビルド: `INFO`

#### `bool consoleEnabled`
コンソール出力の有効化（デフォルト: `true`）

#### `bool fileEnabled`
ファイル出力の有効化（デフォルト: `true`）

#### `bool consoleUseColor`
コンソールでの色付きの使用（自動検出）

#### `bool consoleUseEmojiFallback`
ANSIが使用できない場合の絵文字フォールバック（自動検出）

#### `String fileDirPath`
ログファイルの出力ディレクトリパス

#### `String fileBaseName`
ログファイルのベース名（デフォルト: `"app"`）

#### `RotationPolicy rotation`
ファイルローテーションポリシー

#### `RetentionPolicy retention`
ファイル保持ポリシー

#### `int flushEveryLines`
何行ごとにフラッシュするか（デフォルト: `20`）

#### `int flushEveryMs`
何ミリ秒ごとにフラッシュするか（デフォルト: `500`）

#### `int queueCapacity`
ログキューの容量（デフォルト: `500`）

#### `bool piiMaskingEnabled`
PII マスキングの有効化（デフォルト: `true`）

#### `MaskMode maskMode`
マスキングモード（redact/hash/partial）

#### `List<RegExp> customPatterns`
カスタムPIIパターン

#### `Map<String, LogLevel> tagLevels`
タグ別ログレベル設定

#### `List<String> allowListKeys`
PII マスキングの除外キー

#### `bool enableContext`
コンテキスト機能の有効化（デフォルト: `true`）

#### `RateConfig rate`
レート制限設定（Phase 3）

#### `CallsiteConfig callsite`
呼び出し元情報設定（Phase 3）

#### `OverflowPolicy overflowPolicy`
キューオーバーフロー時のポリシー（Phase 3）

#### `bool crashCaptureEnabled`
クラッシュキャプチャの有効化（Phase 3）

### メソッド

#### `LogConfig copyWith({...})`
一部のプロパティを変更したコピーを作成します。

#### `static LogConfig defaults({String? fileDirPath})`
デフォルト設定でLogConfigを作成します。

**パラメータ:**
- `fileDirPath`: ファイル出力ディレクトリパス

## コンテキスト機能

コンテキスト機能の実践的な使用方法は `guide/logging.md` のコンテキスト機能セクションを参照してください。

### 型定義

#### `typedef LogContext = Map<String, Object?>`
ログコンテキストの型定義

### 関数

#### `LogContext? currentLogContext()`
現在のログコンテキストを取得します。

**戻り値:** 現在のコンテキスト、またはnull

#### `T runWithContext<T>(LogContext ctx, T Function() body, {bool merge = true})`
指定されたコンテキストで処理を実行します。

**パラメータ:**
- `ctx`: 設定するコンテキスト
- `body`: 実行する処理
- `merge`: 親コンテキストとマージするか（デフォルト: `true`）

**戻り値:** `body` の戻り値

**使用例:**
```dart
runWithContext({'requestId': 'req_123'}, () {
  i('処理開始'); // コンテキストが自動的に含まれる
  
  runWithContext({'userId': 'u_456'}, () {
    i('ユーザー処理'); // requestIdとuserIdの両方が含まれる
  });
});
```

## PII マスキング

実際の使用例とカスタマイズ方法は `guide/logging.md` の PII マスキングセクションを参照してください。

### MaskMode

PIIのマスキング方式を指定します。

#### `MaskMode.redact()`
`[REDACTED]` に置換

#### `MaskMode.hash()`
SHA-256ハッシュに置換

#### `MaskMode.partial({int keepTail = 4})`
末尾の指定文字数を残して `*` で置換

### 自動検出パターン

以下のパターンが自動的にマスキングされます：

- **Email**: `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
- **電話番号**: `\+?\d[\d -]{8,}\d`
- **IPアドレス**: `InternetAddress.tryParse()` による検証
- **クレジットカード**: VISA/Master/Amex/Discover等のBINパターン
- **JWT**: `[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}`
- **APIキー**: `(sk-[A-Za-z0-9]{16,})|(AKIA[0-9A-Z]{16})`
- **郵便番号（日本）**: `\b\d{3}-\d{4}\b`

## ポリシー設定

### RotationPolicy

ファイルローテーションのポリシーです。

#### `DailyRotation(String timeZone)`
日次ローテーション

**パラメータ:**
- `timeZone`: タイムゾーン（例: `"UTC"`, `"Asia/Tokyo"`）

#### `SizeRotation(int maxBytes)`
サイズベースローテーション

**パラメータ:**
- `maxBytes`: 最大ファイルサイズ（バイト）

#### `CompositeRotation(List<RotationPolicy> policies)`
複数のポリシーの組み合わせ

**パラメータ:**
- `policies`: 適用するポリシーのリスト

### RetentionPolicy

ファイル保持のポリシーです。

#### `MaxFiles(int maxFiles)`
最大ファイル数による保持

**パラメータ:**
- `maxFiles`: 保持する最大ファイル数

#### `MaxDays(int maxDays)`
最大日数による保持

**パラメータ:**
- `maxDays`: 保持する最大日数

### OverflowPolicy

🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

キューオーバーフロー時のポリシーです。

#### `OverflowPolicy.dropNew`
新しいログを破棄

#### `OverflowPolicy.dropOld`
古いログを破棄

#### `OverflowPolicy.blockWithTimeout`
タイムアウトまで待機

### RateConfig

🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

レート制限の設定です。

#### 主要プロパティ

- `bool enabled`: レート制限の有効化
- `TokenBucket global`: グローバルレート制限
- `Map<String, TokenBucket> perTag`: タグ別レート制限
- `Map<(String, LogLevel), TokenBucket> perTagLevel`: タグ×レベル別レート制限
- `Map<(String, LogLevel), int> sampling`: サンプリング率（0-100%）
- `Duration summaryInterval`: 要約出力間隔

### CallsiteConfig

🚧 **実装中（Phase 3予定）** - 2025年Q1実装予定

呼び出し元情報の設定です。

#### 主要プロパティ

- `bool enabled`: 有効化フラグ
- `bool basenameOnly`: ファイル名のみ表示
- `int? skipFrames`: スキップするフレーム数
- `int cacheSize`: キャッシュサイズ

## フォーマッター

### ConsolePrettyFormatter

コンソール用の見やすいフォーマッターです。

#### 出力形式

```
HH:mm:ss.SSS [LVL] (tag) message {field:value} #eventId
```

#### 色分け

- `trace`: グレー (ANSI 90)
- `debug`: 青 (ANSI 34)  
- `info`: 緑 (ANSI 32)
- `warn`: 黄 (ANSI 33)
- `error`: 赤 (ANSI 31)
- `fatal`: 白地に赤背景 (ANSI 97;41)

#### フォールバック

ANSI色が使用できない環境では絵文字を使用：
- `info`: ℹ️
- `warn`: ⚠️
- `error`: ❌
- `fatal`: 💀

### NdjsonFormatter

NDJSON（改行区切りJSON）フォーマッターです。

#### 出力例

```json
{"ts":"2025-08-22T10:23:45.123Z","lvl":"info","tag":"auth","msg":"login success","fields":{"userId":"u_123"},"eventId":"a1b2c3"}
```

## シンク

### ConsoleSink

標準出力へのシンクです。

#### メソッド

- `Future<void> add(String line)`: 行を出力
- `Future<void> flush()`: フラッシュ
- `Future<void> close()`: クローズ

### FileSink

ファイル出力用のシンクです。

#### 主要機能

- 非同期書き込み
- 自動フラッシュ（行数またはタイマー）
- ローテーション対応
- 保持ポリシー対応
- エラー時の自動無効化

#### プロパティ

- `String? get activeFilePath`: 現在のファイルパス
- `Object? get lastError`: 最後のエラー

## LoggerStats クラス

ロガーの統計情報を表すクラスです。

### プロパティ

#### `int queueLength`
現在のキューの長さ

#### `int queueCapacity`
キューの最大容量

#### `int droppedSinceStart`
開始以来ドロップされたログの総数

#### `int rateSuppressedSinceStart`
レート制限により抑制されたログの総数

#### `Object? lastFileError`
最後に発生したファイルエラー

#### `String? activeLogFile`
現在アクティブなログファイルのパス

## 型エイリアス

### `typedef MsgThunk = String Function()`
遅延評価メッセージ関数の型

### `typedef FieldsThunk = Map<String, dynamic> Function()`
遅延評価フィールド関数の型

### `typedef TagLevel = (String, LogLevel)`
タグとレベルのペアの型

## 使用例

基本的な使用方法とベストプラクティスは `guide/logging.md` を参照してください。

### 基本的な使用

```dart
import 'package:yata/infrastructure/logging/logging.dart';

void main() {
  // 基本的なログ出力
  i('アプリケーション開始');
  
  // その他の詳細な使用例は guide/logging.md を参照
}
```