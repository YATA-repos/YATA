---
title: "注文管理UIの税率同期改善計画"
status: "draft"
version: "0.1.0"
authors:
  - "GitHub Copilot"
created: "2025-10-12"
updated: "2025-10-12"
related_surveys:
  - "2025-10-12-tax-rate-application-survey"
scope:
  - "order"
  - "settings"
---

## 1. 現状サマリー
- `OrderManagementState` が税率 0.1 (10%) を固定値で保持しており、`SettingsService` からの更新を取得していない。
- `current_order_section.dart` の表示ラベルも "消費税 (10%)" にハードコードされ、UI表示と計算が一致しない。
- `OrderCalculationService` は `SettingsService.watch()` を通して税率更新を受け取っているため、バックエンド計算は最新税率を使用している。
- UI 表示・リアルタイム計算と最終会計結果が乖離する恐れがあり、設定変更が現場で即時反映されない。

## 2. 目的・ゴール
- 設定画面で更新された税率が注文管理 UI の状態および表示ラベルに即座に反映されること。
- 小計・税額・合計のリアルタイム計算が `OrderCalculationService` と同じ税率で行われること。
- 税率変更に関する回帰テストを追加し、UI とサービス層の整合性を検証できる状態にすること。

## 3. 実装タスク
### 3.1 状態管理と依存解決
- `lib/app/wiring/provider.dart` で `OrderManagementController` が `SettingsService` の watch ストリームを購読できるよう依存関係を整理する。
- `OrderManagementController` もしくは初期ロード用メソッドで `settingsService.current.taxRate` を現在値として受け取り、`OrderManagementState` へ反映させる。
- 税率変更通知を受けた際に `state = state.copyWith(taxRate: updatedRate)` を行い、`subtotal` など既存値は維持したまま再計算するフローを設計する。

### 3.2 UI 更新
- `OrderManagementState` のデフォルト値 0.1 を廃止し、必ず依存から供給された値で初期化する。
- `current_order_section.dart` の消費税ラベルを state の税率を用いた動的表記に変更し、パーセンテージ表示のフォーマットを共通化する。
- 小計→税額→合計の表示計算が state の `taxRate` を参照することを再確認し、必要であれば計算ロジックを共通関数へ切り出す。

### 3.3 サービス層との整合
- `OrderCalculationService` で利用するベース税率と UI state の税率が乖離しないよう、更新トリガー（watch の購読箇所）を同一箇所で扱う設計を検討する。
- カート更新処理 (`CartManagementService` 周辺) で税率を扱う必要があるか確認し、UI で即時計算する場合は `OrderCalculationService.calculateTaxAmount` を利用する。

### 3.4 テスト・検証
- `OrderManagementController` のユニットテストを追加し、税率変更イベントで state.taxRate と税額表示が更新されることを確認する。
- `current_order_section.dart` の widget テストを作成または更新し、異なる税率でラベルおよび金額が更新されることを検証する。
- 税率同期の回帰を防ぐため、設定変更後の注文確定フローを通した結合テスト（モックサービス利用）を検討する。

## 4. 影響範囲とリスク
- Riverpod の依存グラフに新たな watch を追加するため、リビルド頻度やパフォーマンスへの影響を確認する必要がある。
- 税率の丸め処理が UI とサービス層で統一されていない場合、表示と最終金額に差が出るリスクがある。
- 既存の `OrderManagementState` を利用する他 UI (サイドパネル等) にも税率の動的反映が伝播するため、副作用が発生しないか確認する。

## 5. マイルストーンと担当案
- スプリント内 Day 1: 状態管理・依存追加の実装とレビュー。
- Day 2: UI 更新と i18n 対応確認、表示確認 (手動テスト含む)。
- Day 3: テスト追加・更新、回帰確認、およびドキュメント整備 (`docs/survey` の更新要否判断)。
- Day 4: 総合レビュー、QA チェックリスト更新、リリースノート草案作成。

## 6. 未解決事項 / フォローアップ
- 設定画面側で税率表記を統一する際のフォーマット仕様定義 (例: 小数点以下桁数)。
- 軽減税率や複数税率への拡張を見据えたインターフェース設計（単一税率前提解除）の是非。
- バックエンド (Supabase) 側との金額整合テストを自動化するかどうかの判断。
