# flutter analyze エラー修正計画（Contracts 分離フォロー）

作成日: 2025-09-15
状態: 提案（このドキュメントに沿って対応）
対象: 全レイヤー（特に app/wiring, features リポジトリ, infra アダプタ, batch）

## 目的と完了条件
- 目的: `flutter analyze` における error 級問題をゼロ化し、計画の受け入れ条件に適合。
- 完了条件:
  - analyzer のエラー（Severity: error）が 0 件
  - 主要経路のビルドが成功（最低限 debug ビルド）
  - アーキテクチャ整合（features → infra 直接参照なし）を維持

## 現状の所見（2025-09-15 時点）
- 直近の解析では「型エラー」は収束済み。info/warn は多数残存（方針次第で段階対応）。
- 過去エラーとして発生していた代表例と再発リスク:
  - 契約アダプタの未実装メンバー（例: LoggerContract の t/d/i/w/e/f）
  - 型の同名衝突（例: `OrderStockService` の重複定義）
  - Provider の公開型と実装の不一致（契約/具象の取り違い）
  - features → infra の直接 import（レイヤー違反に起因する型不整合）
  - Supabase 型の取り扱いの曖昧さ（dynamic キャストによる潜在的エラー）

## 方針（優先度順）
1) analyzer の error 級の除去に専念（最優先）
2) error 予備軍（危険な dynamic/曖昧な型）の型安全化
3) warn のうち意味の強いものを段階的に解消（unused import などノイズ削減）
4) info のスタイル項目（directives_ordering 等）は別チケットで一括整備

## 対応タスク（高粒度）
1. 契約アダプタの未実装メソッド網羅
2. Provider 型整合・同名クラス衝突の解消
3. features リポジトリの infra 参照撲滅（維持監視）
4. batch 実装の型安全化（Supabase クエリ戻り値の明示型）
5. 未使用 import/シンボルの整理
6. 解析/ビルド/簡易回帰の実施

## 実施ステップ（詳細）
- Step 1: アダプタ網羅性チェック
  - 対象: `lib/infra/logging/logger_adapter.dart` ほか契約 implements クラス
  - 施策: 契約シグネチャと差分比較し未実装メンバーを明示実装
  - 成果物: analyzer の abstract 未実装系エラーの解消

- Step 2: Provider/型整合の総点検
  - 対象: `lib/app/wiring/provider.dart`
  - 施策:
    - Provider の公開型＝契約型で統一
    - 同名クラスは import エイリアスで区別（例: `order_svc.OrderStockService`）
    - Repository ラッパー＋ `GenericCrudRepository<T>` の差し替えを再確認
  - 成果物: 型不一致・曖昧参照に起因するエラーの再発防止

- Step 3: features → infra 参照監視
  - コマンド: `rg -n "\\binfra/" lib/features`
  - 施策: ヒット 0 を維持。検出時はラッパー化 or Provider 合成へ置換
  - 成果物: レイヤー規約順守と将来の差し替え性確保

- Step 4: batch 型安全化
  - 対象: `lib/infra/batch/batch_processing_service.dart`
  - 施策:
    - Supabase クエリの戻り値を `final List<Map<String,dynamic>> rows = await query;` のように明示化
    - `PostgrestFilterBuilder<T>` のジェネリクス整備で不要な dynamic キャストを排除
    - 返却 `Map<String,dynamic>` のキー仕様を docstring に明記
  - 成果物: 将来の型崩れに対する堅牢性向上、潜在エラーの芽を摘む

- Step 5: unused import/シンボル整理
  - 対象: analyzer の `unused_import`/`dead_code`
  - 施策: 例）`lib/core/contracts/cache/cache.dart` の未使用 import を削除 等
  - 成果物: ノイズ削減、解析結果の可読性向上

- Step 6: 解析/ビルド/簡易回帰
  - 解析: `flutter analyze`（error 0 を確認）
  - ビルド: 主要ターゲット 1 つ以上（Android or Windows）
  - 回帰: ログ出力・簡易リポジトリ read の動作確認

## 変更影響とリスク
- 既存動作への影響: 型安全化や import 整理は基本的に非機能だが、batch の戻り値の型厳格化は呼び出し側に影響しうる
- リスク対策:
  - 段階実施（Step 4 は `breaking: false` で進め、インターフェース変更は避ける）
  - 影響範囲の広い修正は PR を分割

## スケジュール目安
- Step 1–3: 0.5 日
- Step 4: 0.5 日
- Step 5–6: 0.5 日

## 成果物/検証手順
- 成果物: 上記対象ファイル群の修正、`docs/intent/` への追記（必要に応じて）
- 検証:
  1) `tree -L 2 lib/infra lib/features` で参照構造を俯瞰
  2) `rg -n "\\binfra/" lib/features` で直接参照 0 を確認
  3) `flutter analyze` で error 0 を確認
  4) `flutter build`（プラットフォーム 1 つ）

## 付記
- info レベル（`directives_ordering` 等）のスタイル修正は別チケットで一括対応します（可読性向上の段階施策）。
