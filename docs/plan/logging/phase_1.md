# Flutter ロガー詳細仕様 Phase 1 v1.0（修正適用版）

> 目的：色付きコンソール出力／JSON Lines へのファイル出力／PII マスキング／省文字 API／非同期書き込みを安定提供し、以後のフェーズ拡張に備える。

---

## 0. 前提・適用範囲

* 対象：Flutter（Android / Windows / Linux）
* ランタイム：Dart（`dart:io` 利用可）
* 目的：開発時の可読性と本番時の調査性を両立し、個人情報の漏えいリスクを最小化
* 本フェーズで**実装しない**（将来拡張）：ファイルローテーション／保持（Phase 2）、レート制限・呼び出し元付与（Phase 3）、暗号化・リモート送信・Isolate 化（Phase 4）

---

## 1. 互換性の背骨（Phase 1 で確定・以後不変）

1. **公開 API 形状**

   * トップレベル：`t/d/i/w/e/f(Object msgOrThunk, {String? tag, Map<String, dynamic> Function()? fields})`
   * 例外系：`e/f(Object msgOrThunk, [Object? error, StackTrace? st], {String? tag, Map<String, dynamic> Function()? fields})`
   * ファサード：`Logger withTag(String tag)`、`Logger.log(LogLevel, ...)`
   * 遅延評価：`msgOrThunk` は `String` または `() => String`、`fields` は `Map` または `() => Map`
2. **イベントスキーマ（NDJSON のキー固定）**

   * 固定キー：`ts`(UTC ISO8601ミリ秒), `lvl`, `tag`, `msg`, `fields`, `err`({type,message}), `st`, `ctx`, `eventId`
   * 自由拡張は \`\` に格納（キー名/型は後方互換を維持）
3. **パイプライン順序（修正適用・統一規約）**

   * **A. レベル/タグ判定**（`msg/fields` 未評価のままメタ情報で判定）
   * **B. 遅延評価**（通過後に `msgOrThunk` → `fieldsThunk` を順に評価）
   * **C. PII マスキング**（`msg/fields/ctx/err/st` に適用）
   * **E. フォーマット**（ConsolePretty / JsonLine）
   * **F. Sink 出力**（Console / File）
   * ※ D（レート/バックプレッシャ）は Phase 3 以降で導入予定。Phase 1 では不使用。
4. **拡張ポイントの契約**

   * `Interceptor`, `Formatter<T>`, `Sink<T>` の責務・メソッド名は固定（以後のフェーズで差し替え）
5. **シリアライズ可能性**

   * イベントは `String/num/bool/List/Map` のみ（将来の Isolate 化に備える）

---

## 2. データモデル（イベント仕様）

**LogEvent**

* `ts` : `DateTime`（UTC, ISO8601ミリ秒）
* `lvl` : `LogLevel`（`trace|debug|info|warn|error|fatal`）
* `tag` : `String?`
* `msg` : `String`
* `fields` : `Map<String, dynamic>?`
* `err` : `{type:String, message:String}?`
* `st` : `String?`（長大時は切詰め）
* `ctx` : `Map<String, dynamic>?`
* `eventId` : `String`（短いUUID）

**ファイル（NDJSON）出力例**

```json
{"ts":"2025-08-17T10:23:45.123Z","lvl":"info","tag":"auth","msg":"login ok","fields":{"userId":"u_123"},"ctx":{"screen":"Login"},"eventId":"a1b2c3"}
```

---

## 3. API（省文字＆一貫性）

### トップレベル関数

* `t/d/i/w/e/f(Object msgOrThunk, {String? tag, Map<String, dynamic> Function()? fields})`
* `e/f` は第2/第3引数に `error` / `StackTrace?` を許容

### ファサード

* `Logger withTag(String tag)`
* `Logger.log(LogLevel level, Object msgOrThunk, {String? tag, Map<String, dynamic> Function()? fields, Object? error, StackTrace? st})`

### 使用例

```dart
final auth = withTag('auth');
auth.i('login ok', fields: {'userId':'u_123'});
e('failed', err, st, tag: 'api');
d(() => 'heavy ${expensive()}');
i('ok', fields: () => buildBigMap());
```

---

## 4. コンソール整形（スタイリング仕様）

* **色**（ANSI）：`trace=90, debug=34, info=32, warn=33, error=31, fatal=97;41`
* **フォールバック**：ANSI不可→絵文字接頭辞（ℹ️/⚠️/❌ 等）→プレーン
* **フォーマット**：`HH:mm:ss.SSS [LVL] (tag) msg {k:v} #eventId`
* **環境検出**：起動時に簡易判定し自動選択

---

## 5. ファイル出力（NDJSON）

* 文字コード：UTF-8
* **ファイル名**：`app-YYYYMMDD-01.log`（*Phase 1 はアプリ起動時の日付を用い、起動中の⽇付跨ぎでは切替しない*）
* **書き込み**：`IOSink` に非同期 append、`flushEveryLines=20` または `flushEveryMs=500` のいずれかで flush
* **異常時**：書込失敗を一度だけコンソール警告し、FileSink を停止（以後は Console のみ）

---

## 6. PII マスキング（Interceptor 仕様）

### 6.1 適用位置と対象

* **パイプライン**：A→B の直後、**必ず C** で適用
* **対象**：`msg`、`fields`（再帰深さ2の文字列値）、`ctx`、`err.message`、`st`（文字列部）

### 6.2 既定ルール（代表）

* Email：`[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
* 電話（緩め）：`\+?\d[\d -]{8,}\d`
* **IP（修正適用）**：正規表現ベースではなく `InternetAddress.tryParse` を優先。成功時にマスク。必要な補助として IPv4 の最小表現のみ正規表現を併用可。
* クレカ（代表）：VISA/Master/Amex/Discover 等の BIN パターン（Luhn 検証は任意）
* JWT：`[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}`
* トークン例：`(sk-[A-Za-z0-9]{16,})|(AKIA[0-9A-Z]{16})`
* 郵便番号（日本）：`\b\d{3}-\d{4}\b`

### 6.3 マスク方式

* 既定：`[REDACTED]`
* 任意：`hash`（SHA-256 + 起動時ソルト）、`partial(keepTail=4)` → `*******1234`

### 6.4 カスタム

* `customPatterns`（正規表現）を設定で追加可能
* `allowListKeys`：`fields` の特定キーは素通し（既定は空）

---

## 7. 非同期パイプライン（実行モデル）

* **キュー**：固定長リングバッファ（既定 500）

  * 溢れ：**新規をドロップ**し内部 `_droppedCount` を増やす（Phase 3 で可視化予定）
* **実行**：同一 Isolate のイベントループで非同期処理（`Future`/`Timer`）
* **遅延評価**：A（レベル/タグ）通過後にのみ `msg`→`fields` を評価

---

## 8. 設定（Config）と既定値

```dart
class LogConfig {
  LogLevel globalLevel;            // debug: DEBUG, release: INFO
  bool consoleEnabled;             // true
  bool fileEnabled;                // true
  bool consoleUseColor;            // 自動検出
  bool consoleUseEmojiFallback;    // 自動検出
  String fileDirPath;              // path_provider で解決
  int flushEveryLines;             // 20
  int flushEveryMs;                // 500
  int queueCapacity;               // 500
  bool piiMaskingEnabled;          // true
  MaskMode maskMode;               // redact/hash/partial(4)
  List<RegExp> customPatterns;     // []
  Map<String, LogLevel> tagLevels; // {}  // 評価は A 段で使用（Phase 2 以降で強化）
}
```

* **ビルド既定**：

  * `debug`：`globalLevel=DEBUG`、色有効、PII=ON
  * `release`：`globalLevel=INFO`、色は検出任せ、PII=ON

---

## 9. 受け入れ基準（Phase 1）

1. **色分け**：`trace/debug/info/warn/error/fatal` が ANSI または絵文字で視認できる。
2. **並行出力**：同一イベントが Console と File の双方に出力される。
3. **PII**：`"email":"a@b.com"` が `[REDACTED]` に置換される（`fields/ctx/err/st` も含む）。
4. **省文字 API**：`d('x')` で即時出力でき、`d(() => heavy())` はしきい値未満で未評価。
5. **性能**：100行/秒の連続出力で UI の体感カクつきが発生しない。
6. **ファイル**：NDJSON 形式、UTF-8、`app-YYYYMMDD-01.log` に追記される。

---

## 10. 非機能要件

* **性能**：フィルタ判定 O(1)。平均レイテンシ（Console のみ）< 0.2ms/行（目安）。
* **メモリ**：キュー長とバッファを設定可能。
* **信頼性**：ファイル I/O 失敗時は Console へフォールバックし、以後 FileSink を停止。
* **テスト容易性**：`Interceptor/Formatter/Sink` を差し替え可能にし、モックで検証。
* **移植性**：出力パスは `path_provider` により OS 別に解決。

---

## 11. テスト計画（Phase 1）

* **単体**：

  * PII：既定パターンの置換、`InternetAddress.tryParse` の結果マスク
  * Console フォーマッタの ANSI / 絵文字フォールバック
  * 遅延評価が A 不通過時に未評価であること
* **結合**：

  * Console + File の並行出力
  * 100行/秒のスパイク出力で UI の体感カクつき無し
* **E2E**：

  * 実機/デスクトップで NDJSON が正しいこと
  * I/O 異常時のフォールバックが 1 回だけ警告されること

---

## 12. 依存（最小）

* `path_provider`（保存先解決）
* `crypto`（ハッシュ／マスキングの hash モード用）
* 標準ライブラリ（`dart:io`, `dart:convert`）

---

## 13. 用語・規約

* **NDJSON**：1 行 1 JSON オブジェクト
* **PII**：個人情報またはそれに準ずる識別子
* **A–F**：パイプライン段（A: Filter, B: Eval, C: PII, E: Format, F: Sink）

---

### 付記（将来拡張へのフック）

* **ローテーション/保持**：`RotationPolicy/RetentionPolicy` を導入する前提で `FileSink` を分割実装（Phase 2）。
* **レート/サンプリング/呼び出し元**：`Interceptor` と `CallsiteConfig` で追加（Phase 3）。
* **暗号化/リモート/Isolate**：`Writer` 差し替え、`RemoteSink` 追加、ログ専用 Isolate（Phase 4）。
