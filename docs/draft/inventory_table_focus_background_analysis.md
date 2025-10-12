# 在庫テーブル背景色異常 調査メモ

- 日付: 2025-10-12
- 対象画面: 在庫管理 > テーブル表示
- 調査担当: GitHub Copilot

## 症状
- テーブルの特定行が濃い灰色で塗りつぶされ、文字が視認しづらくなる。
- 添付スクリーンショットでは先頭行 (`にんじん`) が異常に暗く表示されている。
- 列内のステッパー入力欄をアクティブにすると再現しやすい。

## 再現手順
1. 在庫管理画面で任意の在庫行を表示する。
2. 「調整」列のステッパー内数値フィールドをタップし、フォーカスを当てる。
3. 当該行全体が暗い灰色背景に変わる。

## 観察
- 異常が発生するのはフォーカスを持つ行のみで、他の行は白背景のまま。
- `lib/shared/components/data_display/data_table.dart` で `DataTableThemeData.dataRowColor` を独自設定している。
- テーマ設定では `WidgetState.selected` と `WidgetState.hovered` のみ処理し、それ以外の状態では `null` を返している。

## 原因分析
- Flutter の `DataTable` は行にフォーカス（`WidgetState.focused`）が当たると、`DataTableThemeData.dataRowColor` で `null` が返却された場合にデフォルトのフォーカス色（濃いグレー）を適用する。
- 在庫テーブル行には `YataQuantityStepper`（内部で `TextField` を使用）が含まれており、ステッパーにフォーカスが当たると行全体が `WidgetState.focused` 扱いになる。
- 現状のテーマ設定では `WidgetState.focused` を明示的に処理していないため、デフォルトの濃いグレー背景がそのまま反映されている。

## 結論
- 行背景が暗くなる直接原因は、`WidgetState.focused` 状態で `DataTableThemeData.dataRowColor` が `null` を返している点にある。
- フォーカス時にも `Colors.transparent` 相当を返すか、独自のフォーカス時背景色を指定することで症状を解消できる。

## 対応案
1. `data_table.dart` の `dataRowColor` 設定を見直し、`WidgetState.focused`（必要なら `pressed`, `dragged` など）に対しても透過色または適切な背景色を返す。
2. 併せて、フォーカス有無に応じたアクセシビリティを考慮し、必要であればフォーカスインジケーターを別要素に追加する。

## 影響範囲・留意点
- 在庫テーブル以外で `YataDataTable` を使用している画面でも同じ症状が発生する可能性あり。
- 既存のホバー/選択時スタイルとの整合を確認し、UIガイドラインに沿った色設計にすること。
