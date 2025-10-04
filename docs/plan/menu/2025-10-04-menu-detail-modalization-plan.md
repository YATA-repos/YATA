# メニュー詳細モーダル化計画（2025-10-04）

> **ステータス**: 実装完了（2025-10-04）

## 実装結果
- `MenuManagementPage` のサイドペインを排し、カテゴリペイン + テーブルの2カラム構成に再編したことで一覧領域を全幅で活用できるようになった。
- 詳細表示は常にモーダルとして起動するよう `_openDetailDialogIfNeeded` を刷新し、ダイアログの開閉タイミングをフレーム後に調停することでナビゲーション周りの競合を抑止した。
- `MenuDetailPanel` にモーダル向けのスクロール制御・Semantics 補強を追加し、アクセシビリティと操作導線を改善した。
- `MenuManagementController` の `openDetail` → `closeDetail` フローをカバーするユニットテストと、行タップでモーダルが起動し閉じる操作で状態がリセットされることを検証するウィジェットテストを追加した。

## テスト実績
- `flutter test test/features/menu/presentation/controllers/menu_management_controller_test.dart test/features/menu/presentation/pages/menu_management_page_test.dart`
- `flutter analyze`（既存の情報系警告のみ発生。新規エラーはなし）

## 背景
- TODOタスク「Menu-Enhancement-5」はメニュー管理画面のテーブルが詳細ペインに圧迫されている問題を解消し、詳細表示をモーダルへ移行することを目的としている。
- 現行の `MenuManagementPage` ではレイアウト幅が `1240px` 以上のときにサイドペイン（`MenuDetailPanel`）を常設し、それ未満のときのみ `showDialog` ベースのモーダルを表示している。このためPC表示ではテーブル幅が固定的に狭まり、横スクロールが多発している。
- `MenuItemTable` の操作カラム簡素化（Menu-Enhancement-7）など後続タスクは、詳細情報がモーダル側に集約されることを前提としており、本タスクでの構造移行が先行条件となる。

## スコープ
- 対象コード: `lib/features/menu/presentation/pages/menu_management_page.dart`, `lib/features/menu/presentation/widgets/menu_detail_panel.dart`, `lib/features/menu/presentation/widgets/menu_item_table.dart`
- 対象状態: `MenuManagementController`, `MenuManagementState` の詳細表示関連プロパティとイベントハンドラ
- 対象UX: メニュー一覧テーブルの表示領域、行選択導線、詳細モーダルの起動とクローズ操作、レスポンシブ挙動

## 現状整理
1. `LayoutBuilder` 内で `showDetailSide` 判定を行い、サイドペインを `Row` の3列目に挿入している。
2. 狭幅時のモーダル表示は `_maybeShowDetailDialog` で制御しており、`state.detail` が非nullかつ `_detailDialogOpen` フラグが立っていない場合に `Dialog` を生成する仕組みになっている。
3. 行タップは `MenuItemTable.onRowTap` から `MenuManagementController.openDetail` を呼び出し、非同期でレシピ・可用性を取得して `state.detail` をセットするフローになっている。
4. 詳細ペインの閉鎖は `MenuDetailPanel.onClose` から `MenuManagementController.closeDetail` を呼び出すが、サイドペイン常設時は `Navigator` を介さずローカルの `setState` だけで閉じている。
5. カテゴリパネル（幅260px）とサイドペイン（幅360px）が固定値で確保されるため、テーブルの表示カラム数が増えると横スクロールが必須になる。

## 目標（Success Criteria）
- サイドペインを排し、テーブル領域がカテゴリパネルの隣で残り幅全てを占有する。
- 行選択時は常に詳細モーダルが開き、`MenuDetailPanel` を再利用したコンテンツで詳細を表示する。
- モーダルはEscapeキー、閉じるボタン、モーダル外クリックのいずれでも閉じられ、閉鎖時に `MenuManagementController.closeDetail` が必ず呼ばれる。
- レイアウト変更後も幅1024px〜1440pxのレンジで主要カラムが折り返しなく閲覧できる。
- アクセシビリティ上の表記（Semanticsラベル、フォーカストラップ）が確保され、既存のショートカットやスクリーンリーダー挙動に回帰がない。

## 非スコープ
- モーダルUIのビジュアルリデザイン（色・タイポグラフィ・余白の再定義）。必要最小限の調整に留める。
- 詳細モーダル内の情報項目追加や編集フォームの刷新（別タスクで管理）。
- `MenuService` やバックエンドAPIの仕様変更。

## 関連タスク・依存関係
- `Menu-Enhancement-7`（操作カラムの販売状態トグル化）は本計画完了後に着手する前提。
- `UI/UX-Enhancement-5`（PC表示幅の最適化）は本変更と競合しないが、ブレークポイント調整が必要な場合は連携する。

## UX／インタラクション設計
- 行タップ: テーブル行全体のタップで即時にモーダルを開く。行内ボタンを押下した場合でもモーダルが二重起動しないよう、行単位の `onTap` を条件分岐して制御する。
- モーダル表示: `Navigator.of(context).push` 系ではなく `showDialog` を統一使用し、`MenuDetailPanel` に閉じるボタンとヘッダアクションを表示する。
- クローズ導線: `MenuDetailPanel.onClose` に加えて、`Dialog` の `barrierDismissible` を有効にし、バリアクリックやEscapeで閉じた際も `closeDetail` が呼ばれるよう `Navigator.pop` の `whenComplete` でハンドリングする。
- レスポンシブ: 幅768px未満では `Dialog` の最大幅を画面幅90%に縮小し、縦方向はスクロール可能にする。PCでは最大幅600pxを上限にし、テーブル側の視認性を優先する。

## UI実装方針
### レイアウト再構成
- `LayoutBuilder` から `showDetailSide` 判定とサイドペイン挿入ロジックを削除し、常に `Row` を「カテゴリペイン + Spacer + Expandedテーブル」の2カラム構成へ揃える。
- テーブル横の `SizedBox` 幅を `YataSpacingTokens.lg` に維持しつつ、余白計算が変わることで横幅が広がることを確認する。

### 詳細モーダル実装
- `_maybeShowDetailDialog` を `_openDetailDialogIfNeeded` に改称し、レイアウト幅に依存せず `state.detail` が更新されたタイミングで `Dialog` を開く処理に改修する。
- `_detailDialogOpen` フラグは継続利用するが、`Navigator.of(rootNavigator: true)` でモーダルを閉じられるようにする。
- `Dialog` コンテンツには `MenuDetailPanel` をそのまま使い、ヘッダのクローズアイコン押下で `Navigator.pop` を呼び出す。戻り後に `_controller.closeDetail()` を確実に実行する。
- `MenuDetailPanel` 側でモーダル向けのPaddingやスクロール制御が不足している場合は、追加コンテナ（`SingleChildScrollView` + `ConstrainedBox`）でラップする。

### 状態管理
- `MenuManagementController.openDetail` / `closeDetail` の挙動は据え置きつつ、モーダルクローズ時に `_detailDialogOpen` をリセットして `closeDetail` を呼べるようページ側で同期する。
- 連続で別行を選択した場合は、既存モーダルを `Navigator.pop` 後、`addPostFrameCallback` で再度 `showDialog` を呼び出し、閾値なく切り替えできるようにする。
- 将来のバック栄養（`Navigator.pop` で戻る操作）にも備え、`go_router` のルーティングは変更しない。`RouteAwareRefreshMixin` との互換性を確保する。

### レスポンシブ／アクセシビリティ
- `Dialog` の `insetPadding` を `horizontal: 24`（タブレット）/ `16`（モバイル）などブレークポイント別に設定する。
- `MenuDetailPanel` 内の主要見出しやアクションに `Semantics` 情報を入れ、スクリーンリーダーが「閉じる」「編集」などを識別できるようラベルを補強する。
- フォーカストラップを維持するため、`showDialog` の `barrierDismissible: true` と `useSafeArea: true` 組み合わせを確認し、モーダル内の最初と最後のフォーカス対象を `FocusTraversalGroup` でラップする。

## データフロー調整
- `MenuItemTable.onRowTap` → `MenuManagementController.openDetail` → `state.detail` 更新 → `MenuManagementPage` でモーダル表示 → `MenuDetailPanel` の操作コールバック → 必要に応じて `refreshAll` or 個別更新というストリームを維持する。
- モーダルクローズ時は `MenuManagementController.closeDetail` で `selectedMenuId` と `detail` をクリアし、ストアの整合性を確保する。

## 実装ステップ
1. **レイアウト整理**: `MenuManagementPage` の `LayoutBuilder` からサイドペイン分岐を除去し、カテゴリペイン＋テーブルの2カラム構造に更新する。
2. **モーダル制御ロジック改修**: `_maybeShowDetailDialog` を全幅で機能するよう調整し、`state.detail` の変更検知に合わせてモーダルを開くようにする。既存の `_detailDialogOpen` と `Navigator.pop` の同期も更新する。
3. **MenuDetailPanelのモーダル対応調整**: 必要であればクローズボタン配置やスクロール処理を改善し、モーダル専用のPadding・最大幅を設定する。
4. **アクセシビリティ＆レスポンシブ調整**: フォーカストラップ、Semantics、`insetPadding` の見直しを実施し、主要ブレークポイント（768px, 1024px, 1440px）で表示確認する。
5. **回帰テスト・手動チェック**: Flutter分析、既存ユニット／ウィジェットテスト、手動テストを実施し、テーブル操作とモーダル操作の回帰がないことを確認する。
6. **ドキュメント・TODO更新**: 実装完了後に `TODO.md` の該当項目を移動／更新し、関連タスク（Menu-Enhancement-7など）へ完了報告を連携する。

## テスト計画
- **ユニットテスト**
  - `MenuManagementController` の `openDetail` → `closeDetail` フローで `detail` が正しく設定・解除されること。
- **ウィジェットテスト**
  - `MenuManagementPage` をポンプし、行タップで `showDialog` が呼び出されることをモックして検証する。
  - モーダルクローズ操作で `closeDetail` がinvokedされることを確認する。
- **手動テスト**
  - PCブラウザ（1440px以上）でテーブルがフル幅になり、横スクロールが削減されていること。
  - タブレット（1024px想定）とモバイル（768px未満）でモーダルが画面外へはみ出さず、スクロールで情報へアクセスできること。
  - バリアクリック、閉じるボタン、Escapeキーでモーダルが閉じること。

## リスクと緩和策
| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| 既存の `_detailDialogOpen` フラグ管理と新しいモーダル制御が競合する | モーダルが開かない/閉じない | フラグ更新箇所を単一メソッドに集約し、`whenComplete` で常にリセットする。 |
| `Navigator.pop` が多重に呼ばれ、例外が発生する | UX低下・ログ汚染 | `Navigator.canPop` を確認し、`mounted` チェックと `rootNavigator` を統一する。 |
| 詳細モーダルのサイズが小さすぎる／大きすぎる | 情報が見切れる・空白が過多 | デザインガイドラインに従い、最大幅600px・最小幅320px・可変高さを設定しQAで調整する。 |
| 行選択とモーダル開閉の非同期タイムラグによる多重起動 | UIがちらつく | `state.detail` の更新前に既存モーダルを閉じ、`Future.microtask` で再オープンする制御を導入する。 |

## フォローアップ候補
- モーダルのタブ構造化（基本情報／レシピ／在庫など）により情報整理を行う。
- 行プレビュー内に在庫状況の簡易バッジを表示し、モーダルを開かずに主要情報を確認できるようにする。
- `MenuDetailPanel` を汎用ウィジェット化し、他画面（注文詳細など）でも再利用できるようにする。

## 参照
- 完了タスク: `Menu-Enhancement-5`（TODO.mdより削除済み）
- 関連ドキュメント: `docs/plan/2025-10-03-menu-management-page-implementation-plan.md`
- 既存実装: `lib/features/menu/presentation/pages/menu_management_page.dart`
