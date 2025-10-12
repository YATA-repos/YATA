# 在庫管理テーブルUI改善提案

**作成日**: 2025-10-12  
**対象画面**: 在庫管理画面（`InventoryManagementPage`）  
**対象コンポーネント**: `_InventoryTable`

## 現状分析

### 現在のUI構造

スクリーンショットと実装から、以下の構造が確認できます：

- **列構成**（6列）:
  1. 在庫アイテム（名前 + メモ）
  2. カテゴリ
  3. 在庫状況（現在数量 + 閾値）
  4. ステータス（バッジ表示）
  5. 調整（±調整 + 適用ボタン）
  6. 更新（更新日時）

- **行の高さ**: 60-68px（`dataRowMinHeight: 60, dataRowMaxHeight: 68`）
- **各セルの複雑度**: セル内に複数行の情報とインタラクティブ要素

### 視認性の課題

#### 1. **情報密度の高さ**

**問題点**:
- 1行に多くの情報が詰め込まれており、視線の移動が多い
- 「在庫アイテム」列にメモ（最大2行）が含まれ、縦のスペースを消費
- 「在庫状況」列に現在数量と閾値が縦に並び、数値の比較がしづらい
- 「調整」列にステッパー + ボタン + 計算結果が含まれ、操作領域が狭い

**根拠**:
```dart
// itemCell: 名前 + メモで2段構成
final Widget itemCell = Column(
  children: <Widget>[
    Text(row.name, style: titleSmall.copyWith(fontWeight: w600)),
    Padding(
      child: Text(row.memo, maxLines: 2, overflow: ellipsis), // 最大2行
    ),
  ],
);

// quantityCell: 数量 + 閾値で2段構成
final Widget quantityCell = Column(
  children: <Widget>[
    Text(row.quantityLabel),
    Text(row.thresholdsLabel, style: bodySmall),
  ],
);

// adjustmentColumn: ラベル行 + 操作行の2段構成
final Widget adjustmentColumn = Column(
  children: <Widget>[
    Row(children: [Text(deltaLabel), Text(afterChangeLabel)]), // 計算結果
    Row(children: [YataQuantityStepper(...), ElevatedButton(...)]), // 操作
  ],
);
```

#### 2. **重要情報の埋没**

**問題点**:
- 「12 個」という在庫数が、警告閾値「警告 6 / 危険 3 個」と同じ列に縦並びで表示
- 現在のステータスバッジ（「適切」）が緑色だが、視覚的な強調が弱い
- 「調整」列の操作エリアが複雑で、初見ユーザーには理解しづらい

**根拠**:
- スクリーンショットでは「12 個」の数値が小さく、閾値情報と視覚的に分離されていない
- ステータスは4列目に配置されているが、最も重要な情報の1つであるにもかかわらず中央に埋もれている

#### 3. **操作性の課題**

**問題点**:
- 調整ステッパーとボタンが横に並び、スペースが制約される
- 適用ボタンの状態（有効/無効）の理由が直感的でない
- 行をクリックして編集ダイアログが開くが、その動作がUI上で示されていない

**根拠**:
```dart
// 調整列の幅が制約される中で、ステッパーとボタンを横配置
Row(
  children: <Widget>[
    Expanded(child: YataQuantityStepper(...)), // Expandedで圧縮される
    SizedBox(width: sm),
    SizedBox(height: 36, child: ElevatedButton.icon(...)), // 固定幅のボタン
  ],
),
```

#### 4. **視覚的階層の不足**

**問題点**:
- すべての列が同じ視覚的重要度で扱われている
- 主要な情報（名前、数量、ステータス）と補助情報（更新日時）の区別が弱い
- カラースキームが控えめで、緊急性の高い情報が目立たない

## 改善提案

### アプローチ1: 情報の階層化とレイアウト再構成

#### 提案内容

**列構成の見直し**:
```
[在庫アイテム] [カテゴリ] [現在数量] [ステータス] [調整/操作] [更新]
    ↓
[在庫アイテム（簡略）] [カテゴリ] [在庫情報（強調）] [操作]
```

1. **在庫アイテム列**: メモを削除（ツールチップまたは展開可能に）
2. **在庫情報列**: 現在数量を大きく表示、ステータスバッジと統合
3. **操作列**: 調整と適用を統合し、閾値情報をツールチップに移動
4. **更新列**: 削除し、ホバー時のツールチップに情報を集約

**視覚的改善**:
- 現在数量を `titleLarge` スタイルで大きく表示
- ステータスに応じて行全体の背景色を薄く変更（危険=淡赤、警告=淡黄）
- 調整ボタンを常時表示ではなく、ホバー時に強調表示

#### 実装例（疑似コード）

```dart
// 在庫情報列: 数量とステータスを統合
final Widget inventoryInfoCell = Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: <Widget>[
    // 大きく目立つ数量表示
    Text(
      row.currentQuantity, // "12 個"
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: _quantityColorFor(row.status),
      ),
    ),
    const SizedBox(width: YataSpacingTokens.md),
    // ステータスバッジ
    YataStatusBadge(
      label: row.statusLabel,
      type: row.statusType,
      size: YataStatusBadgeSize.large, // 大きめのバッジ
    ),
  ],
);

// 操作列: シンプルな調整UI
final Widget actionCell = Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: <Widget>[
    // クイック調整ボタン
    YataIconButton(
      icon: Icons.remove,
      onPressed: () => controller.quickAdjust(row.id, -1),
      tooltip: "1減らす",
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    Text(
      row.pendingDelta > 0 ? '+${row.pendingDelta}' : '${row.pendingDelta}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: _deltaColorFor(row.deltaTrend),
        fontWeight: FontWeight.w600,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    YataIconButton(
      icon: Icons.add,
      onPressed: () => controller.quickAdjust(row.id, 1),
      tooltip: "1増やす",
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    // 詳細調整・適用ボタン
    ElevatedButton.icon(
      icon: const Icon(Icons.edit_outlined),
      label: const Text("調整"),
      onPressed: () => _showAdjustmentDialog(row),
    ),
  ],
);
```

#### 期待効果

- **視認性向上**: 現在数量が大きく表示され、一目で在庫状況を把握可能
- **操作性向上**: クイック調整（±1）と詳細調整を分離し、頻繁な操作を簡素化
- **情報整理**: 重要度の低い情報（更新日時、閾値詳細）をツールチップに移動し、テーブルをすっきりさせる

---

### アプローチ2: カードベースレイアウトへの移行

#### 提案内容

従来のテーブルから、カード型のリスト表示に切り替える。

**レイアウト案**:
```
┌────────────────────────────────────────────────────┐
│ [アイコン] にんじん                       12 個    │
│            野菜                       [適切]   │
│            メモ登録済                              │
│                                                    │
│  警告: 6個 / 危険: 3個         [- 0 +] [適用]    │
│  最終更新: 10/11 18:19                            │
└────────────────────────────────────────────────────┘
```

- カードごとに背景色でステータスを表現（危険=淡赤枠、警告=淡黄枠）
- 上段: 名前、現在数量、ステータスバッジ
- 中段: カテゴリ、メモ有無
- 下段: 閾値情報、調整操作、更新日時

#### メリット・デメリット

**メリット**:
- 各アイテムの情報が視覚的にグループ化され、理解しやすい
- モバイル端末での表示に適応しやすい
- カードの高さを柔軟に調整でき、情報の表示/非表示を切り替えやすい

**デメリット**:
- 一覧性が低下し、多数のアイテムを比較しづらい
- ソート機能の視覚的フィードバックが弱くなる
- 実装コストが高い（既存のYataDataTableから大きく変更）

#### 実装難易度

- **高**: 既存のテーブルコンポーネントを使わず、カスタムレイアウトが必要
- デザインシステムとの整合性を保つため、新しい `YataInventoryCard` コンポーネントの設計が必要

---

### アプローチ3: インラインアクションの最適化

#### 提案内容

現在の列構成を維持しつつ、操作UIを最適化する。

**改善ポイント**:

1. **調整列の再設計**:
   - ステッパーUIを削除し、シンプルな `[+/-]` ボタンに変更
   - 調整値を中央に大きく表示（例: `+3`）
   - 「適用」ボタンを右端に配置し、アイコンのみに変更

2. **ステータス列の強化**:
   - バッジサイズを大きくする（`large` サイズ）
   - 緊急性に応じてアイコンを追加（危険=⚠️、警告=⚡）

3. **在庫状況列の簡略化**:
   - 現在数量のみを大きく表示
   - 閾値情報は「ⓘ」アイコンのツールチップに移動

4. **行のホバー効果**:
   - ホバー時に背景を薄く変更し、クリック可能であることを示唆
   - ホバー時に「詳細編集」ボタンを右端に表示

#### 実装例

```dart
// 在庫状況列: シンプルに
final Widget quantityCell = Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: <Widget>[
    Text(
      row.quantityValue, // "12"
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: _quantityColorFor(row.status),
      ),
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    Text(
      row.unitSymbol, // "個"
      style: theme.textTheme.bodyLarge?.copyWith(
        color: YataColorTokens.textSecondary,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    YataIconButton(
      icon: Icons.info_outline,
      size: YataIconButtonSize.small,
      tooltip: row.thresholdsLabel, // "警告: 6個 / 危険: 3個"
      onPressed: null, // 情報表示のみ
    ),
  ],
);

// 調整列: 最小限のUI
final Widget adjustmentCell = Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: <Widget>[
    // クイック調整ボタン
    Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        YataIconButton(
          icon: Icons.remove_circle_outline,
          onPressed: () => controller.adjustDelta(row.id, -1),
          tooltip: "1減らす",
        ),
        const SizedBox(width: YataSpacingTokens.sm),
        SizedBox(
          width: 48,
          child: Text(
            row.deltaLabel, // "±0" or "+3"
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _deltaColorFor(row.deltaTrend),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: YataSpacingTokens.sm),
        YataIconButton(
          icon: Icons.add_circle_outline,
          onPressed: () => controller.adjustDelta(row.id, 1),
          tooltip: "1増やす",
        ),
      ],
    ),
    // 適用ボタン
    Tooltip(
      message: applyTooltip,
      child: IconButton(
        icon: const Icon(Icons.check_circle),
        onPressed: canApplyItem ? () => controller.applyAdjustment(row.id) : null,
        color: YataColorTokens.success,
        disabledColor: YataColorTokens.neutral300,
      ),
    ),
  ],
);
```

#### 期待効果

- **操作性向上**: ±1の調整が直感的になり、マウス操作が減る
- **視認性向上**: 数値が大きく表示され、ステータスとの関連が明確になる
- **実装コスト**: 中程度（既存構造を維持しつつ、セル内のレイアウトのみ変更）

---

## 推奨アプローチ

### 第一段階: アプローチ3（インラインアクション最適化）

**理由**:
1. **既存構造の維持**: YataDataTableを引き続き利用でき、実装コストが低い
2. **即座の効果**: 視認性と操作性の両方を改善できる
3. **段階的移行**: 将来的にアプローチ1や2へ移行する際の基盤となる

**実装優先度**:
1. 🔴 **高**: 在庫状況列の簡略化（数値を大きく表示）
2. 🔴 **高**: 調整列のUI改善（±ボタン + 適用アイコン）
3. 🟡 **中**: ステータス列の強化（バッジサイズ拡大）
4. 🟢 **低**: 行のホバー効果追加

### 第二段階: アプローチ1（情報の階層化）

**条件**:
- ユーザーフィードバックで「情報が多すぎる」という意見が多い場合
- 画面の使用頻度が高く、より洗練されたUIが求められる場合

**実装内容**:
- メモ列の削除（ツールチップ化）
- 更新列の削除（ツールチップ化）
- 在庫情報列とステータス列の統合

---

## 技術的考慮事項

### 1. レスポンシブ対応

現在のYataDataTableはデスクトップ向けに最適化されていますが、将来的にタブレット対応も視野に入れる必要があります。

**対応案**:
- `LayoutBuilder`で画面幅に応じて列数を調整
- 狭い画面では「カテゴリ」「更新」列を非表示にする

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final bool isCompact = constraints.maxWidth < 1200;
    return YataDataTable.fromSpecs(
      columns: [
        itemColumn,
        if (!isCompact) categoryColumn,
        quantityColumn,
        statusColumn,
        adjustmentColumn,
        if (!isCompact) updatedColumn,
      ],
      // ...
    );
  },
);
```

### 2. アクセシビリティ

**現状の問題**:
- スクリーンリーダー利用時、複雑なセル構造の理解が困難
- キーボードナビゲーションで調整ステッパーへのフォーカス移動が煩雑

**改善案**:
- 各セルに適切な `Semantics` ウィジェットを追加
- 行全体に `semanticLabel` を設定（現在も実装済み）
- 調整操作にキーボードショートカット（+/-キー）を追加

```dart
Semantics(
  label: '${row.name}の在庫数量: ${row.quantityLabel}',
  value: row.statusLabel,
  hint: '詳細を編集するにはクリックしてください',
  child: quantityCell,
);
```

### 3. パフォーマンス

**現状**:
- 行数が多い場合（100件以上）、スクロール時のパフォーマンス低下が懸念される
- 各行に複雑なウィジェットツリーが含まれる

**最適化案**:
- `ListView.builder` による仮想化（現在のYataDataTableが実装済みか確認が必要）
- `const` コンストラクタの活用
- 不要な再ビルドを避けるため、行データを `ChangeNotifier` で管理

---

## 実装タスクリスト（アプローチ3）

### Phase 1: 在庫状況列の改善
- [ ] `_buildQuantityCell()` メソッドを作成
- [ ] 数値を `headlineSmall` で大きく表示
- [ ] 閾値情報をツールチップに移動
- [ ] 単位表記を小さく補足表示

### Phase 2: 調整列の改善
- [ ] `_buildAdjustmentCell()` メソッドを作成
- [ ] ±ボタンをアイコンボタンに変更
- [ ] 調整値を中央に大きく表示
- [ ] 適用ボタンをアイコンのみに変更
- [ ] `controller.adjustDelta()` メソッドを追加（現在の `setPendingAdjustment` を補完）

### Phase 3: ステータス列の強化
- [ ] バッジサイズを `large` に変更（YataStatusBadgeの拡張が必要か確認）
- [ ] 緊急度アイコンの追加

### Phase 4: ホバー効果の追加
- [ ] `_InventoryTableRow` ウィジェットを作成（ホバー状態管理）
- [ ] ホバー時に背景色を変更
- [ ] ホバー時に「詳細編集」ボタンを表示

---

## デザインモック（テキストベース）

### 改善前（現状）

```
┌──────────────┬──────┬──────────────┬────────┬─────────────────┬────────┐
│在庫アイテム  │カテゴ│在庫状況      │ステータ│調整             │更新    │
│              │リ    │              │ス      │                 │        │
├──────────────┼──────┼──────────────┼────────┼─────────────────┼────────┤
│にんじん      │野菜  │12 個         │適切│±0   →12 個     │10/11   │
│メモ登録済    │      │警告 6/危険 3 │        │[- 0 +] [適用]   │18:19   │
└──────────────┴──────┴──────────────┴────────┴─────────────────┴────────┘
```

### 改善後（アプローチ3）

```
┌──────────────┬──────┬────────────────┬──────────┬─────────────────────┐
│在庫アイテム  │カテゴ│在庫数量        │ステータス│調整                 │
├──────────────┼──────┼────────────────┼──────────┼─────────────────────┤
│にんじん      │野菜  │ 12 個 [ⓘ]    │[適切]│ [➖] ±0  [➕] [✓]  │
│メモ登録済    │      │                │          │                     │
└──────────────┴──────┴────────────────┴──────────┴─────────────────────┘

※ [ⓘ] = ツールチップで「警告: 6個 / 危険: 3個 | 更新: 10/11 18:19」を表示
※ [✓] = 適用ボタン（変更がある場合のみ有効）
```

---

## まとめ

### 主要な改善ポイント

1. **情報の優先順位付け**: 在庫数量を大きく表示し、補助情報をツールチップに移動
2. **操作の簡略化**: クイック調整（±1）と詳細調整を分離し、頻繁な操作を効率化
3. **視覚的階層の強化**: ステータスバッジを大きくし、緊急性を強調
4. **スペースの有効活用**: 列数を削減し、各セルに余裕を持たせる

### 期待される効果

- **視認性**: 在庫数量が一目で分かり、ステータスの判断が容易になる
- **操作性**: マウスクリック数が減り、在庫調整の作業効率が向上する
- **保守性**: シンプルなUI構造により、将来的な拡張が容易になる

### 次のステップ

1. ユーザーテスト: 既存ユーザーに改善案（アプローチ3）を提示し、フィードバックを収集
2. プロトタイプ作成: Figmaなどで視覚的なモックを作成し、デザイン合意を得る
3. 段階的実装: Phase 1から順次実装し、各段階でユーザーフィードバックを反映
