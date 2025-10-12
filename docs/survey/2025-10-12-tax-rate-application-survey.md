---
title: "注文画面における消費税率適用状況調査"
domain:
  - "order"
  - "settings"
status: "draft"
version: "0.1.0"
authors:
  - "GitHub Copilot"
created: "2025-10-12"
updated: "2025-10-12"
related_issues: []
related_prs: []
references:
  - lib/features/settings/services/settings_service.dart
  - lib/app/wiring/provider.dart
  - lib/features/order/services/order/order_calculation_service.dart
  - lib/features/order/presentation/controllers/order_management_state.dart
  - lib/features/order/presentation/widgets/order_management/current_order_section.dart
---

## 背景
設定画面で消費税率を変更しても、注文画面では税率 10% が表示され続け、計算結果も 10% 前提に見えるとの報告があった。設定値がどこまで反映されているかを確認し、原因候補を特定する。

## 目的
- 消費税率の設定値がどの層まで伝搬しているかを把握する。
- 注文画面で 10% 表示・計算になる理由を突き止める。
- 想定される影響範囲と対応方針を整理する。

## 調査方法
- `SettingsService` および関連 UI (`lib/features/settings/...`) の実装を確認。
- 注文計算系サービス (`OrderCalculationService` ほか) と依存関係を確認。
- 注文画面の StateNotifier と UI (`OrderManagementController` 系列) をコードリーディング。

## 調査結果
### 設定値の保存と配信
- `SettingsService` は `updateTaxRate` 実行時に `AppSettings` を更新し、`watch()` ストリームで変更をブロードキャストしている。
- `orderCalculationServiceProvider` では `settingsService.current.taxRate` を初期値に渡し、`settingsService.watch()` を購読して `OrderCalculationService.setBaseTaxRate` を随時呼び出している。→ サービス層では設定変更が即時反映される前提が整っている。

### 注文計算ロジック
- `OrderCalculationService` は内部に保持する `_taxRate` を使って `calculateOrderTotal`／`calculateTaxAmount` を計算する。`setBaseTaxRate` 経由で上記ストリームから更新されるため、ここでの税額計算は設定値に追従する。
- カート操作中 (`CartManagementService`) はアイテム小計の更新と `total_amount` の更新のみ実施し、税額は保持していない。チェックアウト時に `OrderCalculationService.calculateOrderTotal` を呼び、確定注文の `total_amount` に税額込みの値を反映している。

### 注文管理 UI の状態と表示
- `OrderManagementState` のコンストラクタは `taxRate = 0.1` をデフォルトに持ち、`loadInitialData` を含む全ての更新経路で `taxRate` を別値に更新していない。
- 税額表示 (`OrderManagementState.tax`) は `subtotal * taxRate` を丸めて算出するため、常に 10% で計算される。
- `current_order_section.dart` の表示ラベルもハードコードで `"消費税 (10%)"` となっており、UI 上の案内も固定値。
- その結果、設定画面で税率を変更しても注文画面の表示・リアルタイム計算は 10% のままとなる。一方で最終的な会計処理（バックエンド計算）は変更後の税率を使用する想定であり、UI 表示と確定値が乖離する可能性がある。

## 考察
- サービス層までは税率変更が連動しているが、注文管理 UI が設定ストアと連携していないことが主因と判断できる。
- UI 上の税額が 10% 固定で表示されるため、店舗スタッフは誤った金額を確認する恐れがある。特に軽減税率や独自税率を設定した場合に顕在化し、決済時に表示金額と請求金額が一致しないリスクがある。
- カート段階で DB に保存される `total_amount` は税抜相当であるものの、チェックアウト時に再計算されるため最終請求は設定値に基づく見込み。ただし UI 表示との乖離は利用体験上の問題となる。

## 推奨アクション
- `OrderManagementController` あるいは `OrderManagementState` に `SettingsService.watch()` などを介して税率を注入し、状態更新時に反映する。
- `current_order_section.dart` のラベルを動的に変更し、設定中の税率を表示する。
- UI 計算とバックエンド計算の結果が一致するかを自動テストで確認する（例: 税率変更後のサマリー表示と `OrderCalculationService` の戻り値比較）。
