# 注文履歴カード UI/UX 詳細設計

## 概要

本ドキュメントは、注文履歴カードの改善案における具体的なUI/UXの詳細設計を記載する。

視覚的なレイアウト例、カラー・フォント・スペーシングの具体的な指定、ユーザー操作フローなどを含む。

**関連ドキュメント**:
- 改善提案: `docs/draft/2025-10-01-order-history-card-improvement-proposal.md`
- 実装計画: `docs/plan/2025-10-01-order-history-card-improvement-plan.md`

---

## 推奨案（案A）の詳細レイアウト

### レイアウト構造の詳細図

```
┌─────────────────────────────────────────────────────────────────────┐
│  16px padding                                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ [A-001]  [●完了]                      ¥1,500  [現金]       │ │ ← 第1行（24px高）
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  12px spacing                                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 👤田中太郎 | 🕐10/01 12:30 | 🛍️ラーメン, 餃子, 他2件         │ │ ← 第2行（20px高）
│  └───────────────────────────────────────────────────────────────┘ │
│  16px padding                                                       │
└─────────────────────────────────────────────────────────────────────┘
                    ↑
              Total: ~88px
```

### 第1行の詳細（ヘッダー行）

#### 左側: 受付コード + ステータス

```
[A-001]  [●完了]
 ↑ bodyLarge (16px, fontWeight: 600)
 ↑ 色: YataColorTokens.textPrimary

         ↑ YataStatusBadge（既存コンポーネント）
         ↑ 高さ: 約24px（パディング含む）
```

**スペーシング**:
- 受付コードとステータスバッジの間: `YataSpacingTokens.sm` (12px)

#### 右側: 金額 + 支払い方法

```
                    ¥1,500  [現金]
                     ↑ bodyLarge (16px, fontWeight: 600)
                     ↑ 色: YataColorTokens.textPrimary

                            ↑ bodySmall (12px)
                            ↑ 色: YataColorTokens.textSecondary
```

**スペーシング**:
- 金額と支払い方法の間: `YataSpacingTokens.sm` (12px)

**レイアウト**:
- `Row`で左右に分割（`MainAxisAlignment.spaceBetween`）
- 左側: `Expanded`で残りスペースを占有
- 右側: 固定幅（金額 + 支払い方法）

---

### 第2行の詳細（情報統合行）

#### 構造

```
👤田中太郎 | 🕐10/01 12:30 | 🛍️ラーメン, 餃子, 他2件
↑14px icon      ↑14px icon      ↑14px icon
↑bodySmall      ↑bodySmall      ↑bodySmall（Expanded）
```

**要素の詳細**:

1. **顧客名セクション**:
   - アイコン: `Icons.person_outline`, size: 14
   - テキスト: `bodySmall` (12px)
   - 色: `YataColorTokens.textSecondary`
   - 最大幅: なし（可変）

2. **区切り文字**:
   - テキスト: `"|"`
   - スタイル: `bodySmall`
   - 色: `YataColorTokens.textSecondary`
   - 前後スペース: `YataSpacingTokens.sm` (12px)

3. **日時セクション**:
   - アイコン: `Icons.access_time_outlined`, size: 14
   - テキスト: `bodySmall` (12px)
   - 色: `YataColorTokens.textSecondary`
   - フォーマット: `MM/dd HH:mm`（例: `10/01 12:30`）

4. **注文明細サマリーセクション**:
   - アイコン: `Icons.shopping_bag_outlined`, size: 14
   - テキスト: `bodySmall` (12px)
   - 色: `YataColorTokens.textSecondary`
   - 省略: `overflow: TextOverflow.ellipsis`, `maxLines: 1`
   - `Expanded`で残りスペースを占有

**スペーシング**:
- 各要素間: `YataSpacingTokens.xs` (8px)
- 区切り文字前後: `YataSpacingTokens.sm` (12px)

**レイアウト**:
- `Row`で横並び
- 注文明細サマリーは`Expanded`で可変幅

---

## カラーパレット

### テキストカラー

| 要素 | カラートークン | 実際の色（Light） |
|------|----------------|-------------------|
| 受付コード | `YataColorTokens.textPrimary` | `#1A1A1A` |
| 金額 | `YataColorTokens.textPrimary` | `#1A1A1A` |
| 顧客名・日時・商品 | `YataColorTokens.textSecondary` | `#6B7280` |
| 支払い方法 | `YataColorTokens.textSecondary` | `#6B7280` |

### 背景カラー

| 要素 | カラートークン | 実際の色（Light） |
|------|----------------|-------------------|
| カード背景 | `YataColorTokens.surface` | `#FFFFFF` |
| カード枠線 | `YataColorTokens.border` | `#E5E7EB` |

### ステータスバッジのカラー

`YataStatusBadge`コンポーネントが管理（既存実装を使用）:

- 完了: 緑系
- 準備中: 青系
- キャンセル: 赤系

---

## フォント仕様

### 使用するタイポグラフィトークン

| 要素 | トークン | サイズ | ウェイト | 行高 |
|------|----------|--------|----------|------|
| 受付コード | `bodyLarge` | 16px | 600 | 1.4 |
| 金額 | `bodyLarge` | 16px | 600 | 1.4 |
| 支払い方法 | `bodySmall` | 12px | 500 | 1.5 |
| 顧客名 | `bodySmall` | 12px | 500 | 1.5 |
| 日時 | `bodySmall` | 12px | 500 | 1.5 |
| 商品名 | `bodySmall` | 12px | 500 | 1.5 |

**変更理由**:
- 受付コードと金額を`titleMedium`から`bodyLarge`に変更し、若干軽量化
- その他を`bodyMedium`から`bodySmall`に変更し、コンパクト化

---

## スペーシング仕様

### カード全体

| 箇所 | トークン | 値 |
|------|----------|-----|
| カード内パディング | `YataSpacingTokens.md` | 16px |
| 第1行と第2行の間 | `YataSpacingTokens.sm` | 12px |

### 第1行（ヘッダー行）

| 箇所 | トークン | 値 |
|------|----------|-----|
| 受付コードとステータス間 | `YataSpacingTokens.sm` | 12px |
| 金額と支払い方法間 | `YataSpacingTokens.sm` | 12px |

### 第2行（情報統合行）

| 箇所 | トークン | 値 |
|------|----------|-----|
| アイコンとテキスト間 | `YataSpacingTokens.xs` | 8px |
| 各要素間（通常） | `YataSpacingTokens.xs` | 8px |
| 区切り文字前後 | `YataSpacingTokens.sm` | 12px |

### カード間

| 箇所 | トークン | 値 |
|------|----------|-----|
| カード間の余白 | `YataSpacingTokens.sm` | 12px |

---

## インタラクション仕様

### ホバー状態（デスクトップ）

```dart
// GestureDetectorの代わりにInkWellを使用
InkWell(
  onTap: onTap,
  borderRadius: YataRadiusTokens.borderRadiusCard,
  child: Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: BoxDecoration(
      color: YataColorTokens.surface,
      borderRadius: YataRadiusTokens.borderRadiusCard,
      border: Border.all(color: YataColorTokens.border),
    ),
    child: /* カード内容 */,
  ),
)
```

**ホバー時の変化**:
- 背景色: `YataColorTokens.surface` → `YataColorTokens.surfaceAlt`
- カーソル: `SystemMouseCursors.click`
- 視覚的フィードバック: `InkWell`のリップル効果

### タップ状態（モバイル）

- タップ時: `InkWell`のスプラッシュ効果
- タップ後: 詳細ダイアログが表示される

### アニメーション

カード表示時のアニメーション（オプション）:

```dart
// ListView.builder内でindexに応じた遅延アニメーション
AnimatedOpacity(
  opacity: _isVisible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 200 + (index * 50)),
  child: /* カード */,
)
```

---

## レスポンシブ対応

### モバイル（< 768px）での調整

#### 変更点1: 支払い方法を非表示

第1行の右側を金額のみにする:

```
[A-001]  [●完了]                      ¥1,500
```

#### 変更点2: 顧客名を短縮

顧客名の最大文字数を制限:

```dart
Text(
  order.customerName?.substring(0, min(8, order.customerName!.length)) ?? "名前なし",
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: YataColorTokens.textSecondary,
  ),
)
```

#### 変更点3: パディング削減

カード内パディングをさらに削減:

```dart
padding: EdgeInsets.all(
  ResponsiveHelper.isMobile(context) 
    ? YataSpacingTokens.sm 
    : YataSpacingTokens.md
),
```

### タブレット（768-1024px）

デスクトップと同じレイアウトを使用（調整不要）。

---

## アクセシビリティ対応

### セマンティクス

```dart
Semantics(
  label: "注文 ${order.orderNumber ?? '受付コード未設定'}, "
         "ステータス: ${OrderStatusPresentation.label(order.status)}, "
         "金額: ${currencyFormat.format(order.actualAmount)}円, "
         "顧客名: ${order.customerName ?? '名前なし'}",
  button: true,
  onTap: onTap,
  child: /* カード */,
)
```

### カラーコントラスト

全ての文字色が背景色に対して十分なコントラスト比を持つことを確認:

- 主要テキスト（`textPrimary`）: 4.5:1以上
- 副次テキスト（`textSecondary`）: 3:1以上

### タップ可能領域

カード全体がタップ可能で、最小タップ領域（48x48px）を満たしていることを確認。

---

## 実装時の注意点

### 1. 注文明細サマリーの省略

長いメニュー名が含まれる場合、適切に省略されることを確認:

```dart
Text(
  _buildOrderItemsSummary(order.items),
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: YataColorTokens.textSecondary,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis, // 重要: 省略記号を表示
)
```

### 2. 区切り文字の視覚的バランス

区切り文字（`|`）が他の要素と適切に整列するよう、スペーシングを調整:

```dart
const SizedBox(width: YataSpacingTokens.sm), // 前
Text("|", style: ...),
const SizedBox(width: YataSpacingTokens.sm), // 後
```

### 3. アイコンサイズの統一

全てのアイコンを14pxに統一し、視覚的な一貫性を保つ:

```dart
const Icon(
  Icons.person_outline,
  size: 14, // 統一
  color: YataColorTokens.textSecondary,
)
```

### 4. 金額のフォーマット

既存の`NumberFormat`を使用し、カンマ区切りを保つ:

```dart
final NumberFormat currencyFormat = NumberFormat("#,###");
Text("¥${currencyFormat.format(order.actualAmount)}")
```

---

## エッジケースの処理

### 1. 顧客名が長い場合

```dart
// 顧客名セクションをFlexibleでラップ
Flexible(
  child: Row(
    children: <Widget>[
      const Icon(Icons.person_outline, size: 14, ...),
      const SizedBox(width: YataSpacingTokens.xs),
      Flexible(
        child: Text(
          order.customerName ?? "名前なし",
          style: ...,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  ),
)
```

### 2. 受付コードが長い場合

通常は短い（A-001など）が、念のため省略処理を追加:

```dart
Text(
  order.orderNumber ?? "受付コード未設定",
  style: ...,
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

### 3. 商品が1つもない場合

```dart
String _buildOrderItemsSummary(List<OrderItemViewData> items) {
  if (items.isEmpty) return "商品なし"; // エッジケース処理
  // ...
}
```

### 4. 金額が大きい場合（1,000,000円以上）

既存のフォーマットで対応可能（`#,###`がカンマ区切りを適用）。

---

## 視覚的比較

### Before（現状）

```
┌──────────────────────────────────────────┐
│                                          │
│  24px padding                            │
│  ┌────────────────────────────────────┐  │
│  │ [A-001] [●完了]     ¥1,500 [現金]│  │
│  └────────────────────────────────────┘  │
│                                          │
│  16px spacing                            │
│  ┌────────────────────────────────────┐  │
│  │ 👤田中太郎          🕐10/01 12:30  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  16px spacing                            │
│  ┌────────────────────────────────────┐  │
│  │ 2x ラーメン           ¥1,000       │  │
│  │ 1x 餃子               ¥500         │  │
│  └────────────────────────────────────┘  │
│                                          │
│  24px padding                            │
└──────────────────────────────────────────┘
Total: ~148px
```

### After（改善後）

```
┌──────────────────────────────────────────┐
│  16px padding                            │
│  ┌────────────────────────────────────┐  │
│  │ [A-001] [●完了]     ¥1,500 [現金]│  │
│  └────────────────────────────────────┘  │
│                                          │
│  12px spacing                            │
│  ┌────────────────────────────────────┐  │
│  │ 👤田中太郎|🕐10/01 12:30|🛍️ラーメン, 餃子│  │
│  └────────────────────────────────────┘  │
│  16px padding                            │
└──────────────────────────────────────────┘
Total: ~88px
```

**削減**: 148px → 88px（約40%削減）

---

## サンプルコード（完全版）

以下は、改善後の`_OrderHistoryCard`の実装例（簡略版）:

```dart
class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order, required this.onTap});

  final OrderHistoryViewData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat("MM/dd HH:mm");
    final NumberFormat currencyFormat = NumberFormat("#,###");

    return InkWell(
      onTap: onTap,
      borderRadius: YataRadiusTokens.borderRadiusCard,
      child: Container(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
        decoration: BoxDecoration(
          color: YataColorTokens.surface,
          borderRadius: YataRadiusTokens.borderRadiusCard,
          border: Border.all(color: YataColorTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 第1行: ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        order.orderNumber ?? "受付コード未設定",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: YataColorTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: YataSpacingTokens.sm),
                      _OrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Text(
                      "¥${currencyFormat.format(order.actualAmount)}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: YataColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.sm),
                    Text(
                      paymentMethodLabel(order.paymentMethod),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: YataColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: YataSpacingTokens.sm),

            // 第2行: 情報統合行
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
          ],
        ),
      ),
    );
  }

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
}
```

---

## テーマとの整合性

### デザイントークンの遵守

全ての色・スペーシング・タイポグラフィは、既存のデザイントークンを使用:

- `YataColorTokens.*`
- `YataSpacingTokens.*`
- `YataTypographyTokens.*`
- `YataRadiusTokens.*`

### Material Design準拠

FlutterのMaterial Designコンポーネント（`InkWell`、`Theme`など）を活用し、プラットフォーム標準に準拠。

---

## 将来的な拡張性

### オプション機能の追加

1. **カード表示密度の切り替え**
   - ユーザー設定で「コンパクト」「標準」「詳細」を選択可能

2. **カスタマイズ可能な情報表示**
   - 表示する情報項目をユーザーが選択可能

3. **ソート・フィルターの拡張**
   - カード上でのクイックアクション（再注文、印刷など）

---

## まとめ

本設計により、注文履歴カードの高さを約40%削減し、一覧性を大幅に向上させることができる。

実装時は、本ドキュメントの仕様に従い、既存のデザインシステムとの整合性を保ちながら開発を進めること。

---

*本ドキュメントは実装時に詳細が調整される可能性があります。*
