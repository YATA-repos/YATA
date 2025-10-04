# メニュー機能 静的解析エラー修正計画（2025-10-04）

## 背景
- `flutter analyze` にてメニュー管理領域で複数のエラーが検出された
- 現状は UI 層のビルドが不可能であり、他機能の連鎖的な検証も阻害されている
- 早期にメニュー関連の基盤コードを安定させ、警告レベル以下のリント改善に着手できる状態を整える

## 対象エラー
| ID | ファイル | 概要 | リントID |
| --- | --- | --- | --- |
| E1 | `lib/features/menu/presentation/controllers/menu_management_state.dart` | モデルの相対パス誤りにより `MenuCategory` などが解決不可 | `uri_does_not_exist`, `undefined_class` |
| E2 | `lib/features/menu/presentation/controllers/menu_management_state.dart` | `const` コンストラクタ内で `List.unmodifiable` を呼び出し `invalid_constant` | `invalid_constant` |
| E3 | `lib/features/menu/presentation/pages/menu_management_page.dart` | `MenuRecipeDetail` 未インポートで型解決不可 | `non_type_as_type_argument`, `undefined_class` |
| E4 | `lib/features/menu/presentation/widgets/menu_detail_panel.dart` | `MenuRecipeDetail` 未インポートで型解決不可 | `undefined_class` |

## 対応方針
1. **インポート整理（E1, E3, E4）**
   - `menu_management_state.dart` の相対パスを `../../models/menu_model.dart` に修正
   - ページ／ウィジェットから `lib/features/menu/dto/menu_recipe_detail.dart` を直接インポート
   - 依存方向の整理が必要な場合はコントローラ層に Facade を設ける案も検討（長期対応）
2. **状態クラス初期化の見直し（E2）**
   - `MenuManagementState` のコンストラクタから `const` を外し、`List.unmodifiable` / `Set.unmodifiable` 呼び出しを許容
   - 代替として `UnmodifiableListView` / `UnmodifiableSetView` を採用する場合に備え、`collection` 依存関係の pubspec 追加方針を整理
   - 初期化ファクトリおよびテストコードの差分影響をレビュー
3. **回帰テスト**
   - 修正後に `flutter analyze` を再実行し、エラー解消を確認
   - 必要に応じてメニュー画面のビルドテスト・主要インタラクションのハンドテストを実施

## 影響範囲
- メニュー管理画面（状態・UI）
- 依存 DTO (`MenuRecipeDetail`) およびモデル (`MenuCategory` など)
- Riverpod プロバイダで `MenuManagementState.initial()` を利用している箇所

## リスクと対応
- `const` 解除によるデフォルトイミュータビリティ低下 → 影響範囲テストとコードレビューで担保
- DTO 直接参照が増えることによる層間依存の肥大化 → 長期的には controller 層でのラップ案を検討

## 作業順序（想定）
1. 相対パス修正と DTO インポート追加
2. `MenuManagementState` のコンストラクタ調整
3. `flutter analyze` で再検証し、残件が無いか確認
4. 必要であれば `collection` 依存追加など補完タスクを起票

## 検証計画
- コマンド: `flutter analyze`
- 追加検証（任意）: メニュー管理画面の手動動作確認、関連ユニットテスト

## オープン課題
- `collection` パッケージの依存宣言の扱い
- `MenuDetailViewData` 側での DTO ラップ導入の是非
