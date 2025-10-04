# メニュー管理UI調整計画（2025-10-06）

## 目的
- メニュー管理ページの操作性と視認性を改善し、注文画面とのUI整合性を高める。
- メニュー登録フローで必要な情報を取りこぼさないよう、レシピ設定をモーダル内で完結させる。
- 実運用で利用されていない入力項目を排除し、メンテナンスコストを削減する。

## 対象範囲
- `lib/features/menu/presentation/pages/menu_management_page.dart`
- `lib/features/menu/presentation/widgets/menu_management_header.dart`
- `lib/features/menu/presentation/widgets/menu_category_panel.dart`
- 関連する共有コンポーネント（`lib/shared/components/inputs/segmented_filter.dart` など）

## 現状整理
- メニュー可用性フィルターのピル状ボタンは角丸が浅く、注文画面の支払い方法選択チップと視覚的な一貫性がない。
- メニュー追加モーダルは `AlertDialog` のデフォルト幅（約 320px）に制限されており、入力項目が縦に詰まり読みづらい。
- メニュー画像URL入力欄は現場運用で未使用のため、空欄のまま残り続けている。
- メニュー追加モーダルではレシピ（材料依存関係）の設定ができず、作成直後に別モーダルで再編集する必要がある。
- カテゴリペインの各タイルはベタ塗り背景で塗り潰されており、カード同士の区切りが弱く視覚的に重たい印象になっている。

## 改善方針

### 1. 可用性フィルターの完全ピル化
- 参照元: `OrderPaymentMethodSelector` の `_PaymentMethodChip`（`lib/features/order/presentation/widgets/order_payment_method_selector.dart`）。
- `YataSegmentedFilter` の角丸値を `YataRadiusTokens.pill` に切り替え、波紋範囲と背景塗りを合わせる。
- 選択状態・非選択状態のボーダーと背景色トークンを注文画面の実装と共通化し、チップの高さ／余白も揃える。
- 既存利用箇所への影響を確認し、必要であれば `compact` モード用のパディング調整も同時に見直す。

### 2. メニュー追加モーダルの横幅拡張
- `AlertDialog` ではなく、`Dialog` + `ConstrainedBox` で最大幅 560〜640px 程度のレイアウトを確保する。
- `SingleChildScrollView` 内のフォームを左右2カラム配置にリファクタリング（名称・カテゴリ・価格を左列、説明・レシピ設定を右列など）。
- スクロールを想定しつつ、上下余白を `YataSpacingTokens.lg` 基準に整える。
- 既存の `Form` バリデーション挙動は維持し、`Navigator.pop` 前の検証ロジックのみ再利用する。

### 3. メニュー画像項目の削除
- `MenuFormData` の `imageUrl` プロパティを削除し、サービス層（`MenuService.createMenuItem` / `updateMenuItem`）呼び出しからも除外する。
- 既存レコードで `image_url` が存在する場合に備え、表示側（`MenuDetailPanel` 等）で null 安全にフォールバックする。
- モーダルUIから `TextFormField(labelText: "画像URL")` を削除し、関連テスト（`menu_management_page_test.dart` 等）を更新する。
- 今後画像管理を復活させる場合に備え、ドキュメントに削除理由を記載しておく。
- 実装メモ(2025-10-06): 現場では画像URLが継続的に空欄のまま運用されていたため項目を除去。再導入時は画像ホスティング/キャッシュ戦略と共にフォーム項目を復活させること。

### 4. レシピ設定をモーダルに統合
- `MenuFormData` にレシピ入力用のサブモデル（例: `List<MenuRecipeDraft>`）を追加し、モーダルから依存材料を登録できるようにする。
- `_RecipeEditorDialog` にある UI パターン（材料選択、必要量、任意フラグ、メモ）をフォーム用に再構成し、追加／削除をモーダル内で完結させる。
- 材料候補は `MenuManagementController.loadMaterialOptions()` をダイアログ表示前にプリロードし、フォームビルダーに渡す。
- 送信時は `MenuService.upsertMenuRecipe` 相当のAPIをバッチ実行するワークフローを追加し、メニュー作成と同一トランザクションで完了させる。
- 既存の「メニュー詳細 > レシピ編集」導線は維持しつつ、モーダルで登録した初期レシピが表示にも反映されることを確認する。

### 5. カテゴリペインのカード分離表現
- `MenuCategoryPanel` の `_CategoryTile` で使用している `BoxDecoration` を、背景色を `YataColorTokens.neutral0` にしつつボーダー or シャドウで区切るスタイルへ変更。
- 選択状態はボーダー色強調（`YataColorTokens.primary`）と軽微なシャドウ（`BoxShadow`）を付与し、非選択時は `neutral200` ボーダーのみとする。
- 背景透過化に伴うテキストコントラストを再調整し、アクセシビリティを確保する。
- `YataSectionCard` とタイルの余白が重ならないよう、上下マージンを見直す。

## 実装ステップ案
1. 共有コンポーネント調整
   - `YataSegmentedFilter` の角丸／配色／パディングを更新し、既存利用箇所のスナップショットテストを更新。
2. モーダルUIのレイアウト再構築
   - メニュー追加・編集共通処理を `Dialog` ベースに置き換え、幅・2カラム構成を整える。
3. フォーム入力項目の整理
   - 画像URL項目削除に伴う `MenuFormData`／サービス／テストのシグネチャ更新。
4. レシピ設定統合
   - フォームデータモデル拡張・UI実装・`MenuManagementController` の送信処理実装。
   - メニュー作成→レシピ登録のAPI呼び出しシーケンスを整理し、エラーハンドリングを追加。
5. カテゴリタイルのスタイル改修
   - `_CategoryTile` の装飾差し替えと、テーマカラー微調整。
6. 回帰テスト
   - `menu_management_page_test.dart` と `menu_management_controller_test.dart` のケース更新。
   - 主要フロー（メニュー追加・カテゴリ選択・フィルタ切替）が想定どおり動作することをWidgetテストで検証。

## 想定影響・リスク
- 共有コンポーネントのスタイル変更が他画面に影響する可能性があるため、UI回帰確認を必須とする。
- レシピ設定をモーダルに取り込むことで、メニュー作成時のAPI呼び出し回数が増える。Supabase側のトランザクション or バッチ処理方針を確認する必要がある。
- 画像項目削除により、既存データの表示で null チェック漏れが顕在化する場合がある。

## テスト観点
- フィルタボタンの角丸スタイルが `YataRadiusTokens.pill` になっていることを Golden test またはスナップショットで確認。
- メニュー追加モーダルが横幅 560px 以上を確保し、表示崩れがないことを Golden test で担保。
- レシピ入力を含めたメニュー作成フローのWidgetテスト（材料追加→保存→一覧更新）。
- カテゴリタイルのボーダー／影スタイルが適用され、選択状態が視覚的に区別できることをゴールデンまたはビジュアルテストで確認。

## アウトカム
- 注文画面とUIトーンが揃った可用性フィルタを提供。
- モーダル内で必要情報が完結し、メニュー登録後の追加操作が不要になる。
- カテゴリ一覧の視認性が向上し、空間レイアウトが軽量化される。
- 不要な入力項目が排除され、フォームの保守性が向上する。
