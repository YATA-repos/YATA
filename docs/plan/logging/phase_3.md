# Flutter ロガー詳細仕様 Phase 3 v1.0（修正適用版）

> 目的：**運用時の安全性と制御性の強化**。未捕捉例外の収集、ログ量制御（レート制限・サンプリング）、呼び出し元情報、バックプレッシャ方針と内部ヘルス指標、グレースフルシャットダウンを追加する。Phase 1/2 の互換性の背骨（API/スキーマ/パイプライン）を維持し、破壊的変更を行わない。

---

## 0. 前提・適用範囲

* 対象：Flutter（Android / Windows / Linux）
* ランタイム：Dart（`dart:io` 利用可）
* 前提：Phase 1（コンソール/NDJSON、PII、非同期）と Phase 2（ローテ/保持、コンテキスト、動的レベル）が導入済み
* 非スコープ（Phase 4 以降）：暗号化、リモート送信、OTA、Isolate 化

---

## 1. 互換性の背骨（不変条件・再掲）

1. **公開 API 形状**（Phase 1 と同一）

* `t/d/i/w/e/f(Object msgOrThunk, {String? tag, Map<String, dynamic> Function()? fields})`
* `e/f(Object msgOrThunk, [Object? error, StackTrace? st], {String? tag, Map<String, dynamic> Function()? fields})`
* `Logger withTag(String tag)` / `Logger.log(...)`
* 遅延評価：`msgOrThunk` は `String` or `() => String`、`fields` は `Map` or `() => Map`

2. **イベントスキーマ（NDJSON）**

* 固定キー：`ts,lvl,tag,msg,fields,err,st,ctx,eventId`
* 自由拡張は \`\` に格納

3. **パイプライン順序（修正適用・統一）**

* **A. レベル/タグ判定**（`msg/fields` 未評価）
* **B. 遅延評価**（`msg` → `fields`）
* **C. PII マスキング**（`msg/fields/ctx/err/st`）
* **D. レート/サンプリング/バックプレッシャ**（本フェーズで導入）
* **E. フォーマット**（ConsolePretty/JsonLine）
* **F. Sink 出力**（Console/File）

4. **シリアライズ可能性**：イベントは `String/num/bool/List/Map` のみ

---

## 2. 追加機能サマリ（Phase 3）

* **未捕捉例外の収集**：Flutter/Zone/プラットフォーム経由でハンドル
* **レート制限 & サンプリング**：グローバル/タグ/（タグ,レベル）で制御、抑止サマリ出力
* **呼び出し元情報（Callsite）**：ファイル/行/メンバ（任意、既定OFF）
* **バックプレッシャ方針 & 内部ヘルス指標**：キューあふれ時の挙動と可視化
* **グレースフルシャットダウン**：フラッシュとクローズの完了保証

---

## 3. 未捕捉例外の収集（Crash/Unhandled）

### 3.1 取得ポイント

* `FlutterError.onError`（Flutter フレームワーク例外）
* `PlatformDispatcher.instance.onError`（非同期エラー；対応環境）
* アプリエントリを `runZonedGuarded(() { runApp(...); }, onError)` でラップ
* （任意）将来の Isolate 化を見据え `Isolate.current.addErrorListener` は Phase 4 で拡張

### 3.2 ログ化ルール

* **レベル**：致命（アプリ継続不能）→ `fatal`、継続可能→ `error`
* **デデュープ**：`hash(message + 上位Nフレーム)`（N 既定=5）をキーに、**30秒**の窓で詳細は1回のみ。それ以降は要約のみ。
* **要約**：窓内再発時、`tag:'crash'`, `msg:'crash_suppressed'`, `fields:{hash:..., suppressed:count}` を **60秒** ごとに1行
* **再スロー**：既定 `rethrow=true`（プラットフォーム標準動作を維持）。`rethrow=false` も設定可能。

### 3.3 取り込み項目

* `err`：`{type: error.runtimeType, message: error.toString()}`
* `st` ：先頭 **20行**を保持。長大時は `...(truncated)` を付与
* `fields.crash`：`{handled:'unhandled', zone:true/false}`
* **PII**：`err/st` を含むテキスト域に **C 段で常に適用**

---

## 4. レート制限 & サンプリング（D 段）

### 4.1 位置と順序

* **C（PII）後**, **E（フォーマット）前** に適用（安全優先）

### 4.2 モデル

* **トークンバケット**（`capacity`, `refillPerSec`）を下記キーで適用：

  * **グローバル**
  * **タグ別**（`tag`）
  * **タグ×レベル**（`(tag, level)`）
* **サンプリング**：割合（0–100%）を `(tag, level)` 単位で設定可（例：`('api', DEBUG)=10%`）

### 4.3 設定

```dart
class TokenBucket { int capacity; int refillPerSec; }
class RateConfig {
  bool enabled;                         // default: true
  TokenBucket global;                   // default: cap=200, refill=200/s
  Map<String, TokenBucket> perTag;      // {}
  Map<(String, LogLevel), TokenBucket> perTagLevel; // {}
  Map<(String, LogLevel), int> sampling; // percentage 0..100
  Duration summaryInterval;             // default: 60s
}
```

### 4.4 抑止ログのサマリ

* キーごとに `summaryInterval` 間隔で 1 行：

  * `tag:'logger'`, `msg:'rate_limited'`, `fields:{key:'api:DEBUG', suppressed:123}`
* このサマリ自身は **レート制限の対象外**（ただし暴走防止の内部上限は実装可）

---

## 5. 呼び出し元情報（Callsite）

### 5.1 概要

* オプションで `fields.src = {file, line, member}` を付与
* 既定 **OFF**（コスト/ノイズのため）。`debug` ビルドのみ自動 ON にする運用は可（設定次第）

### 5.2 取得方法

* `StackTrace.current` を1回取得し、最初の **ユーザーコード** フレームを抽出

  * ロガー自身や `dart:async` などのフレームはスキップ
  * 可能なら `package:stack_trace` でパース/正規化

### 5.3 設定

```dart
class CallsiteConfig {
  bool enabled;                 // default: false
  int  skipFrames;              // default: 自動検出（ロガー内部分を計算）
  bool basenameOnly;            // default: true（パス→ファイル名に短縮）
  int  cacheSize;               // default: 256（LRU）
}
```

---

## 6. バックプレッシャ方針 & 内部ヘルス指標

### 6.1 キューあふれ時の挙動

```dart
enum OverflowPolicy { dropNew, dropOld, blockWithTimeout }
```

* **既定**：`dropNew`（UI 保護を最優先）
* `blockWithTimeout`：`overflowBlockTimeout`（既定 50ms）まで待ち、超過でドロップし警告

### 6.2 内部ヘルス指標（Stats）

* `LoggerStats`：

  * `queueLength`, `queueCapacity`
  * `droppedSinceStart`, `rateSuppressedSinceStart`
  * `lastFileError`, `activeLogFile`
* 公開 API：`Stream<LoggerStats> onStats()` / `LoggerStats get stats`
* 任意で `tag:'logger', msg:'health'` の定期メタログを出力（間隔/出力先は設定）

---

## 7. グレースフルシャットダウン

### 7.1 API

```dart
Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)});
```

* すべてのバッファを flush → sinks を close。タイムアウト超過時は残処理を破棄し、コンソールに 1 回だけ警告

### 7.2 ライフサイクル統合（任意）

* Flutter：`WidgetsBindingObserver` で `paused`/`inactive` へ遷移時にベストエフォート flush
* デスクトップ：`ProcessSignal.sigint` 等を捕捉できる範囲で flush 実行

---

## 8. 設定（Phase 3 追加）

```dart
class LogConfig {
  RateConfig rate;                 // §4
  CallsiteConfig callsite;         // §5
  OverflowPolicy overflowPolicy;   // §6（default: dropNew）
  Duration overflowBlockTimeout;   // default: 50ms
  bool crashCaptureEnabled;        // default: true
  Duration crashDedupWindow;       // default: 30s
  Duration crashSummaryInterval;   // default: 60s
}
```

* 既定は **後方互換**を壊さない保守的設定（全機能 OFF/弱め）

---

## 9. 相互作用・優先順位ルール

* **PII**：`msg/fields/ctx/err/st` の全テキスト域に **C 段で必ず適用**
* **レート/サンプリング**：**C 後・E 前**（安全側）。抑止した件数はサマリで可視化
* **呼び出し元**：`enabled=true` のときのみ `fields.src` を付与（マスキング対象外のメタ）。解析の混乱を避けるため `fields.src` キー名は固定
* **オーバーフロー**：`dropNew` を既定。`blockWithTimeout` の使用は本番 UI への影響に留意
* **シャットダウン**：`flushAndClose()` 呼出後は新規ログを受け付けない（エラーにしないが黙殺可）

---

## 10. 受け入れ基準（検証可能）

1. **未捕捉例外**

* `throw Exception()` を `runZonedGuarded` 外で発火 → 初回は詳細（`fatal`/`error`）が1回、30秒内の再発は要約のみ

2. **レート制限**

* `('api', DEBUG)` に 10/s を設定し 100/s 発火 → 10件のみ通過、サマリが1分ごと1行

3. **サンプリング**

* `('ui', INFO)=50%` 設定で 100 件 → 通過数がおおむね 50±10 件

4. **呼び出し元**

* `callsite.enabled=true` で `fields.src.file` が呼び出しファイル名、`line` は正整数、同一フレームはキャッシュが効く

5. **バックプレッシャ**

* `queueCapacity` 超過で `dropNew` が作動し、`droppedSinceStart` が増加

6. **シャットダウン**

* 大量出力直後の `flushAndClose()` でファイル末尾欠落がない

7. **後方互換**

* Phase 1/2 の設定のみでも挙動変化なし（新機能は既定 OFF/保守的）

---

## 11. テスト計画

* **単体**：

  * トークンバケットの境界/再充填、サンプリングの偏り検証
  * 呼び出し元抽出（スキップ/正規化/キャッシュ）
  * 例外デデュープ（ハッシュ一致/不一致）
* **結合**：

  * 例外連打 + デデュープ + サマリ
  * レート制限とローテーション（Phase 2）併用時の整合
  * オーバーフロー各方針（`dropNew/dropOld/blockWithTimeout`）
* **E2E**：

  * 実端末での `flushAndClose` 完了保証
  * 高負荷下の UI レイテンシ観測（Phase 4 の Isolate 化と比較用ベースライン）

---

## 12. 非機能要件

* **性能**：

  * レート判定 O(1)、サンプリング O(1)
  * 呼び出し元有効時のみスタック解析コスト発生（LRU キャッシュで軽減）
* **信頼性**：

  * 例外スパムはデデュープ＋要約で抑止、損失はサマリで可視化
  * シャットダウンでバッファ消失を最小化
* **セキュリティ/プライバシ**：

  * 追加情報（`src`/要約/ヘルス）も PII マスキングの影響を受ける（ただし通常 `src` は PII 非該当）

---

## 13. 依存関係

* 追加候補：`stack_trace`（呼び出し元抽出の正規化）
* 既存：`path_provider`, 標準ライブラリ

---

## 14. 用語・規約

* **A–F**：パイプライン段（A\:Filter, B\:Eval, C\:PII, D\:Rate/Overflow, E\:Format, F\:Sink）
* **Token Bucket**：容量と毎秒の補充レートで制御するレート制限手法
* **Callsite**：ログ呼出元の位置情報（ファイル/行/メンバ）

---

## 15. Phase 2 からの変更点（修正適用済み）

* パイプライン順序を **A→B→C→D→E→F** に統一（D 段の導入）
* レート/サンプリングは **C 後・E 前** に適用
* バックプレッシャ方針（`OverflowPolicy`）と Stats を導入
* グレースフルシャットダウン API を追加
* 呼び出し元情報は `fields.src` に格納、既定 OFF
