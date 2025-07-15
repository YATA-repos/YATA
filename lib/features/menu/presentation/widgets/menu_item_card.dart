import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_badge.dart";
import "../../../../shared/widgets/common/app_button.dart";
import "../../../../shared/widgets/common/app_card.dart";

/// メニューアイテムカードコンポーネント
///
/// メニュー選択画面、AppCard + AppButton統合
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.name,
    required this.price,
    super.key,
    this.description,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.preparationTime,
    this.allergens,
    this.nutrition,
    this.tags,
    this.onAdd,
    this.onQuickAdd,
    this.onViewDetails,
    this.customizeButton,
    this.currencySymbol = "¥",
    this.variant = CardVariant.basic,
  });

  /// メニュー名
  final String name;

  /// 価格
  final num price;

  /// 説明
  final String? description;

  /// 画像URL
  final String? imageUrl;

  /// カテゴリ
  final String? category;

  /// 利用可能
  final bool isAvailable;

  /// 人気商品
  final bool isPopular;

  /// 新商品
  final bool isNew;

  /// おすすめ
  final bool isRecommended;

  /// 調理時間（分）
  final int? preparationTime;

  /// アレルゲン
  final List<String>? allergens;

  /// 栄養情報
  final Map<String, String>? nutrition;

  /// タグ
  final List<String>? tags;

  /// 追加処理
  final VoidCallback? onAdd;

  /// クイック追加処理
  final VoidCallback? onQuickAdd;

  /// 詳細表示処理
  final VoidCallback? onViewDetails;

  /// カスタマイズボタン
  final Widget? customizeButton;

  /// 通貨記号
  final String currencySymbol;

  /// カードバリアント
  final CardVariant variant;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: variant,
    onTap: onViewDetails,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[if (imageUrl != null) _buildImage(context), _buildContent(context)],
    ),
  );

  Widget _buildImage(BuildContext context) => Stack(
    children: <Widget>[
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.spacing2)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.muted,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                      onError: (Object exception, StackTrace? stackTrace) {},
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    LucideIcons.image,
                    size: AppLayout.iconSizeLg,
                    color: AppColors.mutedForeground,
                  )
                : null,
          ),
        ),
      ),
      Positioned(top: AppLayout.spacing2, left: AppLayout.spacing2, child: _buildBadges(context)),
      if (!isAvailable)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.spacing2)),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.spacing3,
                  vertical: AppLayout.spacing2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppLayout.spacing1),
                ),
                child: Text(
                  "売り切れ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildBadges(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (isNew) AppBadge.text("NEW", size: BadgeSize.small),
      if (isPopular) ...<Widget>[
        if (isNew) const SizedBox(height: AppLayout.spacing1),
        AppBadge.text("人気", variant: BadgeVariant.warning, size: BadgeSize.small),
      ],
      if (isRecommended) ...<Widget>[
        if (isNew || isPopular) const SizedBox(height: AppLayout.spacing1),
        AppBadge.text("おすすめ", variant: BadgeVariant.success, size: BadgeSize.small),
      ],
    ],
  );

  Widget _buildContent(BuildContext context) => Padding(
    padding: AppLayout.padding4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        if (description != null) ...<Widget>[
          const SizedBox(height: AppLayout.spacing2),
          _buildDescription(context),
        ],
        if (tags != null && tags!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppLayout.spacing2),
          _buildTags(context),
        ],
        if (preparationTime != null || allergens != null) ...<Widget>[
          const SizedBox(height: AppLayout.spacing3),
          _buildInfo(context),
        ],
        const SizedBox(height: AppLayout.spacing4),
        _buildActions(context),
      ],
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isAvailable ? AppColors.foreground : AppColors.mutedForeground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category != null) ...<Widget>[
              const SizedBox(height: AppLayout.spacing1),
              Text(
                category!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: AppLayout.spacing2),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            "$currencySymbol${_formatCurrency(price)}",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isAvailable ? AppColors.foreground : AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildDescription(BuildContext context) => Text(
    description!,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isAvailable
          ? AppColors.mutedForeground
          : AppColors.mutedForeground.withValues(alpha: 0.5),
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  Widget _buildTags(BuildContext context) => Wrap(
    spacing: AppLayout.spacing1,
    runSpacing: AppLayout.spacing1,
    children: tags!
        .take(3)
        .map(
          (String tag) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.spacing2,
              vertical: AppLayout.spacing1 / 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppLayout.spacing1),
            ),
            child: Text(
              tag,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground, fontSize: 10),
            ),
          ),
        )
        .toList(),
  );

  Widget _buildInfo(BuildContext context) => Row(
    children: <Widget>[
      if (preparationTime != null) ...<Widget>[
        Icon(LucideIcons.clock, size: AppLayout.iconSizeSm, color: AppColors.mutedForeground),
        const SizedBox(width: AppLayout.spacing1),
        Text(
          "$preparationTime分",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
        ),
      ],
      if (preparationTime != null && allergens != null && allergens!.isNotEmpty)
        const SizedBox(width: AppLayout.spacing3),
      if (allergens != null && allergens!.isNotEmpty) ...<Widget>[
        Icon(LucideIcons.alertTriangle, size: AppLayout.iconSizeSm, color: AppColors.warning),
        const SizedBox(width: AppLayout.spacing1),
        Expanded(
          child: Text(
            "アレルゲン: ${allergens!.join(", ")}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ],
  );

  Widget _buildActions(BuildContext context) => Row(
    children: <Widget>[
      if (customizeButton != null) ...<Widget>[
        customizeButton!,
        const SizedBox(width: AppLayout.spacing2),
      ],
      Expanded(
        child: AppButton.text(
          isAvailable ? "カートに追加" : "売り切れ",
          onPressed: isAvailable ? onAdd : null,
          variant: isAvailable ? ButtonVariant.primary : ButtonVariant.ghost,
          isFullWidth: true,
          icon: isAvailable ? LucideIcons.plus : null,
        ),
      ),
      if (onQuickAdd != null && isAvailable) ...<Widget>[
        const SizedBox(width: AppLayout.spacing2),
        Tooltip(
          message: "クイック追加",
          child: AppButton.text(
            "",
            onPressed: onQuickAdd!,
            variant: ButtonVariant.secondary,
            icon: LucideIcons.zap,
          ),
        ),
      ],
    ],
  );

  String _formatCurrency(num amount) => amount.toInt().toString().replaceAllMapped(
    RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
    (Match match) => "${match[1]},",
  );
}

/// メニューアイテム情報
class MenuItemInfo {
  const MenuItemInfo({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.preparationTime,
    this.allergens,
    this.nutrition,
    this.tags,
    this.options,
  });

  /// ID
  final String id;

  /// メニュー名
  final String name;

  /// 価格
  final num price;

  /// 説明
  final String? description;

  /// 画像URL
  final String? imageUrl;

  /// カテゴリ
  final String? category;

  /// 利用可能
  final bool isAvailable;

  /// 人気商品
  final bool isPopular;

  /// 新商品
  final bool isNew;

  /// おすすめ
  final bool isRecommended;

  /// 調理時間（分）
  final int? preparationTime;

  /// アレルゲン
  final List<String>? allergens;

  /// 栄養情報
  final Map<String, String>? nutrition;

  /// タグ
  final List<String>? tags;

  /// オプション
  final List<MenuItemOption>? options;
}

/// メニューアイテムオプション
class MenuItemOption {
  const MenuItemOption({
    required this.name,
    required this.price,
    this.isRequired = false,
    this.maxSelections = 1,
    this.choices,
  });

  /// オプション名
  final String name;

  /// 追加料金
  final num price;

  /// 必須選択
  final bool isRequired;

  /// 最大選択数
  final int maxSelections;

  /// 選択肢
  final List<String>? choices;
}
