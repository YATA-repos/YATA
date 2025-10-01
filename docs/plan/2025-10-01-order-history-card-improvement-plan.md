# 注文履歴カード高さ改善 実装計画

## 概要

注文履歴画面の`_OrderHistoryCard`ウィジェットの高さを削減し、一覧性を向上させる実装計画。

**関連ドキュメント**:
- 現状分析: `docs/draft/2025-10-01-order-history-card-height-analysis.md`
- 改善提案: `docs/draft/2025-10-01-order-history-card-improvement-proposal.md`

## 実装方針

**採用案**: 案A（コンパクトカードレイアウト）

カード内のパディング・マージンを縮小し、情報を2行に集約することで、高さを約40%削減する。

## 実装スコープ

### Phase 1: 基本実装（必須）

1. カード内パディングの削減
2. 行間スペースの削減
3. 注文明細の省略表示
4. 顧客名・日時の1行統合
5. 備考欄の非表示

### Phase 2: 補助的改善（推奨）

6. カード間余白の削減
7. アイコンサイズの統一
8. フォントサイズの最適化

### Phase 3: 発展的改善（オプション）

1.  デザイントークンの整理

## 詳細実装計画

### 1. カード内パディングの削減

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド（309行目付近）

**変更内容**:
```dart
// Before
padding: const EdgeInsets.all(YataSpacingTokens.lg),

// After
padding: const EdgeInsets.all(YataSpacingTokens.md),
```

**効果**: 上下パディングが48px → 32px（16px削減）

---

### 2. 行間スペースの削減

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド内の複数箇所

**変更内容**:
```dart
// ヘッダーと次のセクション間（358行目付近）
// Before
const SizedBox(height: YataSpacingTokens.md),

// After
const SizedBox(height: YataSpacingTokens.sm),

// 同様に400行目、451行目なども変更
```

**効果**: セクション間スペースが16px → 12px（各箇所で4px削減）

---

### 3. 注文明細の省略表示

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド（402-447行目）

**変更内容**:

現在の展開表示を削除し、1行でカンマ区切り表示に変更する。

```dart
// Before（402-447行目）
...order.items
    .take(3)
    .map(
      (OrderItemViewData item) => Padding(
        padding: const EdgeInsets.only(bottom: YataSpacingTokens.xs),
        child: Row(
          children: <Widget>[
            Text(
              "${item.quantity}x",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: YataColorTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: YataSpacingTokens.sm),
            Expanded(
              child: Text(
                item.menuItemName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textPrimary),
              ),
            ),
            Text(
              "¥${currencyFormat.format(item.subtotal)}",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
            ),
          ],
        ),
      ),
    ),

if (order.items.length > 3) ...<Widget>[
  const SizedBox(height: YataSpacingTokens.xs),
  Text(
    "他${order.items.length - 3}件",
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: YataColorTokens.textSecondary,
      fontStyle: FontStyle.italic,
    ),
  ),
],

// After
Row(
  children: <Widget>[
    const Icon(
      Icons.shopping_bag_outlined,
      size: 14,
      color: YataColorTokens.textSecondary,
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    Expanded(
      child: Text(
        _buildOrderItemsSummary(order.items),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: YataColorTokens.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
```

**追加メソッド**（`_OrderHistoryCard`クラス内に追加）:
```dart
/// 注文明細のサマリーを生成する。
String _buildOrderItemsSummary(List<OrderItemViewData> items) {
  if (items.isEmpty) return "商品なし";
  
  final List<String> displayItems = items
      .take(3)
      .map((OrderItemViewData item) => item.menuItemName)
      .toList();
  
  final String summary = displayItems.join(", ");
  
  if (items.length > 3) {
    return "$summary, 他${items.length - 3}件";
  }
  
  return summary;
}
```

**効果**: 注文明細の高さが60px程度 → 20px程度（40px削減）

---

### 4. 顧客名・日時の1行統合

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド（361-398行目）

**変更内容**:

現在の2列レイアウトを1行に統合する。

```dart
// Before（361-398行目）
Row(
  children: <Widget>[
    Expanded(
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.person_outline,
            size: 16,
            color: YataColorTokens.textSecondary,
          ),
          const SizedBox(width: YataSpacingTokens.xs),
          Text(
            order.customerName ?? "名前なし",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
          ),
        ],
      ),
    ),
    Row(
      children: <Widget>[
        const Icon(
          Icons.access_time_outlined,
          size: 16,
          color: YataColorTokens.textSecondary,
        ),
        const SizedBox(width: YataSpacingTokens.xs),
        Text(
          dateFormat.format(order.orderedAt),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
        ),
      ],
    ),
  ],
),

// After
Row(
  children: <Widget>[
    const Icon(
      Icons.person_outline,
      size: 14,
      color: YataColorTokens.textSecondary,
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    Text(
      order.customerName ?? "名前なし",
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: YataColorTokens.textSecondary,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    Text(
      "|",
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: YataColorTokens.textSecondary,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    const Icon(
      Icons.access_time_outlined,
      size: 14,
      color: YataColorTokens.textSecondary,
    ),
    const SizedBox(width: YataSpacingTokens.xs),
    Text(
      dateFormat.format(order.orderedAt),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: YataColorTokens.textSecondary,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    Text(
      "|",
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: YataColorTokens.textSecondary,
      ),
    ),
    const SizedBox(width: YataSpacingTokens.sm),
    // 注文明細サマリーをここに移動（上記の変更内容と統合）
    Expanded(
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.shopping_bag_outlined,
            size: 14,
            color: YataColorTokens.textSecondary,
          ),
          const SizedBox(width: YataSpacingTokens.xs),
          Expanded(
            child: Text(
              _buildOrderItemsSummary(order.items),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: YataColorTokens.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  ],
),
```

**効果**: 2行分の高さ（約40-50px） → 1行（約20px）に削減（約20-30px削減）

---

### 5. 備考欄の非表示

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド（450-473行目）

**変更内容**:

備考欄の表示を完全に削除する。

```dart
// Before（450-473行目）
if (order.notes != null && order.notes!.isNotEmpty) ...<Widget>[
  const SizedBox(height: YataSpacingTokens.md),
  Container(
    padding: const EdgeInsets.all(YataSpacingTokens.sm),
    decoration: BoxDecoration(
      color: YataColorTokens.surfaceAlt,
      borderRadius: YataRadiusTokens.borderRadiusSmall,
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.note_outlined, size: 16, color: YataColorTokens.textSecondary),
        const SizedBox(width: YataSpacingTokens.xs),
        Expanded(
          child: Text(
            order.notes!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: YataColorTokens.textSecondary),
          ),
        ),
      ],
    ),
  ),
],

// After
// 完全に削除（備考は詳細ダイアログでのみ表示）
```

**効果**: 備考がある場合、最大60px程度の削減

---

### 6. カード間余白の削減

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryList.build()` メソッド（246-254行目）

**変更内容**:
```dart
// Before
separatorBuilder: (BuildContext context, int index) =>
    const SizedBox(height: YataSpacingTokens.md),

// After
separatorBuilder: (BuildContext context, int index) =>
    const SizedBox(height: YataSpacingTokens.sm),
```

**効果**: カード間余白が16px → 12px（4px削減）

---

### 7. アイコンサイズの統一

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド内の全アイコン

**変更内容**:
```dart
// Before
size: 16,

// After
size: 14,
```

**効果**: 視覚的な統一感の向上、わずかな高さ削減

---

### 8. フォントサイズの最適化

**対象ファイル**: `lib/features/order/presentation/pages/order_history_page.dart`

**変更箇所**: `_OrderHistoryCard.build()` メソッド内の複数テキストスタイル

**変更内容**:
```dart
// 受付コード（325行目付近）
// Before
style: Theme.of(context).textTheme.titleMedium?.copyWith(
  color: YataColorTokens.textPrimary,
  fontWeight: FontWeight.w600,
),

// After
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
  color: YataColorTokens.textPrimary,
  fontWeight: FontWeight.w600,
),

// 顧客名・日時・商品名など
// Before: bodyMedium
// After: bodySmall
```

**効果**: わずかな高さ削減と視覚的バランスの向上

---

## 実装後の期待効果

### 高さの削減

| ケース | 現状 | 改善後 | 削減率 |
|--------|------|--------|--------|
| 最小ケース（備考なし、1件） | 約148px | 約88px | 約40% |
| 平均ケース（備考なし、2-3件） | 約180px | 約100px | 約44% |
| 最大ケース（備考あり、3件） | 約220-240px | 約100px | 約55% |

### 一覧性の向上

- **スクロール量の削減**: 
  - 20件を閲覧する場合
    - 現状: 約3600px（約3.3画面分）
    - 改善後: 約2000px（約1.9画面分）

---

## テスト計画

### 単体テスト

注文明細サマリー生成メソッドのテスト:

```dart
// test/features/order/presentation/pages/order_history_page_test.dart

void main() {
  group('_OrderHistoryCard', () {
    group('_buildOrderItemsSummary', () {
      test('商品がない場合は「商品なし」を返す', () {
        // テスト実装
      });

      test('1件の場合は商品名をそのまま返す', () {
        // テスト実装
      });

      test('3件以下の場合はカンマ区切りで返す', () {
        // テスト実装
      });

      test('3件を超える場合は「他○件」を追加する', () {
        // テスト実装
      });
    });
  });
}
```

### 視覚的テスト

1. **デバイステスト**:
   - Android（モバイル、タブレット）
   - Windows（デスクトップ）

2. **画面サイズテスト**:
   - モバイル（< 768px）
   - タブレット（768-1024px）
   - デスクトップ（> 1024px）

3. **データパターンテスト**:
   - 注文明細が1件の場合
   - 注文明細が3件の場合
   - 注文明細が10件以上の場合
   - 備考がある場合（詳細ダイアログで確認）
   - 顧客名が長い場合
   - メニュー名が長い場合

### ユーザビリティテスト

1. **一覧性の確認**:
   - 20件の注文履歴を素早くスキャンできるか
   - 特定の注文を見つけやすいか

2. **情報の十分性**:
   - カード上の情報だけで必要な情報が得られるか
   - 詳細ダイアログを開く必要がある頻度は適切か

3. **視認性**:
   - フォントサイズが小さすぎないか
   - アイコンが見やすいか

---

## リスクと対応策

### リスク1: 情報量が不足する

**対応策**:
- 詳細ダイアログが簡単に開けることを強調（ホバー効果など）
- 必要に応じて、注文明細の表示件数を調整（2件 → 3件など）

### リスク2: モバイルで見づらくなる

**対応策**:
- モバイル専用のレイアウト調整を実装（Phase 3）
- レスポンシブヘルパーを活用した条件分岐

### リスク3: フォントサイズが小さすぎる

**対応策**:
- ユーザーフィードバックに基づいて調整
- アクセシビリティガイドラインの確認（最小フォントサイズなど）

---

## 実装スケジュール

### Phase 1（基本実装）: 2-3日

- Day 1: 実装（1-5の変更）
- Day 2: テスト・デバッグ
- Day 3: レビュー・修正

### Phase 2（補助的改善）: 1日

- 6-8の実装とテスト

### Phase 3（発展的改善）: 3-5日（オプション）

- デザイントークン整理: 1-2日

**合計**: 最短3-4日、最長9-11日（Phase 3含む）

---

## レビューポイント

実装後のコードレビューで確認すべき点:

1. **レイアウトの整合性**: 他の画面との一貫性
2. **コードの可読性**: 追加メソッドの命名・ロジック
3. **パフォーマンス**: サマリー生成のパフォーマンス影響
4. **アクセシビリティ**: フォントサイズ・色のコントラスト
5. **レスポンシブ対応**: 各画面サイズでの表示確認

---

## 関連ファイル一覧

- `lib/features/order/presentation/pages/order_history_page.dart`（主要変更対象）
- `lib/shared/foundations/tokens/spacing_tokens.dart`（参照）
- `lib/shared/foundations/tokens/typography_tokens.dart`（参照）
- `lib/shared/foundations/layout/responsive_helper.dart`（Phase 3で使用）
- `test/features/order/presentation/pages/order_history_page_test.dart`（新規作成）

---

## 参考資料

- Material Design Guidelines - Lists: https://m3.material.io/components/lists
- Flutter Layout Cheat Sheet: https://medium.com/flutter-community/flutter-layout-cheat-sheet-5363348d037e
- 既存のカードコンポーネント: `lib/shared/components/layout/section_card.dart`

---

## 変更履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-10-01 | 初版作成 | - |

---

*本計画は実装中に調整される可能性があります。*
