# 注文ページ - 行小計の視認性改善アプローチ

## 概要

注文ページ（`order_management_page.dart`）の右ペイン「現在の注文」セクションにおいて、各商品の行小計（lineSubtotal）の視認性が低いという問題を解決するためのアプローチを検討する。

## 関連情報

- **タスクID**: UI/UX-Enhancement-1
- **Priority**: P2
- **対象ファイル**: `lib/features/order/presentation/pages/order_management_page.dart`
- **対象ウィジェット**: `_OrderRow`

## 現状分析

### 現在の実装

`_OrderRow` ウィジェットは、レスポンシブレイアウトを採用しており、画面幅に応じて2つのレイアウトパターンを使い分けている。

#### 1. 広幅レイアウト（640px以上）

```dart
Row(
  children: [
    Expanded(flex: 6, child: Text(name)),        // 品名
    Expanded(flex: 2, child: Text(unitPrice)),   // 単価
    YataQuantityStepper(...),                    // 数量
    Expanded(flex: 2, child: Text(subtotal)),    // 小計
    IconButton(...)                               // 削除ボタン
  ]
)
```

**現在のスタイル**:
```dart
final TextStyle subtotalStyle = (textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium)
    .copyWith(color: YataColorTokens.textPrimary, fontWeight: FontWeight.w600);
```

#### 2. 狭幅レイアウト（640px未満）

2行構成:
- 1行目: 品名 | 単価 | 削除ボタン
- 2行目: 数量ステッパー | 行小計

### 視認性の問題点

1. **フォントサイズが小さい**
   - `bodyMedium`（14px, fontWeight: w500）をベースにしているため、金額情報として目立たない
   - 単価と同じスタイルベースのため、差別化が不十分

2. **視覚的な強調が不足**
   - `fontWeight: w600`のみで、色や背景による強調がない
   - 数値が右揃えで配置されているが、視線の誘導が弱い

3. **スペーシングの問題**
   - `Expanded(flex: 2)`により、他の要素との相対的なサイズが固定されている
   - 商品名に割り当てられた`flex: 6`が大きく、小計の存在感が薄い

4. **コンテキスト不足**
   - 列ヘッダーに「小計」と表示されているが、データ行では数値のみ
   - 狭幅レイアウトでは特に、何の金額かが不明確

## 改善アプローチ

### A. 最小限のスタイル調整（推奨度: ★★★★★）

**目的**: コードの変更を最小限に抑えつつ、視認性を向上させる

**変更内容**:
1. フォントサイズの拡大
2. カラーの変更（重要度の高さを示す）
3. フォントウェイトの強化

```dart
// 行小計用の専用スタイルを定義
final TextStyle subtotalStyle = (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
    .copyWith(
      color: YataColorTokens.textPrimary,
      fontWeight: FontWeight.w700,  // w600 → w700
    );
```

**メリット**:
- 最小限の変更で実装可能
- 既存のレイアウト構造を維持
- デザインの一貫性を保ちやすい

**デメリット**:
- 劇的な改善にはならない可能性
- レイアウトの根本的な問題は解決しない

**実装難易度**: ★☆☆☆☆ (非常に簡単)
**効果**: ★★★☆☆ (中程度)

---

### B. 視覚的強調の追加（推奨度: ★★★★☆）

**目的**: 背景色や枠線を使って小計を目立たせる

**変更内容**:
1. 小計に軽い背景色を追加
2. 角丸の軽い枠線で囲む

```dart
// 小計表示部分
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: YataSpacingTokens.xs,
    vertical: YataSpacingTokens.xxs,
  ),
  decoration: BoxDecoration(
    color: YataColorTokens.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(YataRadiusTokens.small),
  ),
  child: Text(
    lineSubtotalLabel,
    style: subtotalStyle,
    overflow: TextOverflow.ellipsis,
  ),
)
```

**メリット**:
- 視覚的に明確に区別できる
- 金額情報としての重要性が伝わる
- 実装がそれほど複雑ではない

**デメリット**:
- 視覚的なノイズが増える可能性
- 他のUIコンポーネントとのバランス調整が必要
- 色の選択によっては過剰な装飾に見える

**実装難易度**: ★★☆☆☆ (簡単)
**効果**: ★★★★☆ (高い)

---

### C. レイアウト比率の調整（推奨度: ★★★☆☆）

**目的**: 小計に割り当てられるスペースを拡大する

**変更内容**:
品名と小計のflexバランスを調整

```dart
// 現在: 品名(flex: 6) / 単価(flex: 2) / 小計(flex: 2)
// 提案: 品名(flex: 5) / 単価(flex: 2) / 小計(flex: 3)
Row(
  children: [
    Expanded(flex: 5, child: Text(name)),        // 6 → 5
    Expanded(flex: 2, child: Text(unitPrice)),
    YataQuantityStepper(...),
    Expanded(flex: 3, child: Text(subtotal)),    // 2 → 3
    IconButton(...)
  ]
)
```

**メリット**:
- 小計により多くのスペースを割り当てられる
- 視覚的なバランスが改善される

**デメリット**:
- 商品名の表示領域が減る（長い商品名が切れる可能性）
- 全体のレイアウトバランスへの影響が大きい
- 他の画面との一貫性を検討する必要がある

**実装難易度**: ★☆☆☆☆ (非常に簡単)
**効果**: ★★☆☆☆ (限定的)

---

### D. アイコン/プレフィックスの追加（推奨度: ★★☆☆☆）

**目的**: 金額であることを明示的に示す

**変更内容**:
小計の前に通貨記号アイコンや「小計:」というプレフィックスを追加

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '小計: ',
      style: (textTheme.labelSmall ?? YataTypographyTokens.labelSmall)
          .copyWith(color: YataColorTokens.textSecondary),
    ),
    Text(lineSubtotalLabel, style: subtotalStyle),
  ],
)
```

**メリット**:
- 何の金額かが明確になる
- 狭幅レイアウトで特に効果的

**デメリット**:
- 広幅レイアウトでは列ヘッダーと重複
- 表示領域が狭い場合、さらに圧迫される
- 冗長に感じられる可能性

**実装難易度**: ★☆☆☆☆ (非常に簡単)
**効果**: ★★☆☆☆ (限定的)

---

### E. 複合アプローチ（推奨度: ★★★★★）

**目的**: 複数の改善策を組み合わせて、最大の効果を得る

**推奨組み合わせ**: **A (スタイル調整) + B (視覚的強調)**

**実装例**:
```dart
// 行小計の表示部分
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: YataSpacingTokens.sm,
    vertical: YataSpacingTokens.xs,
  ),
  decoration: BoxDecoration(
    color: YataColorTokens.primarySoft,  // または neutral100等の落ち着いた色
    borderRadius: BorderRadius.circular(YataRadiusTokens.small),
  ),
  child: Text(
    lineSubtotalLabel,
    style: (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
        .copyWith(
          color: YataColorTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
    overflow: TextOverflow.ellipsis,
  ),
)
```

**メリット**:
- 複数の改善効果を同時に得られる
- 視覚的な階層が明確になる
- 金額情報としての重要性が適切に伝わる

**デメリット**:
- やや実装量が増える
- 色の選定が重要（過剰な装飾を避ける）

**実装難易度**: ★★☆☆☆ (簡単)
**効果**: ★★★★★ (非常に高い)

---

## 推奨実装案

### 段階的アプローチ

#### フェーズ1: スタイル調整のみ（最小限の変更）

まず**アプローチA**を実装し、効果を確認する。

```dart
final TextStyle subtotalStyle = (textTheme.titleMedium ?? YataTypographyTokens.titleMedium)
    .copyWith(
      color: YataColorTokens.textPrimary,
      fontWeight: FontWeight.w700,
    );
```

**判断基準**:
- フォントサイズが`bodyMedium`(14px) → `titleMedium`(16px)に変更
- フォントウェイトが`w600` → `w700`に変更
- 視覚的なノイズなし、実装コスト最小

#### フェーズ2: 必要に応じて視覚的強調を追加

フェーズ1の効果が不十分な場合、**アプローチB**を追加する。

```dart
Expanded(
  flex: 2,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: YataSpacingTokens.xs,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: YataColorTokens.neutral100,  // 控えめな背景色
      borderRadius: BorderRadius.circular(YataRadiusTokens.small),
    ),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        lineSubtotalLabel,
        style: subtotalStyle,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
)
```

**色の選択肢**:
1. `YataColorTokens.neutral100` - 最も控えめ、どの画面でも違和感なし
2. `YataColorTokens.primarySoft` - ブランドカラーで統一感あり
3. `YataColorTokens.successSoft.withValues(alpha: 0.3)` - 金額のポジティブな印象

推奨: `YataColorTokens.neutral100` (過剰な装飾を避けつつ視認性向上)

---

## レスポンシブ対応

狭幅レイアウト（640px未満）でも同様の改善を適用する。

```dart
if (isNarrow) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1行目: 品名 | 単価 | 削除ボタン
      Row(...),
      const SizedBox(height: YataSpacingTokens.xs),
      // 2行目: 数量ステッパー | 小計
      Row(
        children: [
          YataQuantityStepper(...),
          const SizedBox(width: YataSpacingTokens.md),
          Expanded(
            child: Container(  // 同じ視覚的強調を適用
              padding: const EdgeInsets.symmetric(
                horizontal: YataSpacingTokens.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: YataColorTokens.neutral100,
                borderRadius: BorderRadius.circular(YataRadiusTokens.small),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(lineSubtotalLabel, style: subtotalStyle),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
```

---

## 他の画面への影響

### 確認が必要な箇所

1. **注文履歴画面** (`order_history_page.dart`)
   - 現在はスタブ実装のため、将来的に同様のスタイルを使用する可能性
   
2. **共通コンポーネント** (`YataOrderItemTile` in `lib/shared/patterns/lists/order_item_tile.dart`)
   - 注文アイテムの表示に使用されている
   - 同様の視認性の問題がある可能性
   - 今回の改善を適用するか検討が必要

### 一貫性の確保

小計の表示スタイルをプロジェクト全体で統一するため、以下の対応を検討:

1. **共通スタイルの定義**
   ```dart
   // lib/shared/foundations/tokens/typography_tokens.dart に追加
   static const TextStyle priceEmphasis = TextStyle(
     fontFamily: _fontFamily,
     fontSize: 16,
     fontWeight: FontWeight.w700,
     height: 1.4,
   );
   ```

2. **共通ウィジェットの作成**
   ```dart
   // lib/shared/components/data_display/price_label.dart
   class YataPriceLabel extends StatelessWidget {
     const YataPriceLabel({
       required this.amount,
       this.emphasis = false,
       super.key,
     });
     
     final String amount;
     final bool emphasis;  // 小計など重要な金額に使用
     
     @override
     Widget build(BuildContext context) {
       // 統一されたスタイルで表示
     }
   }
   ```

---

## 実装チェックリスト

### フェーズ1（最小限の変更）
- [ ] `_OrderRow`ウィジェットの`subtotalStyle`を`titleMedium`ベースに変更
- [ ] フォントウェイトを`w700`に変更
- [ ] 広幅レイアウトでの表示確認
- [ ] 狭幅レイアウトでの表示確認
- [ ] 視認性の改善効果を確認

### フェーズ2（必要な場合のみ）
- [ ] 小計表示を`Container`で囲む実装
- [ ] 背景色を`YataColorTokens.neutral100`に設定
- [ ] paddingとborderRadiusの調整
- [ ] 広幅・狭幅両方のレイアウトに適用
- [ ] 他のUI要素とのバランス確認
- [ ] 過剰な装飾になっていないか確認

### 追加検討事項
- [ ] `YataOrderItemTile`への同様の改善適用の検討
- [ ] 共通スタイル/コンポーネント化の検討
- [ ] デザインレビューの実施
- [ ] ユーザーフィードバックの収集

---

## 関連課題

- TODO.md: UI/UX-Enhancement-1「注文カート行内小計の表示を改善する」
- 将来的な検討: 注文履歴画面での金額表示の一貫性

---

## 参考情報

### 現在使用されているトークン

```dart
// Typography
YataTypographyTokens.bodyMedium  // fontSize: 14, fontWeight: w500
YataTypographyTokens.titleMedium // fontSize: 16, fontWeight: w600

// Colors
YataColorTokens.textPrimary      // メインテキスト
YataColorTokens.textSecondary    // セカンダリテキスト（単価等）
YataColorTokens.primarySoft      // プライマリカラーの柔らかい版
YataColorTokens.neutral100       // ニュートラルな背景色

// Spacing
YataSpacingTokens.xs   // 4
YataSpacingTokens.sm   // 8
YataSpacingTokens.md   // 16

// Radius
YataRadiusTokens.small  // 4
YataRadiusTokens.medium // 8
```

---

## まとめ

**最推奨アプローチ**: 
1. まず**フェーズ1（スタイル調整）**を実装（アプローチA）
2. 効果が不十分な場合、**フェーズ2（視覚的強調）**を追加（アプローチB）

この段階的アプローチにより、最小限の変更で最大の効果を得られ、過剰な装飾を避けることができる。

**実装優先度**: P2（TODO.mdと一致）
**推定工数**: XS～S（フェーズ1のみなら0.5日、フェーズ2含めても1日以内）
