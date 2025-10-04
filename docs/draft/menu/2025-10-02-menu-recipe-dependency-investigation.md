# メニュー⇔レシピ⇔材料 連動不全 調査レポート（2025-10-02）

## 概要
本来、メニュー（`MenuItem`）→レシピ（`Recipe`）→材料（`Material`）の依存関係を通じて、在庫可用性判定や注文時の在庫増減が連動する想定だった。しかし実際には、レシピ情報が存在しないことが常態化しており、結果としてメニューと材料が疎結合のまま稼働している。本レポートでは調査対象コードと挙動を確認し、依存関係が機能しない理由を整理した。

## 調査範囲
- メニュー機能: `lib/features/menu/models/menu_model.dart`、`lib/features/menu/services/menu_service.dart`
- 在庫機能: `lib/features/inventory/models/inventory_model.dart`、`lib/features/inventory/repositories/recipe_repository.dart`
- 注文機能: `lib/features/order/services/order_management_service.dart`、`lib/features/order/services/order_stock_service.dart`
- 既存計画ドキュメント: `docs/plan/2025-09-27-menu-material-dependency-plan.md`

## 主な所見

### 1. レシピ CRUD の実装が欠落
- コード全体を探索したが、`RecipeRepositoryContract` を用いた `create` / `update` / `delete` 呼び出しは存在しない（`ripgrep: _recipeRepository.create` 等でヒットなし）。
- `lib/features/menu/services/menu_service.dart` や `lib/features/menu/presentation` 配下にも、材料依存関係を編集・保存する処理は実装されていない。
- 既存ドキュメントにも「レシピ CRUD は未実装で外部ツールに依存」と明記されており（`docs/plan/2025-09-27-menu-material-dependency-plan.md`）、想定機能が実装段階へ進んでいないことが確認できた。

### 2. レシピ未登録時は在庫可用性が常に「提供可」扱い
- `MenuService._buildAvailabilityForEnabledItem`（`lib/features/menu/services/menu_service.dart:864-906`）では、レシピ一覧が空の場合に `isAvailable: true` として早期リターンしている。結果として、レシピが存在しなくても在庫不足と判定されない。
- 同メソッドは本来、レシピ情報から不足材料を抽出し、`missingMaterials` や `estimatedServings` を算出して UI に伝えるが、レシピ欠如により常に空となる。

### 3. 注文時の在庫増減もレシピ空振りでスキップ
- 注文確定フロー（`OrderManagementService.checkoutCart` → `OrderStockService.consumeMaterialsForOrder`）では、注文アイテムのレシピを `RecipeRepository.findByMenuItemId` で取得し、必要材料の消費量を計算する（`lib/features/order/services/order_management_service.dart:64-120` → `lib/features/order/services/order_stock_service.dart:54-90`）。
- しかしレシピが空のため、材料消費は発生せず、在庫は減らない。
- キャンセル時復元（`restoreMaterialsFromOrder`）でも同様にレシピが無いため何も戻されない（`lib/features/order/services/order_stock_service.dart:92-134`）。

### 4. 実装ギャップの背景
- 2025-09-27 付の計画ドキュメントでは、レシピ管理 UI/サービスの追加方針がまとめられているが、ソースコードには未反映。
- そのため「レシピを定義する手段がアプリ内に無い → レシピテーブルが空 → 依存関係が働かない」という構造的欠陥が残存している。

## 影響範囲
- メニュー管理画面で表示される在庫可用性（欠品バッジなど）が実在庫と乖離する。
- 注文確定時に材料在庫が減らず、在庫残量が常に実在より多く見積もられる。
- 在庫が減らないため、発注提案やアラート機能にも連鎖的な誤差が生じる可能性が高い。

## 補足・参考
- 既存の改善計画（`docs/plan/2025-09-27-menu-material-dependency-plan.md`）では、DTO 追加や `MenuService` のレシピ CRUD 拡張、UI 実装が提案済み。今回の調査結果は同計画の必要性を裏付けるものであり、計画に沿った実装が急務。
- レシピ初期データ投入・移行、材料マスタ整備も平行して進める必要がある。
