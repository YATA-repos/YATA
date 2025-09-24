# 契約/実装 分離（DI統一・互換維持）— 実装意図メモ

作成日: 2025-09-15
状態: 実装反映済み（第一段）

## 背景/目的
- 計画書（`docs/plan/contracts/2025-09-15-contracts-separation-plan.md`）および引継ぎ資料（`docs/draft/contracts/handover.md`）に沿って、features 層が core の契約にのみ依存する形へ整理。
- まずは「サービスの依存注入を契約Providerに統一」することで、features → infra の直接依存を実務的に遮断し、移行の基盤を固める。

## 変更の要点（今回スコープ）
- Provider公開型を契約型に変更（`lib/app/wiring/provider.dart`）。
- Inventory/Order/Menu のサービスを、契約インスタンス注入で合成（具象 `new` を排除）。
- 在庫レベル判定の責務をサービス側へ移動（契約にない便宜メソッド依存を削減）。
- `InfraLoggerAdapter` を契約 `LoggerContract` に明示ブリッジ（ショートハンドも実装して解析エラーを解消）。
- Realtime は契約 `RealtimeManagerContract` を各サービスに注入して横断統一。

## 意図・判断理由
- アーキテクチャ標準（`docs/standards/architecture.md`）に合わせ、UI/Service → Contract → Implementation の直線依存に寄せる。
- 一括導入方針に基づき、まず「DIの公開点」と「サービス合成」を契約へ切り替えることで、アプリ全体の参照方向を強制的に矯正する。
- 互換維持の観点から、logging は既存トップレベルAPIを温存しつつ契約へ委譲（compat/adapter）。

## トレードオフ/代替案
- Repository実装の完全な `infra/` への移設は、モデル配置（core昇格の可否）と密接に絡むため本段では見送り。
  - 代替: 現状は features 配下に実装を残しつつ、外部公開は契約Provider経由に限定して実害を抑止。
- `core/constants/query_types.dart` の Supabase 依存は短期容認（計画書の改善メモに準拠）。
- Realtime の機能識別は一旦文字列のまま（型安全化は後続で `FeatureName` 的抽象を検討）。

## 現状の残タスク（次段）
- Auth の契約化（`AuthRepositoryContract` 新設 + Supabase 実装）。
- Repository 実装の配置再設計（モデルの所在方針を確定した上で `infra/` へ移設）。
- `query_types.dart` の純粋抽象化 + `infra` Adapter 導入。
- Realtime 機能識別の型安全化。

## 検証メモ
- `flutter analyze`: 型エラーは解消。既存のスタイルlintは残存（非機能、後回し）。
- features → infra 直接参照は、Repository実装およびAuth周辺に限定（サービス層からは排除済み）。

## 参照
- 計画: `docs/plan/contracts/2025-09-15-contracts-separation-plan.md`
- 引継ぎ: `docs/draft/contracts/handover.md`
- 標準: `docs/standards/architecture.md`, `docs/standards/documentation_guidelines.md`

