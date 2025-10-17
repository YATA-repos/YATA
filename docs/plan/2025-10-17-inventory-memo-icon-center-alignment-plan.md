# 在庫管理テーブル メモアイコン中央揃え実装計画（2025-10-17）

## 背景

在庫管理画面のテーブルに表示されるメモアイコン（📝）が、メモカラムの左側に寄っており、UI の統一性と視認性が低下している。

メモカラムに表示されるメモアイコンを中央揃えにすることで、テーブルレイアウトの一貫性を高め、より整理された外観を実現する。

## 課題分析

### 現状

- **ファイル**: `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- **対象部分**: 1015～1028行目付近の `memoCell` ウィジェット定義
- **現在の配置**: `Align(alignment: Alignment.centerLeft, ...)`
- **問題点**:
  - メモアイコンが左寄せされており、カラム内での位置がちぐはぐに見える
  - テーブルの他のセル（metrics等）との配置バランスが失われている

### 参照実装

- `metricsCell` や `adjustmentCell` では、適切な `MainAxisAlignment` や `Alignment` を使用してレイアウトが調整されている
- メモカラムは比較的シンプルな構成（メモあり/なしで表示切り替え）のため、中央揃えへの変更は他の要素への影響が少ない

## 解決方針

1. **メモセルのアラインメント変更**
   - `Align` ウィジェットの `alignment` プロパティを `Alignment.centerLeft` から `Alignment.center` に変更
   - メモアイコンがカラムの中央に表示されるようになる

2. **代替案の検討**
   - 必要に応じて `SizedBox` で固定幅を指定し、アイコンを厳密に中央に配置することも可能
   - ただし、メモなし時に `SizedBox.shrink()` が返されるため、基本的には `Alignment.center` で十分

3. **レイアウトへの影響確認**
   - メモカラムの幅と行の高さ（`dataRowMinHeight: 60, dataRowMaxHeight: 68`）において、アイコンが適切に表示されるか確認
   - 隣接する他のカラム（カテゴリ、在庫状況など）に影響がないことを検証

## タスク分解

### 1. コード修正
- **対象ファイル**: `lib/features/inventory/presentation/pages/inventory_management_page.dart`
- **修正内容**:
  ```dart
  // 変更前
  final Widget memoCell = row.hasMemo
      ? Align(
          alignment: Alignment.centerLeft,  // ← ここを変更
          child: Tooltip(
            message: row.memoTooltip ?? row.memo,
            child: const Icon(
              Icons.sticky_note_2_outlined,
              size: 20,
              color: YataColorTokens.textSecondary,
            ),
          ),
        )
      : const SizedBox.shrink();
  
  // 変更後
  final Widget memoCell = row.hasMemo
      ? Align(
          alignment: Alignment.center,  // ← 中央揃えに変更
          child: Tooltip(
            message: row.memoTooltip ?? row.memo,
            child: const Icon(
              Icons.sticky_note_2_outlined,
              size: 20,
              color: YataColorTokens.textSecondary,
            ),
          ),
        )
      : const SizedBox.shrink();
  ```

### 2. UI 確認・検証
- 在庫管理画面を起動し、メモカラムのアイコン配置を目視確認
- 以下のケースで表示が正しいことを確認:
  - メモ有りの在庫アイテム: アイコンが中央に表示されている
  - メモなしの在庫アイテム: 何も表示されていない（`SizedBox.shrink()`の動作）
  - テーブル全体: 他のカラムとのバランスが取れている

### 3. 静的解析・フォーマッティング
- `flutter analyze` を実行し、警告やエラーがないことを確認
- `dart format` を実行し、コード形式を整える

### 4. ユニットテスト（任意）
- 既存のウィジェットテストで `memoCell` の描画を確認している場合、テストの更新検討
- 変更が小規模であるため、手動テストで十分な可能性が高い

## 検証計画

### UI 検証チェックリスト
- [ ] 在庫管理画面を起動
- [ ] メモカラムのアイコンが中央に表示されている
- [ ] テーブル行全体のバランスが取れている
- [ ] ホバー/フォーカス時のツールチップが正常に動作している
- [ ] メモなしアイテムでは何も表示されていない

### コード検証チェックリスト
- [ ] `flutter analyze` にエラーがない
- [ ] `dart format` で形式が統一されている
- [ ] 隣接するコード（カラム定義など）に問題がない

## 成果物

- `lib/features/inventory/presentation/pages/inventory_management_page.dart` の修正版

## リスク・注意事項

- **影響範囲が限定的**: メモアイコンの配置変更のみであり、他の機能への影響はほぼなし
- **UI 検証必須**: アラインメント変更は微細な変更のため、本来は目視確認で十分
- **テーブル全体の一貫性**: 他のカラム（特に `metricsCell`）との配置バランスも合わせて確認することを推奨

## 関連タスク

- **ID**: Inventory-Enhancement-35
- **Priority**: P3
- **Size**: XS
- **Goal**: 在庫管理テーブルのメモカラムでメモアイコンが中央揃えになる

## スケジュール目安

- 実装・検証: 15～30分
- テスト・確認: 15分
- **合計**: 1時間未満

