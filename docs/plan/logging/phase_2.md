# Flutter ロガー詳細仕様 Phase 2 v1.0（修正適用版）

> 目的：Phase 1 の互換性の背骨（API/スキーマ/パイプライン）を維持したまま、運用に必須の **ファイル・ローテーション**、**保持ポリシー**、**タグ別レベル/動的設定**、**コンテキスト API**、**遅延評価の厳密化** を追加する。

---

## 0. 前提・適用範囲

* 対象：Flutter（Android / Windows / Linux）
* ランタイム：Dart（`dart:io` 利用可）
* 前提：Phase 1 仕様が導入済み（ConsolePretty/NDJSON、PII マスキング、非同期キュー、トップレベル API）
* 非スコープ：レート制限/呼び出し元/クラッシュ収集（Phase 3）、暗号化/リモート送信/OTA/Isolate（Phase 4）

---

## 1. 互換性の背骨（不変条件）

1. **公開 API 形状**（Phase 1 と同一）

* `t/d/i/w/e/f(Object msgOrThunk, {String? tag, Map<String, dynamic> Function()? fields})`
* `e/f(Object msgOrThunk, [Object? error, StackTrace? st], {String? tag, Map<String, dynamic> Function()? fields})`
* `Logger withTag(String tag)` / `Logger.log(...)`
* 遅延評価：`msgOrThunk` は `String` or `() => String`、`fields` は `Map` or `() => Map`

2. **イベントスキーマ（NDJSON）**

* 固定キー：`ts,lvl,tag,msg,fields,err,st,ctx,eventId`
* 自由拡張は **`fields`** に格納

3. **パイプライン順序（修正適用・統一）**

* **A. レベル/タグ判定**（`msg/fields` 未評価）
* **B. 遅延評価**（`msg` → `fields`）
* **C. PII マスキング**（`msg/fields/ctx/err/st`）
* **D.（Phase 3〜）** レート/サンプリング/オーバーフロー
* **E. フォーマット**（ConsolePretty/JsonLine）
* **F. Sink 出力**（Console/File）

4. **シリアライズ可能性**：イベントは `String/num/bool/List/Map` のみ

---

## 2. 追加機能サマリ（Phase 2）

* **ファイル・ローテーション**：日次・サイズ・複合
* **保持ポリシー**：最大個数/最大日数/複合
* **タグ別レベル/動的設定**：`globalLevel` と `tagLevels` の併用、ランタイム即時反映
* **コンテキスト API**：`runWithContext` による相関 ID 等の付与と非同期伝播
* **遅延評価の厳密化**：評価順序と適用範囲を明文化

---

## 3. ファイル・ローテーション仕様

### 3.1 ポリシー（Strategy）

* `RotationPolicy` 抽象を導入し差し替え可能：

  * `NoRotation`（Phase 1 同等）
  * `DailyRotation({String timezone = 'UTC'})`
  * `SizeRotation({required int maxBytes /*例: 5 * 1024 * 1024*/})`
  * `CompositeRotation(List<RotationPolicy> policies)` ※**いずれかが真**で回転

### 3.2 判定とトリガ（修正適用）

* **UTF-8 エンコード後のバイト長**でサイズ判定し、**閾値超過前**に回転（次レコード追記で超過しない）
* 日次判定は `timezone` に基づき**現在のローカル日付**が前回オープン時と変わった最初の `emit` で回転

### 3.3 ファイル名と採番

* 規約：`{baseName}-{YYYYMMDD}-{NN}.log`

  * 例：`app-20250817-01.log`（同日内で 01, 02...）
* `baseName` は `LogConfig.fileBaseName` に従う（既定 `'app'`）

### 3.4 回転手順（アトミック性）

1. 現在ファイルを **強制 `flush`**
2. **`close(current)`**
3. **`open(new)`**（新規ファイル作成）
4. **Retention** を実行（§4）

* いずれか失敗時：1回のみコンソール警告→`NoRotation` へフォールバックし継続

### 3.5 同時実行/多重起動

* 想定：単一プロセスでの利用。デスクトップの多重起動は非対応（将来ロックファイル導入余地）

---

## 4. 保持ポリシー仕様（Retention）

* `RetentionPolicy` 抽象：

  * `NoRetention`
  * `MaxFiles(int count = 7)`：対象拡張子（`.log`）のうち古い順に削除
  * `MaxDays(int days = 7)`：`mtime`（更新時刻）比較で削除
  * `CompositeRetention(List<RetentionPolicy>)`：**両方適用**
* **実行タイミング**：新ファイルオープン直後（回転ごと）
* **対象の列挙**：`fileBaseName` と拡張子一致、同一ディレクトリ

---

## 5. タグ別レベル/フィルタと動的設定

### 5.1 有効レベル判定

* しきい値 = `tagLevels[tag] ?? globalLevel`
* タグ未指定イベントは `globalLevel` のみで判定

### 5.2 実装（Interceptor）

```dart
class LevelFilterInterceptor implements Interceptor {
  final LogConfigHub _hub; // 原子的スナップショット読み出し
  @override
  LogEvent intercept(LogEvent e) {
    final cfg = _hub.snapshot; // イミュータブル
    final tagLevel = (e.tag != null) ? cfg.tagLevels[e.tag] : null;
    final threshold = tagLevel ?? cfg.globalLevel;
    return (e.level.index >= threshold.index) ? e : _DROP; // _DROP は内部的な無視指示
  }
}
```

* **注意**：`_DROP` は以降の B/C/E/F を実行しない内部表現

### 5.3 ランタイム更新（動的設定）

```dart
abstract class LogConfigHub {
  LogConfig get snapshot;                 // イミュータブル・スナップショット
  void update(void Function(LogConfigBuilder b) mutate); // 原子更新
}
```

* 公開メソッド例：`setGlobalLevel(LogLevel)`, `setTagLevel(String, LogLevel)`, `clearTagLevel(String)`
* 更新は **1 回の原子操作** とし、読取側はロック不要

---

## 6. コンテキスト API（相関情報）

### 6.1 目的

* 一連の操作（画面/リクエスト/セッション）に共通する識別子（`requestId` 等）を付与し検索性と相関分析を向上

### 6.2 API

```dart
typedef LogContext = Map<String, Object?>;

T runWithContext<T>(LogContext ctx, T Function() body, {bool merge = true});
```

* `merge=true`：親コンテキストに**上書きマージ**（デフォルト）
* `merge=false`：置換（親を破棄）
* 取得は Zone ベースで非同期境界を越えて伝播

### 6.3 規約

* 推奨キー：`requestId`（短いUUID）、`sessionId`、`screen`、`route`、`device`
* **PII**：`ctx` にも Phase 1 の PII マスキング（C 段）を適用
* ネスト例：

```dart
runWithContext({'requestId':'R1'}, () {
  i('start');
  runWithContext({'screen':'Home'}, () {
    i('tap'); // ctx: {requestId:R1, screen:Home}
  });
});
```

---

## 7. 遅延評価の厳密化（再確認）

* **A（レベル/タグ判定）** では `msg/fields` を**評価しない**
* **B** で `msgOrThunk` → `fieldsThunk` の順に **初めて** 評価
* **C** で直後に PII マスキング（`msg/fields/ctx/err/st`）
* 目的：不要な計算を避けつつ、出力前に常に PII を適用

---

## 8. 設定（追加/変更）

```dart
class LogConfig {
  // Phase 1 から継承
  LogLevel globalLevel;                  // debug: DEBUG, release: INFO
  Map<String, LogLevel> tagLevels;       // {}
  // ファイル
  String fileBaseName;                   // 'app'
  RotationPolicy rotation;               // default: DailyRotation('UTC')
  RetentionPolicy retention;             // default: MaxFiles(7)
  // コンテキスト/遅延
  bool enableContext;                    // true
  bool enableFieldsThunk;                // true
}
```

* 既定の動作：`DailyRotation(UTC)` + `MaxFiles(7)`、`enableContext=true`、`enableFieldsThunk=true`

---

## 9. 相互作用・優先順位ルール

* **パイプライン順序**：常に A→B→C→E→F（D は Phase 3 以降）
* **タグ競合**：`withTag('x')` と呼び出し引数 `tag:'y'` が同時指定された場合は **引数側優先**
* **日付切替**：`DailyRotation` は `emit` 時に判定（タイマー不要）
* **サイズ**：レコードの UTF-8 バイト長を算出し、閾値**到達前**にファイルを切替
* **保持**：ローテーション後に即時評価（削除の失敗は 1 回のみ警告）

---

## 10. 受け入れ基準（検証可能）

1. **ローテーション（日次/サイズ）**

* 23:59→00:00 の跨ぎで次レコードが新ファイルに書き込まれる
* サイズ上限（例：5MB）に達する**前**に新ファイルが作成され、旧ファイルは閾値以下

2. **保持**

* `MaxFiles(3)` で 4 本目作成時に最古が削除され合計 3 本に保たれる
* `MaxDays(2)` で 3 日前のファイルが回転直後に削除される

3. **タグ別レベル**

* `global=INFO`, `tagLevels['api']=DEBUG` のとき、`api` の `debug` は出力、`db` の `debug` は抑止

4. **動的更新**

* ランタイムで `setTagLevel('db', DEBUG)` を適用した直後のイベントから反映

5. **コンテキスト**

* `runWithContext({'requestId':'R1'})` 内の全ログに `ctx.requestId='R1'` が付与される
* ネスト時は `merge=true` で上書きマージ、`merge=false` で置換

6. **遅延評価厳密化**

* フィルタ不一致時には `msgThunk/fieldsThunk` が**未評価**である（カウンタで検証）

7. **後方互換**

* Phase 1 のコード/設定のままで挙動変化がない（既定値で上位互換）

---

## 11. テスト計画

* **単体**：

  * `DailyRotation/SizeRotation/CompositeRotation` の判定関数（境界値）
  * `MaxFiles/MaxDays/CompositeRetention` の削除順序
  * `LevelFilterInterceptor` のしきい値ロジック
  * Zone 伝播と `runWithContext` のマージ/置換
  * 遅延評価が A 不通過時に未評価であること
* **結合**：

  * 高頻度ログ（1000行）と回転/保持の相互作用（欠落/重複なし）
  * 動的設定の連続更新でデータ競合や Tear が発生しない（スナップショット設計）
* **E2E**：

  * 疑似日付跨ぎ（タイムゾーン差含む）でファイル名・採番が正しい
  * サイズ閾値境界での先読み回転（超過前ロール）

---

## 12. 非機能要件

* **性能**：ローテーション判定 O(1)、保持評価は O(n log n)（n=保持対象）。標準端末で 100 行/秒を目標。
* **信頼性**：回転手順は排他的で、境目イベントの欠落を許容しない（flush→close→open）。
* **セキュリティ/プライバシ**：`ctx` も PII マスキング対象。予約キーに生の PII を置かない運用指針を併記。
* **可観測性**：回転/保持の動作は `tag='logger'` のメタログ（info）で 1 行報告してもよい（任意）。

---

## 13. 依存・導入

* `path_provider`（保存先解決）
* 標準ライブラリ：`dart:io`, `dart:convert`
* Phase 1 の依存を継承。新規追加依存は不要。

---

## 14. 用語・規約

* **NDJSON**：1 行 1 JSON オブジェクト
* **A–F**：パイプライン段（A\:Filter, B\:Eval, C\:PII, D\:Rate/Overflow(Phase3), E\:Format, F\:Sink）
* **Rotation/Retention**：回転/保持。Composite は OR（回転）/ AND（保持）
