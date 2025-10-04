# メニュー管理UI ギャップ分析（2025-10-03）

## 概要
- 対象: `lib/features/menu/presentation/pages/menu_management_page.dart` および同ウィジェット群
- 目的: 現行実装とモック（`_images/mocks/menu_management_page.png`）の差分を把握し、既存コンポーネントを活かした改善方針を整理する
- 前提: 新規UIコンポーネントを極力作らず、`shared/components` 直下の共通パーツとトークンを再利用する

## 差分サマリー
| 領域 | 現状 | モック | 観測された課題 |
| ---- | ---- | ---- | ---- |
| レイアウト | `MenuItemTable` と `MenuItemDetailPanel` を縦積み。詳細が常時表示されテーブルが圧縮 | テーブルを主役にし、詳細はサイドシート/モーダルへ退避 | テーブルの視認性と空間効率が悪い |
| テーブル構造 | Material準拠の密な行。トグルスイッチ・説明テキストなど要素が多い | 余白のあるフラットな行。チェックボックスによる一括選択が強調 | 情報過多で主要操作が埋もれている |
| カテゴリパネル | `YataStatusBadge`を多用し色数が多い。ドラッグハンドル/編集アイコンが常時表示 | 主要指標のみ色分け。カテゴリカードはシンプル | アテンションが分散し、操作がごちゃつく |
| ヘッダー | ステータスバッジとアクションがカード内に混在 | ヘッダー右肩に主要ボタン、上段に指標カード | 操作導線が分散している |
| ビジュアルトーン | `YataSectionCard`の枠線と影で重厚 | 淡い背景と薄いボーダーで軽やか | 画面全体が重く感じられる |

## 既存コンポーネント活用のヒント
- `YataDataTable`（`shared/components/data_display/data_table.dart`）
  - `onSelectAll` と `dataRowMinHeight`/`dataRowMaxHeight`を指定してチェックボックス列と余白を付与
  - `columnSpacing` 調整でモックに近い間隔を再現
- `YataSectionCard`（`shared/components/layout/section_card.dart`）
  - `backgroundColor` や `padding` を明るめに調整し、枠線を省略することでフラットなカードを表現
- `YataStatCard`（`shared/components/data_display/stat_card.dart`）
  - ヘッダー配下にメニュー数・提供可・要確認などの指標カードとして再利用可能
- `MenuItemDetailPanel` / `MenuCategoryPanel`
  - 中身を流用し、表示タイミング（サイドシート or ダイアログ）とボタン配置のみ調整すればOK
- 共通トークン類
  - `YataSpacingTokens`／`YataColorTokens`／`YataTypographyTokens` で余白・色味を統一し、システムから逸脱しない

## 改善方針
1. **レイアウト再構成**
   - 横幅960px以上では`MenuItemDetailPanel`を右側サイドシート（例: `AnimatedPositioned` + `SizedBox(width: 360)`)として表示
   - 狭幅時は行選択で`showDialog`にフォールバックし、通常状態はテーブル領域を全幅で利用

2. **テーブル整理 (`MenuItemTable`)**
   - 先頭列にチェックボックスを追加し、`MenuManagementController`に選択IDセットを保持（今後の一括操作に備える）
   - 「販売状態」スイッチは行右端のアイコンメニューに移し、ステータス表示は`YataStatusBadge`に一本化
   - 行高と列スペースを拡張し、更新日時は `MM/DD HH:mm` フォーマットに統一

3. **カテゴリパネルの簡素化 (`MenuCategoryPanel`)**
   - ステータスバッジを最大3種（総数・提供可・要確認）へ削減
   - 行右側の編集/削除は`PopupMenuButton`へ統合し、ドラッグハンドルはホバー時に`Opacity`で表示

4. **ヘッダー/サマリーの刷新**
   - `_PageHeader`内に`YataStatCard`を2〜3枚配置し、主要指標を視覚化
   - 「在庫再取得」「メニュー追加」はヘッダー右肩の`ButtonBar`にまとめ、カード本体から分離

5. **ビジュアルトーン調整**
   - `Scaffold.backgroundColor`を`YataColorTokens.neutral50`前後に変更
   - `YataSectionCard`の`backgroundColor`を`YataColorTokens.neutral0`、`border`を透過に設定し、影のみで区切る

## 推奨実装ステップ
1. レイアウト再構成 → 画面分割と詳細表示の導線変更
2. テーブルUIの刷新 → 列構成と行余白調整
3. カテゴリパネルのスタイル調整 → バッジ・アクションの整理
4. ヘッダーの強化 → 指標カードとボタン集約
5. 仕上げ → トーン調整と一括操作用のコントローラ拡張

## フォローアップ課題
- テーブル一括操作（削除/販売状態更新）の具体仕様詰め
- サイドシート表示時のアニメーションとアクセシビリティ（フォーカス管理）検討
- レスポンシブ閾値の再評価（タブレット横向きでの使い勝手確認）
