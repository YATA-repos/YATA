import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

/// バッジコンポーネント
///
/// 状態表示、カウント表示、アイコン付きバッジに対応
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.child,
    super.key,
    this.variant = BadgeVariant.info,
    this.size = BadgeSize.medium,
    this.icon,
    this.onTap,
    this.padding,
  });

  AppBadge.text(
    String text, {
    Key? key,
    BadgeVariant variant = BadgeVariant.info,
    BadgeSize size = BadgeSize.medium,
    IconData? icon,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) : this(
         key: key,
         variant: variant,
         size: size,
         icon: icon,
         onTap: onTap,
         padding: padding,
         child: Text(text),
       );

  AppBadge.count(int count, {Key? key, BadgeSize size = BadgeSize.medium, VoidCallback? onTap})
    : this(
        key: key,
        variant: BadgeVariant.count,
        size: size,
        onTap: onTap,
        child: Text(count.toString()),
      );

  /// バッジコンテンツ
  final Widget child;

  /// バッジバリアント
  final BadgeVariant variant;

  /// バッジサイズ
  final BadgeSize size;

  /// アイコン
  final IconData? icon;

  /// タップ処理
  final VoidCallback? onTap;

  /// カスタムパディング
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final _BadgeStyle badgeStyle = _getBadgeStyle();
    final _BadgeSize badgeSize = _getBadgeSize();

    Widget badgeContent = _buildContent(badgeStyle, badgeSize);

    if (onTap != null) {
      badgeContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(badgeSize.borderRadius),
        child: badgeContent,
      );
    }

    return badgeContent;
  }

  Widget _buildContent(_BadgeStyle badgeStyle, _BadgeSize badgeSize) {
    final List<Widget> children = <Widget>[];

    if (icon != null) {
      children.add(Icon(icon, size: badgeSize.iconSize, color: badgeStyle.foregroundColor));

      if (child is Text && ((child as Text).data?.isNotEmpty ?? false)) {
        children.add(SizedBox(width: badgeSize.spacing));
      }
    }

    if (child is Text) {
      children.add(
        DefaultTextStyle(
          style: TextStyle(
            color: badgeStyle.foregroundColor,
            fontSize: badgeSize.fontSize,
            fontWeight: badgeSize.fontWeight,
            height: 1.0,
          ),
          child: child,
        ),
      );
    } else {
      children.add(child);
    }

    return Container(
      padding: padding ?? badgeSize.padding,
      decoration: BoxDecoration(
        color: badgeStyle.backgroundColor,
        border: badgeStyle.borderColor != null ? Border.all(color: badgeStyle.borderColor!) : null,
        borderRadius: BorderRadius.circular(badgeSize.borderRadius),
      ),
      child: children.length == 1
          ? children.first
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  _BadgeStyle _getBadgeStyle() {
    switch (variant) {
      case BadgeVariant.success:
        return _BadgeStyle(
          backgroundColor: AppColors.successMuted,
          foregroundColor: AppColors.success,
          borderColor: AppColors.success.withValues(alpha: 0.3),
        );
      case BadgeVariant.warning:
        return _BadgeStyle(
          backgroundColor: AppColors.warningMuted,
          foregroundColor: AppColors.warning,
          borderColor: AppColors.warning.withValues(alpha: 0.3),
        );
      case BadgeVariant.danger:
        return _BadgeStyle(
          backgroundColor: AppColors.dangerMuted,
          foregroundColor: AppColors.danger,
          borderColor: AppColors.danger.withValues(alpha: 0.3),
        );
      case BadgeVariant.info:
        return _BadgeStyle(
          backgroundColor: AppColors.muted,
          foregroundColor: AppColors.primary,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
        );
      case BadgeVariant.count:
        return _BadgeStyle(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
        );
    }
  }

  _BadgeSize _getBadgeSize() {
    switch (size) {
      case BadgeSize.small:
        return _BadgeSize(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spacing2,
            vertical: AppLayout.spacing1,
          ),
          fontSize: 10,
          iconSize: AppLayout.iconSizeSm,
          borderRadius: AppLayout.spacing3,
          fontWeight: FontWeight.w500,
          spacing: AppLayout.spacing1,
        );
      case BadgeSize.medium:
        return _BadgeSize(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spacing3,
            vertical: AppLayout.spacing1,
          ),
          fontSize: 12,
          iconSize: AppLayout.iconSizeSm,
          borderRadius: AppLayout.spacing4,
          fontWeight: FontWeight.w500,
          spacing: AppLayout.spacing1,
        );
      case BadgeSize.large:
        return _BadgeSize(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spacing4,
            vertical: AppLayout.spacing2,
          ),
          fontSize: 14,
          iconSize: AppLayout.iconSize,
          borderRadius: AppLayout.spacing5,
          fontWeight: FontWeight.w600,
          spacing: AppLayout.spacing2,
        );
    }
  }
}

/// バッジサイズ列挙型
enum BadgeSize { small, medium, large }

/// バッジスタイル定義
class _BadgeStyle {
  const _BadgeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
}

/// バッジサイズ定義
class _BadgeSize {
  const _BadgeSize({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.borderRadius,
    required this.fontWeight,
    required this.spacing,
  });

  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final FontWeight fontWeight;
  final double spacing;
}

/// ステータスバッジ専用ヘルパー
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key, this.size = BadgeSize.medium, this.onTap});

  /// ステータス値
  final String status;

  /// バッジサイズ
  final BadgeSize size;

  /// タップ処理
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BadgeVariant variant = _getVariantFromStatus(status);
    final String displayText = _getDisplayText(status);
    final IconData? icon = _getIconFromStatus(status);

    return AppBadge.text(displayText, variant: variant, size: size, icon: icon, onTap: onTap);
  }

  BadgeVariant _getVariantFromStatus(String status) {
    switch (status.toLowerCase()) {
      case "完了":
      case "complete":
      case "success":
      case "確定":
      case "在庫あり":
        return BadgeVariant.success;

      case "警告":
      case "warning":
      case "注意":
      case "在庫少":
      case "調理中":
      case "cooking":
        return BadgeVariant.warning;

      case "エラー":
      case "error":
      case "danger":
      case "削除":
      case "キャンセル":
      case "在庫切れ":
        return BadgeVariant.danger;

      default:
        return BadgeVariant.info;
    }
  }

  String _getDisplayText(String status) {
    switch (status.toLowerCase()) {
      case "complete":
        return "完了";
      case "cooking":
        return "調理中";
      case "cancelled":
        return "キャンセル";
      default:
        return status;
    }
  }

  IconData? _getIconFromStatus(String status) {
    switch (status.toLowerCase()) {
      case "完了":
      case "complete":
      case "success":
        return Icons.check_circle_outline;

      case "警告":
      case "warning":
      case "注意":
        return Icons.warning_amber_outlined;

      case "エラー":
      case "error":
      case "danger":
        return Icons.error_outline;

      case "調理中":
      case "cooking":
        return Icons.restaurant_outlined;

      default:
        return null;
    }
  }
}

/// 数値バッジ専用ヘルパー
class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    super.key,
    this.maxCount = 99,
    this.size = BadgeSize.medium,
    this.showZero = false,
    this.onTap,
  });

  /// カウント数
  final int count;

  /// 最大表示数
  final int maxCount;

  /// バッジサイズ
  final BadgeSize size;

  /// ゼロ表示フラグ
  final bool showZero;

  /// タップ処理
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) {
      return const SizedBox.shrink();
    }

    final String displayText = count > maxCount ? "$maxCount+" : count.toString();

    return AppBadge.text(displayText, variant: BadgeVariant.count, size: size, onTap: onTap);
  }
}
