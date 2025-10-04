# メニュー機能 静的解析エラー調査メモ

## 概要
- 解析実施コマンド: `flutter analyze`
- 実行日時: 2025-10-04 08:43:20 JST（ローカル環境）
- 主な対象領域: `lib/features/menu/presentation` 配下の状態・画面・ウィジェット

## エラー詳細

### 1. `MenuManagementState` での相対パス誤り
- 発生箇所: `lib/features/menu/presentation/controllers/menu_management_state.dart:3`
- 症状: `Target of URI doesn't exist` により `MenuCategory` などモデル定義が解決できず、派生して `MenuCategory` 未定義エラーが発生
- 原因: `../../../models/menu_model.dart` というパスが1階層多く遡っており、実ファイル位置 `lib/features/menu/models/menu_model.dart` を参照できていない
- 対応案:
  - インポートを `../../models/menu_model.dart` に修正する
  - 併せて `MenuCategory` などモデル型が解決され、二次エラー（`undefined_class`）も解消される見込み

### 2. `MenuManagementState` の `const` コンストラクタに対する `invalid_constant`
- 発生箇所: `lib/features/menu/presentation/controllers/menu_management_state.dart:252-254`
- 症状: `List.unmodifiable` / `Set.unmodifiable` 呼び出しが `const` コンテキストに置かれているため `invalid_constant` が発生
- 原因: `const` コンストラクタ内で非 `const` ファクトリメソッドを実行している
- 対応案:
  - `const MenuManagementState` を通常コンストラクタに変更する（`const` キーワードを削除）
  - もしくは `UnmodifiableListView` など `const` 互換の仕組みに切り替える（ただし `collection` 依存関係の整理が必要）
  - 初期生成ファクトリ `MenuManagementState.initial()` 像への影響を確認し、パフォーマンス影響が許容範囲か評価する

### 3. `MenuRecipeDetail` の未解決型エラー
- 発生箇所:
  - `lib/features/menu/presentation/pages/menu_management_page.dart:547, 575`
  - `lib/features/menu/presentation/widgets/menu_detail_panel.dart:121`
- 症状: `MenuRecipeDetail` を型引数として使用しているが型が解決できず `non_type_as_type_argument` / `undefined_class` が発生
- 原因: 各ファイルで `lib/features/menu/dto/menu_recipe_detail.dart` をインポートしていない
- 対応案:
  - 上記 DTO を明示的にインポートする
  - あるいは `MenuDetailViewData` 側で公開用の型エイリアスを用意するなど、参照元が DTO に直接依存しない構成を検討する

## その他の気付き
- `package:collection` の直接インポートが `depend_on_referenced_packages` lint を誘発している。`pubspec.yaml` の `dependencies` に `collection` を追加するか、`dart:collection` ベースの実装に置き換える必要がある（優先度は低めだが、上記対応案2の検討と合わせて整理すると良い）。
- `flutter analyze` には警告および情報レベルの指摘も複数含まれる。今回のエラー修正後に改めて lint 全体をスキャンし、優先度順に解消していくことを推奨。
