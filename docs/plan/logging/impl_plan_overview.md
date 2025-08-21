# ロギング実装計画概要

---

## ステップ0：基盤の土台（コード受け皿）

**作業**

* `packages/logger/` 新規作成（または `lib/logger/`）。
* 空の型だけ先に確定：`Logger`, `LogEvent`, `Interceptor`, `Formatter`, `Sink`, `LogConfig`, `LogConfigHub`。
* CI（dart analyze/test/format）とサンプル`example/`プロジェクト。

**成果物**

* 公開APIの型定義一式・CIパイプライン。

**受け入れ基準**

* 仕様に記載のAPIシグネチャと一致（差分テストで検知可能）。

---

## ステップ1：Phase 1 の最小垂直スライスを“差し込む”

**作業**

1. **パイプライン骨格**：A(レベル/タグ)→B(遅延評価)→C(PII)→E(フォーマット)→F(Sink)。
2. **ConsolePretty**（ANSI/絵文字フォールバック）。
3. **FileSink(NDJSON)**：flushポリシ（行数/時間）実装。
4. **PIIマスカー**：`InternetAddress.tryParse`優先、代表パターン同梱。
5. **非同期キュー**：`queueCapacity`＋`dropNew`。
6. **アプリ統合**：`main()`で`runZonedGuarded`ラップ、`withTag`導入、`print`呼び出し箇所の置換（最低限・外周から）。

**成果物**

* ライブラリ実装＋MVPへの初期統合PR。

**受け入れ基準**

* 同一イベントが**色付きConsole**と**NDJSONファイル**に出力。
* `msg/fields/ctx/err/st`へ**PIIマスク**適用。
* 100行/秒でUIの体感劣化なし（簡易計測ログ/目視）。

---

## ステップ2：Phase 2 の運用拡張（ローテ・保持・コンテキスト）

**作業**

1. **ローテーション**：`DailyRotation('UTC')`/`SizeRotation(maxBytes)`/Composite。サイズはUTF-8バイト長で超過前ロール。
2. **保持**：`MaxFiles/MaxDays`（ロール直後に適用）。
3. **コンテキストAPI**：`runWithContext`導入、`requestId/sessionId/screen`をMVPのエントリ/ルータで付与。
4. **動的レベル**：`LogConfigHub`の原子更新（`globalLevel/tagLevels`）。

**成果物**

* ログディレクトリに日次/サイズでローテされたファイル群。
* 主要ユースケースで`ctx.requestId`付与。

**受け入れ基準**

* 0:00跨ぎ/サイズ閾値境界で正しく新ファイルへ。
* `MaxFiles(n)`で常にn本以内。
* `api`タグに対する`DEBUG`レベルのオンオフが即時反映。

---

## ステップ3：Phase 3 の安全制御（例外・レート/サンプリング・バックプレッシャ）

**作業**

1. **未捕捉例外収集**：`FlutterError.onError`/`PlatformDispatcher.onError`/`runZonedGuarded`。30秒窓でデデュープ＋60秒サマリ。
2. **レート制限/サンプリング**：グローバル/タグ/タグ×レベル単位のトークンバケット、割合サンプル。
3. **バックプレッシャ**：`OverflowPolicy`（既定`dropNew`）と`LoggerStats`公開。
4. **呼び出し元情報**（任意・既定OFF）：`fields.src`追加（debug時のみON推奨）。

**成果物**

* 例外時に`fatal/error`ログ＋要約。キュー統計の取得API。

**受け入れ基準**

* 例外連打で詳細1回＋要約のみ。
* レート制限設定が通過件数とサマリに反映。
* バッファ溢れで`droppedSinceStart`が増加。

---

## ステップ4：Phase 4 の高度機能（暗号・リモート・OTA・Isolate）

**作業**

1. **保存時暗号化**：`.elog`（AES-256-GCM、DEK/KEK、初期IV＋96bitカウンタ、フレーム単位）。
2. **RemoteSink**：NDJSONバッチ＋gzip＋指数バックオフ、**Allow-list既定ON**、**TLSピンニング必須**、オフラインスプール（暗号化ONならスプールも暗号化）。
3. **OTA**：署名検証（Ed25519等）＋TLSピンニング、`LogConfigHub`へ原子反映、フェイルセーフ。
4. **Isolate化**：暗号/圧縮/IO/HTTPをロギングIsolateへ。メイン側はA判定のみ。

**成果物**

* `.elog`を復号ユーティリティでNDJSONに戻せる。
* オフライン→オンラインでFIFO送信が確認できる。

**受け入れ基準**

* 1byte改ざんで復号失敗を検知。
* サーキットブレーカがOpen→半開→Close遷移。
* Isolate ONで高負荷時のUIフレームドロップが減少。

---

## ステップ5：MVP側の“差し込みポイント”整理（並行）

**対象箇所**

* アプリ起動：`main()`で初期化＋`runZonedGuarded`。
* 画面遷移：ルータ/ナビゲーション層で`screen/route`を`runWithContext`。
* ネットワーク：HTTPクライアントラッパ（リクエスト/レスポンスの**要点のみ**Allow-listで`fields.http`へ）。
* データ層：主要ユースケースに`withTag('repo'/'api'/'ui')`でタグ統一。
* 既存`print`の段階的置換（外周→内側へ）。

**受け入れ基準**

* 検索性：`tag`と`ctx.requestId`で主要シナリオが追える。
* PII：ネットワーク/エラー文言にマスクが常に効いている。

---

## ステップ6：ドキュメント・運用ハンドブック

**作業**

* `ARCHITECTURE.md`（仕様の転載はcanvasを参照、運用手順/設定例を集約）。
* 運用Runbook：レベル切替、障害時の降格動作、ログ採取・復号、Remote/OTA鍵の更新手順。

**受け入れ基準**

* 新メンバーが半日で導入・運用手順を再現できる。

---

## リスクと対策（要点）

* **PII誤検知/漏れ**：Allow-list徹底＋`customPatterns`追加の運用手順を先に整備。
* **サイズ回転の境界**：UTF-8バイト長の“超過前ロール”をテストで固定。
* **モバイルI/O負荷**：Phase 4のIsolate化で吸収、前段はキュー設定で緩和。
* **リモート重複**：`eventId`でサーバ側排重前提を明記。
* **鍵管理（Win/Linux）**：`KeyProvider`の実装差で吸収、Passphrase方式をフォールバックに用意。

---

## 定義済みタグ/コンテキストの初期案（運用の足並みを揃える）

* **tags**：`ui`, `api`, `repo`, `db`, `auth`, `logger`(内部メタ)
* **ctx**：`requestId`, `sessionId`, `screen`, `route`, `device`

---

## 成果物の追跡（チェックリスト）

* [ ] API型・CI通過（Step0）
* [ ] Console/File/PII/非同期（Step1）
* [ ] ローテ/保持/ctx/動的レベル（Step2）
* [ ] 例外/レート/サンプリング/Stats（Step3）
* [ ] 暗号/Remote/OTA/Isolate（Step4）
* [ ] 差し込み完了（起動/ルータ/HTTP/print置換）（Step5）
* [ ] Runbook整備（Step6）
