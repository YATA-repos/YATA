import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// AppCard - 統一されたカードコンポーネント
///
/// 既存のAppColorsを活用し、一貫性のあるカードUIを提供します。
/// 他のカード系コンポーネント（StatsCard、MenuItemCard等）の基盤となります。
class AppCard extends StatelessWidget {
  const AppCard({
    this.child,
    this.header,
    this.footer,
    this.title,
    this.subtitle,
    this.variant = CardVariant.default_,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    super.key,
  });

  final Widget? child;
  final Widget? header;
  final Widget? footer;
  final String? title;
  final String? subtitle;
  final CardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = _buildCardContent();

    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.zero,
      child: Card(
        color: _getBackgroundColor(),
        surfaceTintColor: Colors.transparent,
        elevation: _getElevation(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _getBorderSide(),
        ),
        child: onTap != null
            ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: cardContent)
            : cardContent,
      ),
    );
  }

  Widget _buildCardContent() {
    final EdgeInsets effectivePadding = padding ?? const EdgeInsets.all(16);

    return Padding(
      padding: effectivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ヘッダー部分
          if (header != null) ...<Widget>[header!, const SizedBox(height: 12)] else if (title !=
              null) ...<Widget>[_buildTitleSection(), const SizedBox(height: 12)],

          // メインコンテンツ
          if (child != null) ...<Widget>[Flexible(child: child!)],

          // フッター部分
          if (footer != null) ...<Widget>[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }

  Widget _buildTitleSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title!, style: AppTextTheme.cardTitle),
      if (subtitle != null) ...<Widget>[
        const SizedBox(height: 4),
        Text(subtitle!, style: AppTextTheme.cardDescription),
      ],
    ],
  );

  Color _getBackgroundColor() => switch (variant) {
    CardVariant.default_ => AppColors.card,
    CardVariant.elevated => AppColors.card,
    CardVariant.outlined => AppColors.card,
    CardVariant.muted => AppColors.muted,
    CardVariant.primary => AppColors.primaryHover,
    CardVariant.success => AppColors.successMuted,
    CardVariant.warning => AppColors.warningMuted,
    CardVariant.danger => AppColors.dangerMuted,
  };

  double _getElevation() => switch (variant) {
    CardVariant.default_ => 1,
    CardVariant.elevated => 4,
    CardVariant.outlined => 0,
    CardVariant.muted => 0,
    CardVariant.primary => 2,
    CardVariant.success => 1,
    CardVariant.warning => 1,
    CardVariant.danger => 1,
  };

  BorderSide _getBorderSide() => switch (variant) {
    CardVariant.default_ => BorderSide(color: AppColors.border),
    CardVariant.elevated => BorderSide.none,
    CardVariant.outlined => BorderSide(color: AppColors.border, width: 1.5),
    CardVariant.muted => BorderSide(color: AppColors.border),
    CardVariant.primary => BorderSide(color: AppColors.primary),
    CardVariant.success => BorderSide(color: AppColors.success),
    CardVariant.warning => BorderSide(color: AppColors.warning),
    CardVariant.danger => BorderSide(color: AppColors.danger),
  };
}

/// コンパクトカード - より小さなパディングのカード
class CompactCard extends AppCard {
  const CompactCard({
    super.child,
    super.header,
    super.footer,
    super.title,
    super.subtitle,
    super.variant,
    super.onTap,
    super.margin,
    super.width,
    super.height,
    super.key,
  }) : super(padding: const EdgeInsets.all(12));
}

/// アクションカード - ボタンアクション付きのカード
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.variant = CardVariant.default_,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final CardVariant variant;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: variant,
    onTap: onTap,
    child: Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[icon!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTextTheme.cardTitle),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTextTheme.cardDescription),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

/// インフォカード - 情報表示専用のカード
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.variant = CardVariant.default_,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? icon;
  final CardVariant variant;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: variant,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Row(
            children: <Widget>[
              icon!,
              const SizedBox(width: 8),
              Text(title, style: AppTextTheme.cardTitle.copyWith(fontSize: 14)),
            ],
          ),
        ] else ...<Widget>[Text(title, style: AppTextTheme.cardTitle.copyWith(fontSize: 14))],
        const SizedBox(height: 8),
        Text(value, style: AppTextTheme.priceLarge.copyWith(fontSize: 20)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTextTheme.cardDescription),
        ],
      ],
    ),
  );
}
