# Logger DI 移行計画 (2025-10-05)

## 背景
- features 層では依然として `core/logging/compat.dart` によるグローバル API 参照が残存しており、テストや差し替え時の柔軟性が制約されている。
- Riverpod で公開されている `loggerProvider` / `LoggerContract` を活用すれば、層ごと・環境ごとのロガー差し替えが容易になる。
- ロギング基盤の高度化（構造化フィールド、LogContext など）に備えるため、依存注入ベースの統一が必要。

## 目的
- Service/Repository/UI 各層で `LoggerContract` をコンストラクタ注入できる状態を整える。
- グローバル互換 API への依存を撤廃し、テストでロガーをモック・検証できる基盤を用意する。

## ゴール
- `lib/core/logging/compat.dart` の利用箇所が 0 件である。
- 各主要サービス/コントローラが `LoggerContract` を受け取り、内部で `log.<level>` を発行している。
- ユニットテストで `loggerProvider` を override して期待ログを検証できるサンプルが追加されている。

## スコープ外
- `LoggerContract` 自体のインターフェース変更。
- UI ウィジェット内での直接注入（Controller 経由の利用を想定）。

## 対応方針
1. **現状調査**
   - `rg "core/logging/compat" lib` を実行し、利用箇所一覧を整理。
   - 影響範囲を features 毎に分類し、優先順位と段階を決める。
2. **DI パスの確立**
   - Service 層: 既存のプロバイダ/ファクトリに `LoggerContract` を追加し、`InfraLoggerAdapter` を注入。
   - Infra 層: 既に DI 済みの箇所を確認し、必要に応じて `loggerProvider` の共有化を図る。
3. **互換 API の段階的廃止**
   - 各対応完了後に `compat` API を利用するファイルから import を削除。
   - 最終的に `compat.dart` を非推奨（@Deprecated）マークし、削除計画を別タスク化。
4. **テスト整備**
   - `test/support/logging/test_logger.dart`（仮称）で `FakeLogger` を提供。
   - 代表サービスのテストで注入→期待ログ検証を行い、利用例を明文化。

## 作業手順
1. 調査結果を `docs/plan/logging/impl_plan_overview.md` に追記し、対象リストを共有。
2. Service 層（メニュー、注文、在庫）の `Provider` を改修し、`LoggerContract` を必須依存として注入。
3. Repository / Infra 層で同様に注入パスを確認し、必要ならコンストラクタ引数を追加。
4. `compat` API 呼び出しを削除し、置き換え後に `dart fix` / `flutter analyze` で回帰確認。
5. `FakeLogger` とユニットテストサンプルを追加し、`README` やガイドにリンク。
6. `compat.dart` に `@Deprecated('Use LoggerContract via DI')` を付与し、削除期限を TODO コメントで明記。

## 実施状況メモ (2025-10-05)
- Service / Repository 層からの `core/logging/compat.dart` 依存を全廃。
- `loggerProvider` 経由の Riverpod DI に統一し、`OrderCalculationService` テストで override + ログ検証例を追加。
- `FakeLogger` を `test/support/logging/fake_logger.dart` として整備。
- `compat.dart` を `@Deprecated` 化し、11月以降での削除予定を TODO コメントで明示。

## 検証計画
- `flutter analyze` で型エラー/未使用 import を確認。
- 代表的なサービステスト（例: `menu_service_test.dart`）で `FakeLogger` を注入し、ログ検証が通ることを確認。
- 実機/エミュレータでアプリ起動し、主要フローのログが出力されることを目視確認。

## リスク / 留意事項
- DI 追加に伴いコンストラクタ引数が増え、既存テストが壊れる可能性 → 先にテストの依存調整を計画。
- `LoggerContract` のライフサイクルに関わる差分（シングルトン前提）を維持する必要あり。
- `compat` API を利用するサードパーティ連携コードが存在する場合は移行手順を別途定義。

## 成功指標
- CI で `compat.dart` の import が検出されない。
- 少なくとも 1 つのユニットテストが `LoggerContract` のモックを利用してログ内容を検証している。
- レビュー観点として DI 注入のテンプレートがドキュメント化され、コードレビューで再利用されている。
