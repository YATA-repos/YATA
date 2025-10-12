# 在庫注意アイテム UI 改善計画（2025-10-13）

在庫管理ページの「要確認の在庫」セクションに表示される `_AttentionInventoryTile`（注意/危険ステータスのアイテムカード）の視認性向上計画。情報が散在して“雑然”と見えている現状を整理し、ステータスの優先度を明示しつつ読み取りを高速化する。ドキュメント化の元資料は `docs/draft/inventory/thirdparty_ui_analyze_result.md`。

- **対象画面/コンポーネント**: `lib/features/inventory/presentation/pages/inventory_management_page.dart` 内 `_AttentionInventoryTile`
- **関連コンポーネント**: `YataStatusBadge`, `YataTag`, `YataColorTokens`, `YataSpacingTokens`
- **非機能制約**: Riverpod 状態管理構造は変更しない／在庫編集ダイアログ呼び出しは既存実装を維持
- **ステークホルダー**: 在庫管理ユーザー、UI/UX 担当、デザインシステム担当（Yata Design）

## 1. 背景と課題
- タイトル・カテゴリ・ステータス・在庫量が別々のブロックに散在し、視線往復が多い。
- バッジ/タグのベースラインが揃っておらず、リズムが崩れて“雑然感”を招いている。
- 状態（危険/注意）と在庫数が同じ強度で表示され、重要度の階層が不明瞭。
- パディング/行間が 8px グリッドから外れており、カード全体のバランスが悪化。

## 2. 目的
1. アイテム名→状態→在庫数の読み順を一貫させ、視認性を高める。
2. 状態を最重要情報として強調し、在庫数は補助情報として従属させる。
3. Yata Design トークンに沿った余白・タイポグラフィを適用し、画面全体の調和を取る。
4. 実装コストを抑えつつ、将来的にカードのバリエーション（ラベル左リボン等）へ拡張できる土台を用意する。

## 3. 成果物とアウトカム
- レイアウト再構成済みの `_AttentionInventoryTile` 実装（メタ情報右上集約パターンをベースラインに採用）。
- ステータス優先度に応じたバッジ/タグのカラーパレット・文言整理。
- 余白/ベースラインの調整および関連ユーティリティ（`YataStatusBadge`, `YataTag`）のプロパティ拡張が必要な場合の対応。
- 実装反映後の UI キャプチャまたは golden テストを用いた回帰防止策。

## 4. スコープ
### 4.1 対象
- `InventoryManagementPage` 内「要確認の在庫」セクションに表示されるカードコンポーネント。
- 状態バッジ・在庫タグの視覚表現、ラベル文言、レイアウト構造。
- スペーシング定義（トークン適用）およびカード全体の背景色/境界線の見直し。

### 4.2 非対象
- 在庫一覧テーブル・カテゴリペイン等、カード以外の UI。
- ステータス判定ロジック、在庫計算ロジックの変更。
- 在庫編集モーダル内の UI/UX 改善。
- サーバー連携・API スキーマの改修。

## 5. 利用者視点の期待値
- 危険/注意アイテムを開いた瞬間に状態がひと目で分かる。
- 在庫数量を確認するために視線がカード内を往復しない。
- どの情報が主・従かがひと目で判断でき、操作（タップ）への導線がすっきりする。

## 6. 改善方針（パターン選定）
### 6.1 ベースライン: メタ情報右上集約（ドラフト推奨パターン）
- 左カラム: タイトル（`titleMedium`）＋カテゴリ（`bodySmall`）。
- 右カラム: 上に在庫チップ、下に状態バッジを縦積み。どちらも `Alignment.topRight` で一塊にする。
- 状態: 彩度の高い赤/橙ピル + アイコン（`Icons.priority_high_outlined` 等）で最重要を明示。
- 在庫: 無彩色のアウトラインチップ。文言は簡潔に「在庫 7」のように表記。

### 6.2 拡張案: 左リボン/左ボーダー色
- カード左端に 4–8px のカラーストリップを追加し、ステータスをカード属性として示す。
- バッジは補助的に右上に寄せるか、タイトル横の小型ピルとして残す。
- コード構造はベースラインと共通化し、色帯はオプションパラメータで制御。初期実装では feature flag（`bool enableStatusAccent`）で無効化。

### 6.3 その他考慮
- 長い商品名・カテゴリでの折返し：タイトルは最大 2 行、カテゴリは 1 行に制限し、右カラムとの高さが崩れないよう `IntrinsicHeight` などを避ける。
- モバイル/デスクトップ両方での表示崩れ確認（`LayoutBuilder` で幅 320px〜600px と 1024px 以上を想定）。

## 7. ワークストリーム

| WS | 目的 | 主な変更 | 依存 |
| --- | --- | --- | --- |
| WS-A | レイアウト再構成 | 左右 2 カラム構成と右上集約の Column/Wrap 再配置 | 既存 `_AttentionInventoryTile` 実装 |
| WS-B | ビジュアル階層の整理 | バッジ/タグのカラーパレット・アイコン・文言整備 | WS-A |
| WS-C | デザインシステム連携 | トークン適用・オプション（左リボン）をデザインシステムへ問い合わせ/共有 | WS-A, WS-B |
| WS-D | 品質保証 | スナップショット（golden）/画面キャプチャ作成、QA チェックリスト整備 | WS-A〜C |

## 8. 詳細タスク

### WS-A: レイアウト再構成
1. `_AttentionInventoryTile` の `Wrap` を `Row` 左右構成に置き換え、`Expanded` 左、右は `Column` で `MainAxisSize.min` を指定。
2. 状態バッジ・在庫チップを `Column(crossAxisAlignment: CrossAxisAlignment.end, spacing: YataSpacingTokens.xxs)` で縦積みにする。
3. パディングを `EdgeInsets.symmetric(horizontal: YataSpacingTokens.lg, vertical: YataSpacingTokens.md)` へ調整し、8px グリッドに揃える。
4. タイトル・カテゴリのテキストスタイルを `textTheme.titleMedium.copyWith(fontWeight: FontWeight.w600)` と `bodySmall.copyWith(color: YataColorTokens.textSecondary)` で統一。

### WS-B: ビジュアル階層の整理
1. `YataStatusBadge` に危険/注意で共通アイコンを付与（必要なら `showIcon` フラグを追加）。
2. `YataTag` 表示時の背景色を無彩色（例: `YataColorTokens.neutral100`）に統一し、`foregroundColor` を `YataColorTokens.textPrimary` へ。
3. 在庫ラベルのテンプレートを `InventoryItemViewData` から組み立てるユーティリティ `InventoryCopyFormatter.stockLabel()` を新設し、文言ブレを防ぐ。
4. 余白トークン／ベースライン調整の確認。必要であれば `YataTag` の `height` 調整や `EdgeInsets` のオーバーライドを追加。

### WS-C: デザインシステム連携
1. 左リボン案のスタイルガイド化が可能か Yata Design 担当と確認。
2. 追加トークン（例: `YataColorTokens.alertDangerAccent`）の必要性を洗い出し、トークン追加の Pull Request 方針をまとめる。
3. 将来の在庫カード一覧（テーブル内カードなど）へ再利用できるよう、カードを独立コンポーネント化する是非を検討。

### WS-D: 品質保証
1. Golden テスト（`inventory_attention_tile_golden.dart`）を追加し、危険/注意ステータスの表示を固定化。
2. 手動 QA チェックリストを作成（モバイル/デスクトップ、長文テキスト、ダークモード）。
3. コントローラー経由で状態変更（`StockStatus.low/critical`）をトリガーし、UI が即時反映されることを再確認。
4. ドキュメント更新：`docs/guide/inventory/attention-items.md`（存在しない場合は作成）への反映 TODO を追加。

## 9. デザインガードレール
- **余白**: カード外余白 16px、要素間 8px、右カラム縦間隔 8px。
- **タイポ**: タイトル `titleMedium`（600）、カテゴリ `bodySmall`（400, secondary）、在庫チップ `labelSmall`、状態バッジ `labelSmall` + アイコン。
- **色**: 危険= `YataColorTokens.danger`, 注意= `YataColorTokens.warning`。在庫チップは `neutral100` 背景 + `textPrimary`。左リボン採用時は alpha 0.12 のサーフェス。
- **アイコン**: 状態は `Icons.error_outline` / `Icons.report_problem` など視認性の高いものを採用。色覚多様性対策として必ず文字ラベル付与。
- **文言**: `在庫 N`（半角スペース区切り）。タイトル補助テキストは最大 24 文字目で省略記号。

## 10. 検証計画
- `flutter test --tags=golden` で新規 Golden テストを実行し、UI 崩れを自動検知。
- スクリーンショット比較（Before/After）を Notion / Figma に添付してデザイナー確認を依頼。
- インタラクション確認：タップ時の波紋（InkWell）が維持されるか、アクセシビリティラベル（`Semantics`）が適切かを手動検証。

## 11. リスクと対応策
- **長文データで折返し崩れ**: Golden テストに 2 行タイトルケースを追加。
- **デザインシステムとの乖離**: トークン追加が必要になった場合、別途 design tokens 更新タスクを起票。
- **在庫チップの再利用影響**: 他画面で `YataTag` のカラーバリエーションを共有しているため、既存利用箇所への影響調査（`rg "YataTag(" lib/`）。必要なら専用スタイルを新設。

## 12. オープン課題 / 次フェーズ候補
- 左リボン案を正式採用するかどうかの意思決定（WS-Cで整理）。
- 注意在庫カードをリスト表示（非カード）に切り替える検討。
- メニュー管理ページのステータスカードとの統一 UI 指針策定。

## 13. 参考
- `docs/draft/inventory/thirdparty_ui_analyze_result.md`
- `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- `lib/shared/components/data_display/status_badge.dart`
- `lib/shared/components/data_display/tag.dart`
