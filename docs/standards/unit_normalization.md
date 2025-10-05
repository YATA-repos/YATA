# 単位定義の正規化ガイドライン

本ガイドでは、在庫・原材料管理における単位の取り扱い方針、丸めルール、UI入力・表示の統一ルールを定義します。

## 対象と目的
- 在庫数量、閾値（警告/危険）、調整量の一貫した扱い
- UI/UXの一貫性（表示桁数・入力ステップ・最小/最大値）
- バックエンド/APIとの整合性

## 単位と記号
- piece: 個数（記号: 個）
- gram: グラム（記号: g）
- kilogram: キログラム（記号: kg）
- liter: リットル（記号: L）

将来追加: 長さ、袋/箱などの包装単位、その他。

## 既定設定（UnitSettings）
- piece: step=1, decimals=0, min=0, rounding=round
- gram: step=10, decimals=0, min=0, rounding=round
- kilogram: step=0.1, decimals=1, min=0, rounding=round
- liter: step=0.1, decimals=1, min=0, rounding=round

これらは `UnitConfig.defaults` に定義。必要に応じてマスタ設定で上書き可能とする。

## 丸めルール
- rounding: round | ceil | floor
- 表示・保存前に `UnitFormatter.roundValue(value, unit)` を適用

## フォーマット/検証の使用法
- 表示: `UnitFormatter.format(value, unit)`
- クランプ: `UnitFormatter.clamp(value, unit)`
- 小数桁: `UnitConfig.get(unit).decimals`
- 入力ステップ: `UnitConfig.get(unit).step`

## UI適用箇所
- 在庫一覧: 閾値表示・新在庫表示のフォーマット（実装済み）
- ステッパー/直接入力: 単位の step/decimals に準拠（今後拡張）
- バリデーション: min/max/丸めの適用

## データモデル連携
- `Material.unitType` を真とし、画面上の表示記号は `UnitType.symbol` から生成
- 既存の `InventoryItemViewData.unit` は暫定互換（記号→UnitType変換で吸収）。今後、`unitType` を直接持たせる変更を検討

## API/保存
- サーバ保存時は内部表現（例えば gram を基本に統一）か `unitType` を明示保存
- バッチ更新時も `unitType` に従い丸めを行う

## テスト観点
- 単位ごとの丸め/表示桁/クランプが期待通り
- piece で小数入力→整数に丸め
- kilogram/liter の端数入力→小数1桁に丸め
- min 未満の入力→ min にクランプ

---
関連: `lib/shared/utils/unit_config.dart`, `lib/core/constants/enums.dart`, `docs/plan/inventory/2025-09-25-inventory-management-ui-improvement.md`