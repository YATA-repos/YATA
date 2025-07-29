import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/app_badge.dart";

/// MenuItemCard - メニューアイテム表示カード
///
/// 既存のAppTextTheme価格表示・AppColors在庫色を活用し、
/// レストラン・屋台のメニューアイテム表示に最適化されたカードです。
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.stockCount,
    this.isSelected = false,
    this.onTap,
    this.onAddToCart,
    this.variant = MenuCardVariant.default_,
    super.key,
  });

  final String name;
  final int price;
  final String? description;
  final String? imageUrl;
  final String? category;
  final bool isAvailable;
  final int? stockCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final MenuCardVariant variant;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: _getCardVariant(),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 画像エリア
        _buildImageSection(),

        // コンテンツエリア
        Padding(
          padding: AppLayout.paddingSmall,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // タイトル・カテゴリ行
              _buildTitleSection(),

              AppLayout.vSpacerSmall,

              // 説明文
              if (description != null) ...<Widget>[
                Text(
                  description!,
                  style: AppTextTheme.cardDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                AppLayout.vSpacerSmall,
              ],

              // 価格・在庫・アクション行
              _buildBottomSection(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildImageSection() => AspectRatio(
    aspectRatio: 16 / 9,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: <Widget>[
          // 画像またはプレースホルダー
          SizedBox.expand(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                          _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // 在庫状態バッジ（右上）
          Positioned(top: 8, right: 8, child: _buildStockBadge()),

          // 選択状態オーバーレイ
          if (isSelected) ...<Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(LucideIcons.check, color: AppColors.primary, size: 32),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildImagePlaceholder() => Container(
    color: AppColors.muted,
    child: const Center(
      child: Icon(LucideIcons.utensils, size: 48, color: AppColors.mutedForeground),
    ),
  );

  Widget _buildStockBadge() {
    if (!isAvailable) {
      return AppBadge(text: "売切れ", variant: BadgeVariant.outOfStock, size: BadgeSize.small);
    }

    if (stockCount != null && stockCount! <= 5) {
      return AppBadge(text: "残量少", variant: BadgeVariant.lowStock, size: BadgeSize.small);
    }

    return const SizedBox.shrink();
  }

  Widget _buildTitleSection() => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(name, style: AppTextTheme.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (category != null) ...<Widget>[
              AppLayout.vSpacerTiny,
              Text(
                category!,
                style: AppTextTheme.cardDescription.copyWith(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _buildBottomSection() => Row(
    children: <Widget>[
      // 価格表示
      Text(
        _formatPrice(price),
        style: AppTextTheme.priceText.copyWith(
          fontWeight: FontWeight.bold,
          color: isAvailable ? AppColors.foreground : AppColors.mutedForeground,
        ),
      ),

      const Spacer(),

      // カートに追加ボタン
      if (isAvailable && onAddToCart != null) ...<Widget>[
        SizedBox(
          height: 32,
          child: AppButton(
            text: "追加",
            size: ButtonSize.small,
            icon: const Icon(LucideIcons.plus, size: 14),
            onPressed: onAddToCart,
          ),
        ),
      ] else if (!isAvailable) ...<Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: AppLayout.borderRadiusTiny),
          child: Text(
            "利用不可",
            style: AppTextTheme.cardDescription.copyWith(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    ],
  );

  CardVariant _getCardVariant() {
    if (isSelected) {
      return CardVariant.primary;
    }
    if (!isAvailable) {
      return CardVariant.muted;
    }

    return switch (variant) {
      MenuCardVariant.default_ => CardVariant.default_,
      MenuCardVariant.featured => CardVariant.primary,
      MenuCardVariant.popular => CardVariant.success,
      MenuCardVariant.new_ => CardVariant.warning,
    };
  }

  String _formatPrice(int price) =>
      "¥${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')}";
}

/// コンパクトメニューアイテムカード（リスト表示用）
class CompactMenuItemCard extends StatelessWidget {
  const CompactMenuItemCard({
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.stockCount,
    this.onTap,
    this.onAddToCart,
    super.key,
  });

  final String name;
  final int price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final int? stockCount;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: isAvailable ? CardVariant.default_ : CardVariant.muted,
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: <Widget>[
        // サムネイル画像
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: AppLayout.borderRadiusSmall),
          child: ClipRRect(
            borderRadius: AppLayout.borderRadiusSmall,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                        _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),

        AppLayout.hSpacerSmall,

        // メインコンテンツ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: AppTextTheme.cardTitle.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (description != null) ...<Widget>[
                AppLayout.vSpacerTiny,
                Text(
                  description!,
                  style: AppTextTheme.cardDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(_formatPrice(price), style: AppTextTheme.priceText),
                  const SizedBox(width: 8),
                  _buildStockIndicator(),
                ],
              ),
            ],
          ),
        ),

        // アクションボタン
        if (isAvailable && onAddToCart != null) ...<Widget>[
          AppLayout.hSpacerSmall,
          SizedBox(
            width: 32,
            height: 32,
            child: AppIconButton(
              icon: const Icon(LucideIcons.plus, size: 16),
              onPressed: onAddToCart,
              size: ButtonSize.small,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildImagePlaceholder() =>
      const Center(child: Icon(LucideIcons.utensils, size: 24, color: AppColors.mutedForeground));

  Widget _buildStockIndicator() {
    if (!isAvailable) {
      return AppBadge(text: "売切れ", variant: BadgeVariant.outOfStock, size: BadgeSize.small);
    }

    if (stockCount != null && stockCount! <= 5) {
      return AppBadge(text: "残り少", variant: BadgeVariant.lowStock, size: BadgeSize.small);
    }

    return const SizedBox.shrink();
  }

  String _formatPrice(int price) =>
      "¥${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')}";
}

/// メニューカードバリアント
enum MenuCardVariant {
  default_, // デフォルト
  featured, // おすすめ
  popular, // 人気
  new_, // 新メニュー
}
