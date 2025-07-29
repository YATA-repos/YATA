# Phase 2: 共通Widgetライブラリ実装計画（既存テーマ活用版）

## 概要

Phase 1で確認した既存の完備されたテーマシステム（AppColors, AppTextTheme）を最大限活用し、UI層専用の共通Widgetライブラリを実装する。新規作成に集中し、既存資産との統合により高品質なコンポーネントを効率的に構築する。

## 1. 既存テーマシステム活用方針

### 1.1 ✅ 活用可能な既存資産

#### 完備されたテーマシステム
- **AppColors**: 業務固有色（調理中、在庫状態等）を含む68色の包括的定義
- **AppTextTheme**: カード、ボタン、テーブル等、UI用途別の詳細テキストスタイル
- **業務特化**: 屋台・レストラン業務に最適化された色・テキスト定義

#### 活用例（既存定義）
```dart
// 既存の業務固有色定義を直接活用
AppColors.cooking        // 調理中（オレンジ）
AppColors.inStock        // 在庫あり（グリーン）
AppColors.lowStock       // 在庫少（イエロー）
AppColors.outOfStock     // 在庫切れ（レッド）

// 既存のテキストスタイル定義を直接活用
AppTextTheme.cardTitle           // カードタイトル用
AppTextTheme.priceText          // 価格表示用
AppTextTheme.buttonText         // ボタンテキスト用
AppTextTheme.tableHeader        // テーブルヘッダー用
```

### 1.2 実装アプローチ

#### 既存テーマの直接活用
新規Widgetは既存のAppColors・AppTextThemeを直接参照して実装

#### 一貫性の確保
全Widgetで統一されたテーマシステムを使用し、デザインの一貫性を保つ

## 2. 実装優先順位（既存テーマ活用版）

### 優先度 1: 基本コンポーネント
1. **AppButton** - 既存AppTextTheme.buttonText活用
2. **AppCard** - 既存AppColors.card活用  
3. **AppTextField** - 既存AppTextTheme.inputText活用

### 優先度 2: 業務特化コンポーネント
4. **StatsCard** - 既存AppColors業務色 + AppTextTheme活用
5. **MenuItemCard** - 既存AppTextTheme.priceText等活用
6. **AppBadge** - 既存AppColors.success/warning/danger活用

### 優先度 3: ナビゲーション
7. **MainNavigation** - 既存AppTextTheme.navigationText活用
8. **MobileBottomNavigation** - 既存AppTextTheme.mobileNavText活用

## 3. 既存テーマ活用型Widget実装

### 3.1 AppButton（既存テーマ完全活用）

#### 実装仕様
```dart
// shared/widgets/buttons/app_button.dart
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  
  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _getButtonStyle(),
      child: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(text),
              ],
            ),
    );
  }

  ButtonStyle _getButtonStyle() {
    // 既存テーマシステムを直接活用
    final (backgroundColor, foregroundColor, textStyle) = switch (variant) {
      ButtonVariant.primary => (
        AppColors.primary,
        AppColors.primaryForeground,
        AppTextTheme.buttonText,
      ),
      ButtonVariant.secondary => (
        AppColors.secondary,
        AppColors.secondaryForeground,
        AppTextTheme.buttonText,
      ),
      ButtonVariant.danger => (
        AppColors.danger,
        AppColors.dangerForeground,
        AppTextTheme.buttonText,
      ),
      ButtonVariant.outline => (
        Colors.transparent,
        AppColors.primary,
        AppTextTheme.buttonTextSecondary,
      ),
      // 既存の業務固有色も活用
      ButtonVariant.complete => (
        AppColors.complete,
        AppColors.completeForeground,
        AppTextTheme.buttonText,
      ),
    };

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textStyle: textStyle, // 既存AppTextThemeを直接使用
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: variant == ButtonVariant.outline
            ? BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
    );
  }

  EdgeInsets _getPadding() => switch (size) {
    ButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ButtonSize.medium => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ButtonSize.large => const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  };
}

enum ButtonVariant { primary, secondary, outline, danger, complete }
enum ButtonSize { small, medium, large }
```

#### 実装タスク
- [ ] 基本実装（既存テーマ活用）
- [ ] バリアント別スタイル（AppColors直接使用）
- [ ] ローディング状態実装
- [ ] Widget テスト作成

### 3.2 StatsCard（業務特化色活用）

#### 実装仕様
```dart
// shared/widgets/cards/stats_card.dart
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StatsCardVariant variant;
  final VoidCallback? onTap;
  final Widget? trend;
  
  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.variant = StatsCardVariant.default_,
    this.onTap,
    this.trend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card, // 既存色使用
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: _getVariantColor(), // 既存業務色活用
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextTheme.cardTitle, // 既存テキストスタイル
                    ),
                  ),
                  if (trend != null) trend!,
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextTheme.priceLarge, // 既存の価格表示スタイル活用
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextTheme.cardDescription, // 既存スタイル
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVariantColor() => switch (variant) {
    StatsCardVariant.default_ => AppColors.primary,
    StatsCardVariant.success => AppColors.success,
    StatsCardVariant.warning => AppColors.warning,
    StatsCardVariant.danger => AppColors.danger,
    // 業務固有色も活用
    StatsCardVariant.stock => AppColors.inStock,
    StatsCardVariant.lowStock => AppColors.lowStock,
    StatsCardVariant.cooking => AppColors.cooking,
  };
}

enum StatsCardVariant { 
  default_, success, warning, danger, 
  stock, lowStock, cooking // 業務固有バリアント
}
```

### 3.3 MenuItemCard（価格表示特化）

#### 実装仕様
```dart
// shared/widgets/cards/menu_item_card.dart
class MenuItemCard extends StatelessWidget {
  final String name;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  final VoidCallback? onAdd;
  final bool isSelected;
  final int? stockCount;
  
  const MenuItemCard({
    Key? key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.onAdd,
    this.isSelected = false,
    this.stockCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected 
          ? AppColors.primaryHover // 既存ホバー色
          : AppColors.card,
      child: InkWell(
        onTap: isAvailable ? onAdd : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像エリア
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : const Icon(
                        Icons.fastfood,
                        size: 48,
                        color: AppColors.mutedForeground,
                      ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextTheme.cardTitle, // 既存スタイル
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        '¥${price.toString().replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (match) => '${match[1]},',
                        )}',
                        style: AppTextTheme.priceText, // 既存価格スタイル
                      ),
                      const Spacer(),
                      
                      // 在庫状態表示（既存業務色活用）
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.outOfStock, // 既存在庫色
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '売切れ',
                            style: AppTextTheme.badgeText,
                          ),
                        )
                      else if (stockCount != null && stockCount! < 5)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lowStock, // 既存低在庫色
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '残り少',
                            style: AppTextTheme.badgeText,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3.4 AppBadge（ステータス表示特化）

#### 実装仕様
```dart
// shared/widgets/common/app_badge.dart
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Widget? icon;
  final BadgeSize size;
  
  const AppBadge({
    Key? key,
    required this.text,
    this.variant = BadgeVariant.default_,
    this.icon,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = _getColors();
    
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          size == BadgeSize.small ? 4 : 6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              (icon as Icon).icon,
              color: textColor,
              size: _getIconSize(),
            ),
            SizedBox(width: size == BadgeSize.small ? 4 : 6),
          ],
          Text(
            text,
            style: AppTextTheme.badgeText.copyWith(
              color: textColor,
              fontSize: _getFontSize(),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors() => switch (variant) {
    BadgeVariant.default_ => (AppColors.muted, AppColors.foreground),
    BadgeVariant.success => (AppColors.success, AppColors.successForeground),
    BadgeVariant.warning => (AppColors.warning, AppColors.warningForeground),
    BadgeVariant.danger => (AppColors.danger, AppColors.dangerForeground),
    // 業務ステータス色活用
    BadgeVariant.cooking => (AppColors.cooking, AppColors.cookingForeground),
    BadgeVariant.complete => (AppColors.complete, AppColors.completeForeground),
    BadgeVariant.inStock => (AppColors.inStock, AppColors.trueWhite),
    BadgeVariant.lowStock => (AppColors.lowStock, AppColors.trueBlack),
    BadgeVariant.outOfStock => (AppColors.outOfStock, AppColors.trueWhite),
  };

  EdgeInsets _getPadding() => switch (size) {
    BadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    BadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    BadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  };

  double _getIconSize() => switch (size) {
    BadgeSize.small => 12,
    BadgeSize.medium => 14,
    BadgeSize.large => 16,
  };

  double _getFontSize() => switch (size) {
    BadgeSize.small => 10,
    BadgeSize.medium => 12,
    BadgeSize.large => 14,
  };
}

enum BadgeVariant { 
  default_, success, warning, danger,
  cooking, complete, inStock, lowStock, outOfStock, // 業務固有
}
enum BadgeSize { small, medium, large }
```

## 4. 実装スケジュール（効率化版）

### Week 1: 基本コンポーネント（既存テーマ活用）
- [ ] AppButton実装（AppColors/AppTextTheme直接使用）
- [ ] AppCard実装（AppColors活用）
- [ ] AppTextField実装（AppTextTheme活用）

### Week 2: 業務特化コンポーネント
- [ ] StatsCard実装（業務固有色活用）
- [ ] MenuItemCard実装（価格表示スタイル活用）
- [ ] AppBadge実装（ステータス色活用）

### Week 3: ナビゲーション・フォーム
- [ ] MainNavigation実装（既存ナビゲーションスタイル活用）
- [ ] MobileBottomNavigation実装
- [ ] SearchField, CategoryFilter実装

### Week 4: 完成・統合テスト
- [ ] LoadingIndicator, EmptyState実装
- [ ] 統合テスト・リファクタリング
- [ ] ドキュメント整備

## 5. 既存テーマ活用によるメリット

### 5.1 開発効率向上
- **スタイル定義不要**: 既存の68色・詳細テキストスタイルを直接活用
- **デザイン一貫性**: 統一されたテーマによる自動的な一貫性確保
- **業務特化**: 屋台・レストラン業務に最適化済みの色・スタイル

### 5.2 品質向上
- **実績あるテーマ**: 既に定義・検証済みのテーマシステム
- **メンテナンス性**: 中央集約されたテーマ管理
- **拡張性**: 既存テーマへの追加・修正が全Widgetに反映

### 5.3 工数削減効果
- **元計画**: 4週間（テーマ設計 + Widget実装）
- **修正計画**: 4週間（Widget実装のみ、テーマ活用）
- **品質向上**: テーマ統一により高品質なUIコンポーネント

## 6. 完了条件

### 6.1 実装完了条件
- [ ] 全コンポーネントが既存テーマを活用している
- [ ] AppColors, AppTextThemeが適切に使用されている
- [ ] 業務固有色（調理中、在庫状態等）が活用されている
- [ ] レスポンシブ対応が完了している

### 6.2 品質完了条件
- [ ] Widget テストが作成されている
- [ ] デザインの一貫性が確保されている
- [ ] パフォーマンスが最適化されている
- [ ] アクセシビリティ対応が完了している

## 7. 次のPhaseとの連携

### Phase 3（画面実装）での活用
```dart
// 既存テーマを活用したWidgetの使用例
class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 統一されたテーマで一貫性のあるUI
          StatsCard(
            title: '今日の売上',
            value: '¥45,600',
            variant: StatsCardVariant.success, // 既存テーマ色
            icon: Icons.trending_up,
          ),
          MenuItemCard(
            name: 'チキンカレー',
            price: 800,
            isAvailable: true, // 自動的に既存在庫色が適用
          ),
          AppButton(
            text: '注文確定',
            variant: ButtonVariant.complete, // 既存業務色
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

この既存テーマ活用アプローチにより、高品質で一貫性のあるUIコンポーネントライブラリを効率的に構築する。