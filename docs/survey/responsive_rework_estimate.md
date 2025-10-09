# Windows/小画面対応に向けたレスポンシブ再設計 工数調査

- 作成日: 2025-10-09
- 作成者: GitHub Copilot
- 対象ブランチ: `dev`

## 1. 背景と目的
Windows 版で OS の DPI 設定を尊重した結果、Linux 版と比較して UI が拡大して見える現象が報告されている。OS 側のスケールを無効化するのではなく、アプリケーション側のレイアウトをレスポンシブ設計へ刷新し、画面幅やデバイス密度に応じて自然な表示を実現するための工数を見積もった。

本調査では、現状の Flutter 実装（`lib/` 配下）を対象に以下を確認した。

- グローバルなレイアウト基盤 (`YataPageContainer`, `YataSectionCard`, トップバー等)
- 主要画面（注文、注文状況、履歴、在庫、メニュー、分析、設定、認証）の構造とレイアウト手法
- レスポンシブ化を阻害する固定値（`maxWidth`, 固定パディング、横並び前提の `Row` 等）

## 2. 現状実装の主要所見
### 2.1 共通レイアウトコンポーネント
- `lib/shared/components/layout/page_container.dart` の `YataPageContainer` は `maxWidth = 1280` を固定し、余白 (`pagePadding = EdgeInsets.symmetric(horizontal: 24)`) も一定。幅の広い環境では中央寄せ、狭い環境では横スクロールが発生しやすい。
- `lib/shared/components/layout/section_card.dart` の `YataSectionCard` は `expandChild` を持つが、ヘッダー部や内包ウィジェットは横並び前提。モバイル幅での改行・折り返し処理が未実装。
- `lib/shared/patterns/navigation/app_top_bar.dart` の `YataAppTopBar` は常に横一列 `ListView` でナビゲーションを表示し、ドロワー／ハンバーガーなどの縮退 UI を持たない。

### 2.2 代表画面別の留意点
| 画面 | ファイル | 主な課題/観測結果 |
| --- | --- | --- |
| 注文管理 | `lib/features/order/presentation/pages/order_management_page.dart` | `YataPageContainer(scrollable: false)` 内で `Row` による二分割レイアウト。`MenuSelectionSection` は `LayoutBuilder` で列数を変えるが、右ペイン `CurrentOrderSection` との縦積み切替がない。|
| 注文状況 | `lib/features/order/presentation/pages/order_status_page.dart` | ステータスごとの `YataSectionCard` を横並びさせるロジックが多く、ウィジェット単位のブレークポイントが不足。|
| 注文履歴 | `lib/features/order/presentation/pages/order_history_page.dart` | テーブルライクな `Row`、ページネーション、詳細ダイアログがデスクトップ想定。狭い幅での再配置が未対応。|
| 在庫管理 | `lib/features/inventory/presentation/pages/inventory_management_page.dart` | `LayoutBuilder` で 1080px を境にサイドバー有無を切替。テーブル・ダイアログ含め、全体としてデスクトップ幅前提の固定余白が多い。|
| メニュー管理 | `lib/features/menu/presentation/pages/menu_management_page.dart` | 在庫管理と同等の構造。詳細パネルや検索結果が広いカード幅を前提に構築されている。|
| 売上分析 | `lib/features/analytics/presentation/pages/sales_analytics_page.dart` | `Wrap` や `Flex` を用いて一定のレスポンシブ性があるが、カード幅の下限や余白調整が不十分。|
| 設定 | `lib/features/settings/presentation/pages/settings_page.dart` | `YataSectionCard` を複数並べる固定レイアウト。フォーム群の縦積み最適化が必要。|
| 認証 | `lib/features/auth/presentation/pages/auth_page.dart` | 中央寄せの固定幅カード。小画面対応は容易。|

### 2.3 モーダル/ダイアログ類
在庫管理やメニュー管理ではダイアログ (`AlertDialog`) 内でフォームを提供しており、入力欄がデスクトップ幅前提のパディングになっている。モバイル相当の画面幅を想定した再調整が必要。

## 3. 想定タスクと工数見積り
下表は 1 人日 ≒ 8h を基準に、設計/実装/レビューをまとめた概算。**最適化対象となるコンポーネントの複雑度**と**変更影響範囲**を反映し、レンジ表示（Best/Most/Worst）で記載した。

| カテゴリ | タスク例 | Best (人日) | Most (人日) | Worst (人日) |
| --- | --- | --- | --- | --- |
| 基盤設計 | ブレークポイント整理、デザイン整合、検証デバイス定義 | 0.5 | 1.0 | 1.5 |
| 共通レイアウト更新 | `YataPageContainer` の柔軟化、`YataSectionCard` のヘッダー折返し、`SpacingTokens` の可変化 | 1.0 | 1.5 | 2.0 |
| ナビゲーション刷新 | `YataAppTopBar` の縮退 UI (ハンバーガー/ドロワー)、`YataNavItem` のモバイル対応 | 0.8 | 1.2 | 1.8 |
| 注文管理画面 | ペイン縦積み切替、`CurrentOrderSection` のテーブル→カード化、余白調整 | 2.0 | 2.8 | 3.5 |
| 注文状況画面 | ステータスカードのグリッド化、統計セクションの縦積み調整 | 0.8 | 1.2 | 1.8 |
| 注文履歴画面 | テーブルのレスポンシブ化、詳細ダイアログのレイアウト調整 | 1.2 | 1.6 | 2.2 |
| 在庫管理画面 | サイドバー縮退、テーブル/フィルタ/モーダルの再配置 | 1.8 | 2.4 | 3.2 |
| メニュー管理画面 | 在庫管理と同様の再配置、レシピ編集パネル対応 | 1.4 | 1.9 | 2.6 |
| 売上分析画面 | カード幅調整、チャートセクションの縦横切替整備 | 0.6 | 1.0 | 1.6 |
| 設定画面 | フォーム縦積み、カード幅最適化 | 0.4 | 0.6 | 1.0 |
| 認証画面 | 固定幅解除、フォント/余白の縮小対応 | 0.2 | 0.4 | 0.6 |
| モーダル/ダイアログ共通 | `AlertDialog` 内フォームのスクロール対応、ボタン配置調整 | 0.8 | 1.2 | 1.6 |
| QA・回帰テスト | Windows/Linux 双方での表示確認、主要動線チェック | 1.0 | 1.5 | 2.0 |
| バッファ | 不測の UI 崩れ、追加要件対応 | 1.0 | 1.5 | 2.0 |

**総計 (Most ケース): 約 18.8 人日**  
Best: ~13.6 人日 / Worst: ~26.8 人日

## 4. 前提とリスク
- デザイン指針・ブレークポイントは新規策定が必要。UI/UX 担当との協業が前提。
- データテーブル系（注文履歴、在庫、メニュー）はデスクトップ向け最適化が進んでおり、モバイルサイズでは表示すべき情報の取捨選択が必要になる。
- レスポンシブ化によるレイアウト再構成はテストコードが少ない領域であるため、リグレッションが発生しやすい。
- Flutter ウィジェットの再配置に伴い、パフォーマンス計測 (`OrderManagementTracer`) の再調整が発生する可能性がある。
- 追加でアクセシビリティ（タップ領域、フォント倍率）を考慮する場合、さらに +10〜20% の工数増を見込むべき。

## 5. 推奨進め方
1. **基盤整備フェーズ**: ブレークポイント、レイアウトユーティリティ、トップバー縮退 UI を先に対応し、各画面で再利用できる状態を作る。
2. **画面別改修フェーズ**: ページ重要度 (注文管理 → 在庫/メニュー → 注文履歴 → 注文状況 → 分析 → 設定/認証) に沿って段階的に対応。段階ごとに QA を挟みリグレッションを抑制する。
3. **QA フェーズ**: Windows (125%/150% DPI) と Linux (100%/125% 相当) での表示をダブルチェックし、端末ログやスクリーンショットでエビデンスを残す。
4. **デザインフィードバック**: 各段階で UI/UX チームにレビューを依頼し、余白・フォント・コンポーネント構成の調整を行う。

以上の分析より、レスポンシブ再設計の実装には 3〜4 週間程度（1 人体制想定）が必要となる見込みである。複数名での並行開発を行う場合は、共通基盤の整備完了後に画面単位でタスクを分割するのが効率的。