---
title: "Windows UI スケーリング調整 — 実装意図"
domain:
  - "shared"
  - "app"
status: "draft"
version: "0.1.0"
authors:
  - "Codex Agent"
created: "2025-10-18"
updated: "2025-10-18"
related_issues: []
related_prs: []
references:
  - docs/draft/windows_ui_scaling_analysis.md
  - docs/plan/2025-10-18-windows-ui-scaling-normalization-plan.md
  - docs/survey/windows_dpi_measurements.md
---

## 背景
- Windows ランナーは Per Monitor V2 の DPI 情報を反映してウィンドウサイズを調整しており、Linux 版よりも UI が拡大して見えるケースが報告された。
- Flutter アプリ側ではプラットフォーム別の補正を実装していないため、Windows の表示スケール設定に依存して画面密度が大きく変動する。
- Linux とレイアウトを揃えたい要望に応えるため、OS 側のスケーリングを尊重しつつ、アプリ側で論理密度を調整する指針を採用する。

## 目的と方針
- `LOG_DPI_INFO` フラグによる初期メトリクスの採取 → 補正係数の設計 → MediaQuery/Theme の適用の順で進め、OS ごとの差異を可視化しながら調整する。
- ランナー側のスケーリング無効化は高 DPI のボヤけを招くため非採用。アプリ層で密度補正を行い、DPI 情報を保持したまま UI の見た目を標準化する。
- 将来的に macOS や Linux HiDPI へ拡張できるスケーリング抽象を `shared/foundations` に配置し、プラットフォーム別の調整ロジックを再利用可能とする。

## 現状ステータス（2025-10-18）
- `lib/main.dart` に `LOG_DPI_INFO` フラグが導入され、起動直後に `dpi_probe` タグでデバイスメトリクスを出力できる。
- 計測結果を記録するテンプレート（`docs/survey/windows_dpi_measurements.md`）を用意し、ログ/スクリーンショット/差分メモを整理する準備を整えた。
- 具体的な補正係数や UI アップデートは未着手。Windows 実機での計測およびログ収集が次のアクション。

## 次のステップ
1. Windows 100% / 125% / 150% で `LOG_DPI_INFO` ログを取得し、スクリーンショットと合わせてサーベイに追記。
2. 計測結果をもとに補正係数の設計案をまとめ、Riverpod プロバイダと MediaQuery ラッパーの仕様を確定。
3. 補正実装とデザインシステム調整を段階的に進め、検証結果を本意図ドキュメントに追記する。

## 残課題・オープンクエスチョン
- 極端な DPI 設定（175% 以上）での扱いと、フォントの読みやすさを損なわない範囲の補正上限値。
- Linux HiDPI や macOS ビルドへの展開タイミング。今回の抽象をどこまで汎用化すべきか。
- 補正導入後に既存のウィジェットテストが失敗する可能性への備え（テスト更新またはゴールデンテスト導入）。
