# flutter analyze 対応計画（2025-10-04）

## 背景
- `flutter analyze` を実行した結果、メニュー領域を中心に複数のエラーが検出された
- ビルド不能状態を解消し、後続の警告対応や機能追加に着手できる状態を回復させる必要がある

## 解析結果サマリ
| 優先度 | ファイル | 概要 | Lint ID |
| --- | --- | --- | --- |
| 高 | lib/features/menu/presentation/controllers/menu_management_state.dart | `MenuCategory` 等のモデルを解決できず、状態クラスがビルド不可 | `uri_does_not_exist`, `undefined_class` |
| 高 | lib/features/menu/presentation/controllers/menu_management_state.dart | `const` コンストラクタ内で `List.unmodifiable` を呼び出し定数式扱いにならない | `invalid_constant` |
| 高 | lib/features/menu/presentation/pages/menu_management_page.dart | `MenuRecipeDetail` 型未インポートによる型解決エラー | `non_type_as_type_argument`, `undefined_class` |
| 高 | lib/features/menu/presentation/widgets/menu_detail_panel.dart | `MenuRecipeDetail` 型未インポートによる型解決エラー | `undefined_class` |
| 中 | lib/features/menu/presentation/controllers/menu_management_controller.dart | Provider 呼び出しの冗長な既定値指定、型未指定 | `avoid_redundant_argument_values`, `always_specify_types` |
| 中 | lib/features/menu/presentation/controllers/menu_management_state.dart | constructor の並び順、不要インポート等のリント | `sort_constructors_first`, `depend_on_referenced_packages` |
| 中 | lib/features/menu/presentation/pages/menu_management_page.dart | フォーム初期値設定に非推奨 API を使用 | `deprecated_member_use` |
| 低 | その他 UI/テストコード | `_` 付き引数名、cascade 重複等のスタイル警告 | `unnecessary_underscores`, `cascade_invocations` ほか |

## 優先対応（クリティカル）
1. **モデル参照修正**
   - `menu_management_state.dart` の相対パスを正しい `../../models/menu_model.dart` に更新
   - `MenuCategory` を利用する箇所を再確認し、必要な DTO/モデルを明示インポート
2. **状態クラス初期化の再設計**
   - `MenuManagementState` から `const` を外すか、定数演算を使用せずにイミュータブルコレクションを生成
   - イミュータビリティを保つため、`UnmodifiableListView` 等の採用可否を検討
3. **DTO インポートの追加**
   - `menu_management_page.dart` と `menu_detail_panel.dart` に `menu_recipe_detail.dart` をインポートし、型エラーを解消

## 警告対応（フォローアップ）
- `menu_management_controller.dart` の冗長引数・型未指定の整理
- `depend_on_referenced_packages` 警告の原因を特定し、`pubspec.yaml` の依存追加またはコード修正
- `_` 引数のリネームや cascade 再利用などスタイル系リントの対応はクリティカル修正完了後に実施

## 作業手順（目安）
1. クリティカルエラー（E1〜E4）を順次修正
2. `flutter analyze` を再実行し、エラーが解消されたことを確認
3. 余裕があれば警告レベルのリント改善に着手

## 検証計画
- コマンド: `flutter analyze`
- 追加: メニュー管理画面のビルド確認、既存テストのスモーク実行（任意）

## リスクと留意点
- `const` 除去によるイミュータブル性低下 → 生成メソッドでの defensive copy を維持
- DTO 直接参照の増加 → 長期的には service 層でのラップ検討
- 依存追加の必要性 → `collection` パッケージの扱いをチームで合意
