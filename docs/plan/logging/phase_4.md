# Flutter ロガー詳細仕様 Phase 4 v1.0（修正適用版）

> 目的：**セキュリティ（保存時暗号化）**、**運用高度化（リモート送信・リモート設定）**、\*\*性能隔離（Isolate 化）\*\*を追加し、Phase 1–3 の互換性の背骨（API/スキーマ/パイプライン）を維持する。破壊的変更は行わない。

---

## 0. 前提・適用範囲

* 対象：Flutter（Android / Windows / Linux）
* ランタイム：Dart（`dart:io` 利用可）
* 前提：Phase 1（Console/NDJSON・PII・非同期）、Phase 2（ローテ/保持・コンテキスト）、Phase 3（例外収集・レート/サンプリング・バックプレッシャ）が導入済み
* 非スコープ：外部 SIEM 連携のスキーマ個別最適化（将来検討）

---

## 1. 互換性の背骨（不変条件・再掲）

1. **公開 API 不変**：`t/d/i/w/e/f(...)`、`withTag(String)`、`runWithContext(...)`、`Logger.log(...)`
2. **イベントスキーマ**：固定キー `ts,lvl,tag,msg,fields,err,st,ctx,eventId`（自由拡張は `fields`）
3. **パイプライン順序（統一規約）**：

   * **A. レベル/タグ判定**（`msg/fields` 未評価）
   * **B. 遅延評価**（`msg` → `fields`）
   * **C. PII マスキング**（`msg/fields/ctx/err/st`）
   * **D. レート/サンプリング/バックプレッシャ**（Phase 3 で導入済み）
   * **E. フォーマット**（ConsolePretty / JsonLine / **Encrypted**）
   * **F. Sink 出力**（Console / File / **Remote**）
4. **シリアライズ可能性**：イベントは `String/num/bool/List/Map` のみ（Isolate 伝送互換）

---

## 2. 追加機能サマリ（Phase 4）

* **保存時暗号化**：AES-256-GCM によるレコード単位暗号化（エンベロープ方式、DEK/KEK）
* **リモート Sink（HTTP/APM）**：NDJSON バッチ送信、再送/オフラインスプール、サーキットブレーカ、Allow-list
* **リモート設定（OTA）**：署名検証必須、TLS ピンニング、原子反映、フェイルセーフ
* **Isolate 化**：暗号化・圧縮・I/O・HTTP をロギング専用 Isolate に隔離

---

## 3. 保存時暗号化（EncryptedWriter）

### 3.1 脅威モデルと方針

* 対象脅威：端末紛失やディスク抜き取りによる **ファイル単体**への不正アクセス
* 目的：**機密性**と**完全性**（改ざん検知）。プロセス内の正当アクセスは許容
* 方式：**エンベロープ暗号**（ファイルごと DEK、KEK で DEK をラップ）

### 3.2 暗号仕様（修正適用）

* アルゴリズム：**AES-256-GCM**
* ノンス：**DEK ごとの 96bit カウンタ方式**

  * ヘッダにランダムな **初期 IV（12B）** を `iv0` として記録
  * 各イベントで **big-endian 単調増加**（再利用禁止）
* 単位：**1イベント=1フレーム**を独立暗号化（追記耐性・破損の局所化）
* 圧縮：`gzip` → 暗号化（順序固定）
* 改ざん検知：GCM タグ（16B）で検証、失敗時はフレーム破棄＋エラー

### 3.3 ファイル形式（拡張子 `.elog`）

```
Header:
  magic: 4B "ELOG"
  ver  : u16 = 1
  header_len: u32
  header_json (UTF-8): {
    "alg":"AES-256-GCM",
    "kid":"<KEK id>",
    "edek":"<b64(DEK wrapped by KEK)>",
    "iv0":"<b64(initial 12B IV)>",
    "salt":"<b64(KDF salt, passphrase provider only)>",
    "created":"RFC3339",
    "compress":"none|gzip"
  }
Body (for each event):
  [ frame_len: u32 ][ nonce: 12B ][ ciphertext+tag: frame_len-12B ]
```

* 回転（Phase 2）時は **新 DEK** を生成（`edek/iv0` も更新）
* 復旧：ヘッダ破損時はファイル全体無効、ボディ破損時は該当フレームのみ無効

### 3.4 鍵管理（`KeyProvider`）

```dart
abstract class KeyProvider {
  Future<Uint8List> obtainKek({required String kid});
  Future<void> rotateKek({required String newKid});
  Future<void> revokeKek({required String kid});
}
```

* 実装例：

  * `PlatformKeyProvider`：OS セキュアストア（Android Keystore 等）
  * `PassphraseKeyProvider`：Argon2id/PBKDF2 により KEK 派生（パスフレーズは保存禁止）
  * `InMemoryEphemeralKeyProvider`：デバッグ用（プロセス終了で失効）
* ローテーション：新規 `.elog` は新 `kid` を使用。旧ファイルは旧 `kid` で復号可能
* 失敗時：暗号化エラーは 1 回警告し **FileSink を停止**（Console のみ継続）

### 3.5 設定

```dart
class EncryptionConfig {
  bool enabled;          // default: false
  String kid;            // default: "default"
  KeyProvider provider;  // required if enabled
  bool compress;         // default: false
}
```

### 3.6 復号ユーティリティ（任意）

* CLI 例：`elogcat --in app-20250817-01.elog --out app-20250817-01.ndjson`
* 動作：ヘッダ検証 → KEK 取得 → DEK 復号 → フレーム順次復号

---

## 4. リモート Sink（HTTP/APM）

### 4.1 送信モデル

* 形式：**NDJSON** バッチを HTTP POST
* 圧縮：`Content-Encoding: gzip`（既定 ON）
* 認証：`Bearer <token>` / API Key（**ログファイルに保存しない**）
* TLS：必須。**証明書/公開鍵ピンニング必須（修正適用）**

### 4.2 バッチング・再送

* バッチ確定条件：**イベント最大 100 件** または **64KB** 超
* 失敗時：指数バックオフ（初期 1s、倍々、最大 60s、ジッタ付）
* セマンティクス：**at-least-once**（重複は `eventId` によりサーバ側で排除）
* タイムアウト：接続/応答 10s（既定）

### 4.3 オフラインスプール（修正適用）

* 保存先：`remote-spool/` ディレクトリに NDJSON チャンク
* 上限：容量 50MB または 200 ファイル（古い順に削除）
* **暗号化 ON 時はスプールも暗号化**（同じ `EncryptionConfig`）
* 暗号化 OFF 時：OS 保護ディレクトリに限定
* 送信順序：FIFO。成功後に削除

### 4.4 サーキットブレーカ

* 直近 1 分の失敗率がしきい値超過 → **Open**（送信休止）
* 半開で試行し成功なら **Close**

### 4.5 Allow-list（修正適用：既定 ON）

* 送出前に安全なキーのみ残す。**既定セット**：`ts,lvl,msg,tag,eventId,ctx.requestId`
* 必要に応じて拡張（例：`fields.http.code` 等）

### 4.6 設定

```dart
class RemoteSinkConfig {
  Uri endpoint;                      // required
  Map<String,String> headers;        // e.g., {"Authorization":"Bearer ..."}
  bool gzip;                         // default: true
  int maxBatch;                      // default: 100
  int maxBatchBytes;                 // default: 64*1024
  int spoolMaxBytes;                 // default: 50*1024*1024
  int spoolMaxFiles;                 // default: 200
  bool certPinningEnabled;           // default: true
  List<String> allowedFields;        // default: 最小安全セット（上記）
}
```

---

## 5. リモート設定（OTA）

### 5.1 概要と要件

* 配信対象：`levels/tagLevels/sampling/rate/remote/encryption` 等の運用パラメータ
* 取得：起動後および間隔（既定 15 分）で `GET`
* **署名検証必須**（Ed25519 等）。公開鍵はアプリに埋込。**TLS ピンニング必須**
* スキーマ検証（JSON Schema）後、`LogConfigHub.update(...)` により **原子的に反映**
* フェイルセーフ：検証失敗・署名不正・TL S失敗は**適用拒否**し、最後に成功した設定を継続

### 5.2 ドキュメント例

```json
{
  "version": 4,
  "ttlSec": 3600,
  "signedAt": "2025-08-17T10:00:00Z",
  "levels": {"global": "INFO", "tags": {"api":"DEBUG"}},
  "sampling": {"ui:INFO": 50, "api:DEBUG": 10},
  "rate": {"global": {"cap":200, "refill":200}},
  "remoteSink": {"endpoint": "https://log.example/v1/ingest", "gzip": true},
  "encryption": {"enabled": true, "kid": "2025Q3"},
  "signature": "<base64>"
}
```

### 5.3 セーフガード

* `release` では `globalLevel` の下限を強制（例：`INFO` 未満に下げない）
* `ttlSec` 超過時は破棄または再取得
* 局所上書き（ローカル設定優先）も選択可能

---

## 6. Isolate 化（Logging Isolate）

### 6.1 目的と境界

* UI を保護するため、CPU/I O を要する処理（暗号・圧縮・ファイル・HTTP）を別 Isolate に隔離

### 6.2 アーキテクチャ

```
Main Isolate
  ├─ A: Level/Tag Filter（未評価）
  └─ [SendPort] ─────────────▶ Logging Isolate
                               ├─ B: 遅延評価（msg→fields）
                               ├─ C: PII マスキング
                               ├─ D: レート/サンプリング/バックプレッシャ
                               ├─ E: フォーマット（ConsolePretty/JsonLine/Encrypted）
                               └─ F: Sink（Console/File/Remote）
```

* 転送：`Map/List/primitive` のみ
* Stats：Logging 側で集計し、定期/要求ベースで返送
* 異常時：Logging Isolate の停止を検知したら **Console のみ**へ自動降格
* `flushAndClose()`：両 Isolate 協調で完了通知
* 既定：`release=true` / `debug=false`

---

## 7. 設定（Phase 4 追加）

```dart
class LogConfig {
  // Encryption
  EncryptionConfig encryption;            // §3

  // Remote sink
  RemoteSinkConfig? remote;               // §4（null=無効）

  // OTA
  Uri? remoteConfigUrl;                   // §5
  Duration remoteConfigInterval;          // default: 15min
  bool remoteConfigRequireSignature;      // default: true
  List<String> remoteConfigPubKeys;       // 信頼する公開鍵

  // Isolate
  bool useLoggingIsolate;                 // default: true (release), false (debug)
}
```

---

## 8. 相互作用・優先順位ルール

* **PII**：常に **C 段**（Isolate 内）で適用。Remote 送信・暗号化の前提
* **Allow-list**：Remote 送信直前に適用（ローカル保存には影響させない設定も可）
* **回転×暗号**：回転ごとに **新 DEK** を生成。Retention は拡張子ごと（`.elog` 対象）
* **レート×Remote**：レート/サンプリング後に残ったイベントのみ送信・スプール
* **フォールバック**：暗号/送信/Isolate の障害は段階的に File/Console へ降格。降格を 1 行のメタログで通知

---

## 9. 受け入れ基準（検証可能）

1. **暗号化**：`.elog` をツールで復号 → NDJSON と完全一致。1byte 改ざんで復号失敗
2. **鍵ローテーション**：`kid` 切替後の新規ファイルで新 `edek/iv0`。旧ファイルは旧鍵で復号可
3. **Remote**：オフラインでスプール → オンライン復帰で FIFO 送信、5xx で Open→半開→Close
4. **Allow-list**：既定セット以外のキーが送信されない
5. **OTA**：署名 OK で即時反映、署名 NG/TTL 超過は適用拒否
6. **Isolate**：高負荷（1,000 行/秒 + 暗号/送信）でも UI フレームドロップが有意に減少
7. **後方互換**：暗号/Remote/OTA/Isolate をすべて無効にすると Phase 1–3 と同一動作

---

## 10. テスト計画

* **単体**：

  * ノンスカウンタの単調増加・オーバーフロー境界
  * `KeyProvider`：生成/取得/ローテーション/失効
  * Allow-list のフィルタ適用
  * サーキットブレーカ遷移（Open/Half-Open/Close）
  * 署名検証・スキーマ検証の成功/失敗
* **結合**：

  * 暗号化×回転×保持の相互作用（欠落/重複なし）
  * オフラインスプール上限（容量/個数）と FIFO 送信
  * Isolate 停止時の自動降格と復帰
* **E2E**：

  * 実デバイスでの OTA 配信→署名検証→原子反映
  * 高負荷下の UI レイテンシ比較（Isolate ON/OFF）

---

## 11. 非機能要件

* **性能**：暗号+gzip で 0.3–0.8 ms/イベント（端末依存の目安）
* **信頼性**：送信は at-least-once、ファイルはフレーム完全性、障害時は段階的降格
* **セキュリティ**：KEK 平文保存禁止、Passphrase は KDF（Argon2id/PBKDF2）必須、TLS ピンニング＋署名検証
* **可観測性**：Encryption/Remote/OTA/Isolate の状態/統計を `LoggerStats` に反映（最後の送信結果、spool 使用量 等）

---

## 12. 依存

* 暗号：`package:cryptography` 等（高水準 API）
* セキュアストア：各 OS の安全な鍵保管機構
* HTTP：`http` または同等
* 既存：`path_provider`, `crypto`, `stack_trace`（任意）

---

## 13. 用語・規約

* **NDJSON**：1 行 1 JSON オブジェクト
* **DEK/KEK**：データ鍵 / キーカプセル化鍵
* **OTA**：Over-The-Air 設定配信
* **A–F**：パイプライン段（A\:Filter, B\:Eval, C\:PII, D\:Rate/Overflow, E\:Format, F\:Sink）
