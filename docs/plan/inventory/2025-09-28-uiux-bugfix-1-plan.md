# 在庫一括操作ボタン改善 計画（UI/UX-Bugfix-1 / 2025-09-28）

> 種別: plan / ステータス: 計画中（未実装） / 対象領域: inventory / 優先度: P1
>
> 元タスク: `TODO.md` > Ready > `[Bugfix] 在庫一括操作の適用ボタンとdisabled制御を修正`
>
> 参照ファイル:
> - `lib/features/inventory/presentation/pages/inventory_management_page.dart`
> - `lib/features/inventory/presentation/controllers/inventory_management_controller.dart`

---

## 1. 背景と現状の問題整理

- **一括操作ツールバーに「適用」ボタンが存在しない。**
  - 選択行に差分を設定しても、各行の「適用」ボタンを個別に押す必要がある。
  - コントローラには `applySelected()` が既に存在しており、UI と非同期になっている。
- **行ごとの「適用」ボタンの無効化条件が UI とロジックでズレている。**
  - UI は `delta == 0 || (item.current + delta) < 0` のみを判定している。
  - コントローラは `canApply(itemId)` を定義しており、将来的に条件が追加されても UI が追従しない。
  - `pendingAdjustments` に存在しないが `selectedIds` に含まれている場合など、UI が有効表示のままになるケースが発生する。
- 既存の計画（2025-09-26 inventory management UI plan）で一括適用 UI を追加する構想はあるが、本タスクは**現行仕様のバグ修正**として最小限の改善を行う。

---

## 2. 目的と非目的

### 目的（達成すべきこと）

1. 選択状態で一括適用ボタンを表示し、`applySelected()` を呼び出せるようにする。
2. 無効化条件を `InventoryManagementController.canApply` と同期させ、UI が常に正しい状態を示すようにする。
3. バグ修正後も既存の操作フローとレイアウトを大きく崩さない。

### 非目的（今回扱わないこと）

- バッチ適用結果のサマリ表示、トースト通知などの追加 UX。
- `applyAllVisible()` や差分クリアなど新たなショートカット UI の導入。
- `pendingAdjustments` のスキーマ変更、数値刻み設定など別計画で扱う改善案。

---

## 3. 変更方針

### 3.1 一括適用ボタンの追加

- 選択用ツールバー（`state.selectedIds.isNotEmpty` で表示される `Wrap`）に `FilledButton.icon` を追加。
- ラベル案: `適用 (選択)`、アイコン: `Icons.task_alt`。
- **活性条件**: 選択行のうち `canApply(id)` が true で `pendingAdjustments[id]` が 0 でないものが1件以上存在する場合のみ enabled。
- 押下時の挙動: `controller.applySelected()` を呼び出し、完了後は SnackBar 等の通知は追加しない（現行の UX を踏襲）。
- ツールチップ: "選択された行の調整をまとめて適用"。

### 3.2 行別ボタンの無効化条件整理

- 各行の `ElevatedButton.icon` における `onPressed` 判定を以下のように切り替え:
  1. `delta == 0` の場合は null（従来通り）。
  2. `!controller.canApply(item.id)` の場合は null。
- ツールチップ文言を `controller.canApply` の結果に合わせて分岐:
  - 適用不可: "新在庫が0未満のため適用不可"（既存流用）
  - 差分0: "変更がありません"（既存流用）
- 必要に応じて `controller.canApply` が `pendingAdjustments` に存在しない ID を扱った際に false を返すよう再確認（現仕様では既に false になる）。

### 3.3 UI ステート計算のサポート

- Widget 側で選択対象の適用可否を判定するため、以下のいずれかでロジックを共通化:
  - Option A: Widget 内で `state.selectedIds.any((id) => (state.pendingAdjustments[id] ?? 0) != 0 && controller.canApply(id))` を計算。
  - Option B: コントローラに `bool hasApplicableSelection(Set<String> ids)` ヘルパーを追加（ステートレスに保つ場合は A 案で可）。
- `state.pendingAdjustments` が空でも `selectedIds` に値が残っているケースに備え、選択解除ボタン (`controller.clearSelection`) の活性条件は現状維持。

---

## 4. 実装タスク（順序）

1. **UI ロジック整備**
   - `_InventoryTable` 内で選択行の適用可否を計算するヘルパーを追加。
   - ツールバーの `Wrap` に新しいボタンを追加し、活性条件を紐付け。
2. **行別ボタンの無効化統一**
   - `onPressed` 判定と Tooltip の条件式を `controller.canApply` ベースへ置き換え。
3. **テスト/検証**
   - `InventoryManagementController` の `canApply` が期待通り動作することを確認する既存テストを補強・追加。
   - `applySelected` の単体テストを追加し、適用後に `selectedIds` と `pendingAdjustments` が更新されることを確認。
   - 手動確認: 選択→差分入力→一括適用→差分クリアの動作。
4. **リグレッション確認**
   - 差分をマイナスにして 0 未満になる場合にボタンが無効化されることを確認。
   - 選択を解除した際に一括適用ボタンが消えることを確認。

---

## 5. 受け入れ基準

- 差分を持つ 2 行を選択し、一括適用ボタンが活性化する。
- 一括適用ボタン押下後、選択行の `pendingAdjustments` がクリアされ、`selectedIds` も空になる。
- 行別「適用」ボタンが負在庫になる差分では常に無効化され、ツールチップで理由が確認できる。
- 差分 0 の行は適用ボタンが無効化される。
- Analyzer / テストが失敗しない。

---

## 6. リスクと対応

| リスク | 影響 | 緩和策 |
| --- | --- | --- |
| `controller.canApply` のロジックに変更が入った場合に UI との再同期が必要 | 中 | 今回 `canApply` を単一ソースとして参照。将来変更時はテストを更新。 |
| 選択が多い場合に `any` 判定がパフォーマンスに与える影響 | 低 | 最大でも画面表示件数ぶんのループ。現状リスト件数は限定的で問題なし。 |
| UI 追加によりレイアウトが詰まり、狭幅時に折り返しが崩れる | 中 | `Wrap` を使用しているため既存レイアウトに準拠。必要なら `Expanded` で調整。 |

---

## 7. バリデーション方法

1. **ユニットテスト**
   - `applySelected` が `canApply` false の行をスキップすること。
   - `canApply` が `pendingAdjustments` 未登録や負在庫ケースで false を返すこと。
2. **手動チェックリスト**
   - 加算（+1）後に一括適用→ `current` が更新される。
   - 減算で `current` が 0 未満になる設定 → 行ボタン・一括ボタンともに無効。
   - 選択解除後に一括ボタンが非表示。

---

## 8. 今後の拡張メモ

- Selection ツールバーに差分クリアボタン・表示分適用ボタンを再配置する検討（別タスク）。
- 適用完了時に Snackbar を表示し、オペレーションフィードバックを強化する施策。
- 差分単位の粒度・小数対応は `Order-Performance-1` や既存改善計画と連携して扱う。
