---
title: "Windows DPI 計測ログ"
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
---

## 目的
- Windows ビルドにおける `devicePixelRatio` や `textScaleFactor` の実測値を記録し、Linux 版との差異を定量化する。
- ログ出力とスクリーンショットを紐付け、補正係数設計の根拠資料とする。

## 計測手順
1. `flutter run -d windows --dart-define=LOG_DPI_INFO=true` を実行し、起動直後にメトリクスがログへ出力されることを確認する。
2. ログに出力された `dpi_probe` タグの内容を以下のテンプレートに転記する。
3. Windows の「表示スケール」を 100% / 125% / 150% に切り替え、それぞれについてログとスクリーンショットを取得する。
4. 取得したスクリーンショットを `media/ui_scaling/windows_<scale>.png` に保存し、ファイル名とリンクを記入する。
5. Linux 100% でのスクリーンショットも取得し、比較対象として記録する。

## ログ転記テンプレート
| 計測日 | OS / ビルド | 表示スケール | devicePixelRatio | textScaleFactor | 物理解像度 (W×H) | 論理解像度 (W×H) | 備考 |
|--------|-------------|---------------|------------------|-----------------|-------------------|-------------------|------|
| yyyy-mm-dd | Windows 11 Pro 23H2 / Release | 125% | 1.25 | 1.00 | 5120×1440 | 4096×1152 | 例: 外部モニター UWQHD |

## 計測記録
### 2025-10-XX 計測（担当: 未実施）
- `flutter run` コマンド: 
- ログ抜粋:
  ```text
  # ここに `dpi_probe` のログを貼り付ける
  ```
- スクリーンショット: `media/ui_scaling/windows_125.png` *(未取得)*
- Linux 比較キャプチャ: `media/ui_scaling/linux_100.png` *(未取得)*
- 概要メモ: 未実施

> 計測完了後は本セクションを複製し、日付順に追記すること。
