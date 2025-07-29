import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/constants/enums.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// AppBadge - 統一されたバッジコンポーネント
///
/// 既存のAppColors業務固有色・AppTextTheme.badgeTextを活用し、
/// 調理状況・在庫状態・注文ステータス等の業務情報表示に特化したバッジです。
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.text,
    this.variant = BadgeVariant.default_,
    this.size = BadgeSize.medium,
    this.icon,
    this.showIcon = false,
    super.key,
  });

  final String text;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final (Color backgroundColor, Color textColor) = _getColors();
    final IconData? effectiveIcon = showIcon ? (icon ?? _getDefaultIcon()) : icon;

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (effectiveIcon != null) ...<Widget>[
            Icon(effectiveIcon, color: textColor, size: _getIconSize()),
            SizedBox(width: _getIconSpacing()),
          ],
          Text(
            text,
            style: AppTextTheme.badgeText.copyWith(
              color: textColor,
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors() => switch (variant) {
    BadgeVariant.default_ => (AppColors.muted, AppColors.foreground),
    BadgeVariant.primary => (AppColors.primary, AppColors.primaryForeground),
    BadgeVariant.secondary => (AppColors.secondary, AppColors.secondaryForeground),
    BadgeVariant.success => (AppColors.success, AppColors.successForeground),
    BadgeVariant.warning => (AppColors.warning, AppColors.warningForeground),
    BadgeVariant.danger => (AppColors.danger, AppColors.dangerForeground),
    // 業務固有ステータス色活用
    BadgeVariant.cooking => (AppColors.cooking, AppColors.cookingForeground),
    BadgeVariant.complete => (AppColors.complete, AppColors.completeForeground),
    BadgeVariant.inStock => (AppColors.inStock, AppColors.trueWhite),
    BadgeVariant.lowStock => (AppColors.lowStock, AppColors.trueBlack),
    BadgeVariant.outOfStock => (AppColors.outOfStock, AppColors.trueWhite),
  };

  IconData? _getDefaultIcon() => switch (variant) {
    BadgeVariant.success => LucideIcons.check,
    BadgeVariant.warning => LucideIcons.alertTriangle,
    BadgeVariant.danger => LucideIcons.x,
    BadgeVariant.cooking => LucideIcons.clock,
    BadgeVariant.complete => LucideIcons.checkCircle,
    BadgeVariant.inStock => LucideIcons.package,
    BadgeVariant.lowStock => LucideIcons.alertTriangle,
    BadgeVariant.outOfStock => LucideIcons.packageX,
    _ => null,
  };

  EdgeInsets _getPadding() => switch (size) {
    BadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    BadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    BadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  };

  double _getBorderRadius() => switch (size) {
    BadgeSize.small => 3.0,
    BadgeSize.medium => 4.0,
    BadgeSize.large => 6.0,
  };

  double _getIconSize() => switch (size) {
    BadgeSize.small => 10.0,
    BadgeSize.medium => 12.0,
    BadgeSize.large => 14.0,
  };

  double _getIconSpacing() => switch (size) {
    BadgeSize.small => 3.0,
    BadgeSize.medium => 4.0,
    BadgeSize.large => 5.0,
  };

  double _getFontSize() => switch (size) {
    BadgeSize.small => 10.0,
    BadgeSize.medium => 12.0,
    BadgeSize.large => 14.0,
  };
}

/// 注文ステータスバッジ
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, this.size = BadgeSize.medium, super.key});

  final OrderStatus status;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (String text, BadgeVariant variant) = _getStatusInfo();

    return AppBadge(text: text, variant: variant, size: size, showIcon: true);
  }

  (String, BadgeVariant) _getStatusInfo() => switch (status) {
    OrderStatus.pending => ("待機中", BadgeVariant.default_),
    OrderStatus.confirmed => ("確認済み", BadgeVariant.primary),
    OrderStatus.preparing => ("準備中", BadgeVariant.cooking),
    OrderStatus.ready => ("準備完了", BadgeVariant.complete),
    OrderStatus.delivered => ("配達済", BadgeVariant.success),
    OrderStatus.completed => ("完了", BadgeVariant.success),
    OrderStatus.cancelled => ("キャンセル", BadgeVariant.danger),
    OrderStatus.refunded => ("返金済み", BadgeVariant.default_),
  };
}

/// 在庫ステータスバッジ
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    required this.stockCount,
    required this.lowStockThreshold,
    this.size = BadgeSize.medium,
    super.key,
  });

  final int stockCount;
  final int lowStockThreshold;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (String text, BadgeVariant variant) = _getStockInfo();

    return AppBadge(text: text, variant: variant, size: size, showIcon: true);
  }

  (String, BadgeVariant) _getStockInfo() {
    if (stockCount <= 0) {
      return ("在庫切れ", BadgeVariant.outOfStock);
    } else if (stockCount <= lowStockThreshold) {
      return ("在庫少", BadgeVariant.lowStock);
    } else {
      return ("在庫あり", BadgeVariant.inStock);
    }
  }
}

/// 数量バッジ（通知用）
class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    this.maxCount = 99,
    this.size = BadgeSize.small,
    this.variant = BadgeVariant.danger,
    super.key,
  });

  final int count;
  final int maxCount;
  final BadgeSize size;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final String displayText = count > maxCount ? "$maxCount+" : count.toString();

    return AppBadge(text: displayText, variant: variant, size: size);
  }
}

/// 優先度バッジ
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, this.size = BadgeSize.medium, super.key});

  final Priority priority;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (String text, BadgeVariant variant) = _getPriorityInfo();

    return AppBadge(text: text, variant: variant, size: size);
  }

  (String, BadgeVariant) _getPriorityInfo() => switch (priority) {
    Priority.low => ("低", BadgeVariant.default_),
    Priority.medium => ("中", BadgeVariant.warning),
    Priority.high => ("高", BadgeVariant.danger),
    Priority.urgent => ("緊急", BadgeVariant.danger),
  };
}

/// カスタムバッジ（自由なテキスト・色）
class CustomBadge extends StatelessWidget {
  const CustomBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.size = BadgeSize.medium,
    this.icon,
    super.key,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final BadgeSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: _getPadding(),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(_getBorderRadius()),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, color: textColor, size: _getIconSize()),
          SizedBox(width: _getIconSpacing()),
        ],
        Text(
          text,
          style: AppTextTheme.badgeText.copyWith(
            color: textColor,
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  EdgeInsets _getPadding() => switch (size) {
    BadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    BadgeSize.medium => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    BadgeSize.large => const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  };

  double _getBorderRadius() => switch (size) {
    BadgeSize.small => 3.0,
    BadgeSize.medium => 4.0,
    BadgeSize.large => 6.0,
  };

  double _getIconSize() => switch (size) {
    BadgeSize.small => 10.0,
    BadgeSize.medium => 12.0,
    BadgeSize.large => 14.0,
  };

  double _getIconSpacing() => switch (size) {
    BadgeSize.small => 3.0,
    BadgeSize.medium => 4.0,
    BadgeSize.large => 5.0,
  };

  double _getFontSize() => switch (size) {
    BadgeSize.small => 10.0,
    BadgeSize.medium => 12.0,
    BadgeSize.large => 14.0,
  };
}
