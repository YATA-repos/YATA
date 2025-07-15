import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

/// チップコンポーネント
///
/// 状態表示、タグ表示用のチップ
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.variant = ChipVariant.basic,
    this.size = ChipSize.medium,
    this.onPressed,
    this.onDeleted,
    this.avatar,
    this.deleteIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.deleteIconColor,
    this.selected = false,
    this.enabled = true,
    this.elevation,
    this.shadowColor,
    this.selectedColor,
    this.selectedShadowColor,
    this.tooltip,
    this.padding,
    this.labelPadding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.shape,
  });

  /// 基本チップ
  factory AppChip.basic(
    String label, {
    Key? key,
    ChipSize size = ChipSize.medium,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
    bool selected = false,
    bool enabled = true,
  }) => AppChip(
    label: label,
    size: size,
    onPressed: onPressed,
    onDeleted: onDeleted,
    selected: selected,
    enabled: enabled,
    key: key,
  );

  /// アウトラインチップ
  factory AppChip.outlined(
    String label, {
    Key? key,
    ChipSize size = ChipSize.medium,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
    bool selected = false,
    bool enabled = true,
  }) => AppChip(
    label: label,
    variant: ChipVariant.outlined,
    size: size,
    onPressed: onPressed,
    onDeleted: onDeleted,
    selected: selected,
    enabled: enabled,
    key: key,
  );

  /// ステータスチップ
  factory AppChip.status(
    String label, {
    required ChipVariant status,
    Key? key,
    ChipSize size = ChipSize.medium,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
    bool selected = false,
    bool enabled = true,
  }) => AppChip(
    label: label,
    variant: status,
    size: size,
    onPressed: onPressed,
    onDeleted: onDeleted,
    selected: selected,
    enabled: enabled,
    key: key,
  );

  /// アクションチップ
  factory AppChip.action(
    String label,
    VoidCallback onPressed, {
    Key? key,
    ChipSize size = ChipSize.medium,
    Widget? avatar,
    bool enabled = true,
  }) => AppChip(
    label: label,
    size: size,
    onPressed: onPressed,
    avatar: avatar,
    enabled: enabled,
    key: key,
  );

  /// フィルターチップ
  factory AppChip.filter(
    String label,
    bool selected,
    ValueChanged<bool> onSelected, {
    Key? key,
    ChipSize size = ChipSize.medium,
    Widget? avatar,
    bool enabled = true,
  }) => AppChip(
    label: label,
    size: size,
    onPressed: () => onSelected(!selected),
    avatar: avatar,
    selected: selected,
    enabled: enabled,
    key: key,
  );

  /// 入力チップ
  factory AppChip.input(
    String label,
    VoidCallback onDeleted, {
    Key? key,
    ChipSize size = ChipSize.medium,
    Widget? avatar,
    VoidCallback? onPressed,
    bool enabled = true,
  }) => AppChip(
    label: label,
    size: size,
    onPressed: onPressed,
    onDeleted: onDeleted,
    avatar: avatar,
    enabled: enabled,
    key: key,
  );

  /// ラベル
  final String label;

  /// バリアント
  final ChipVariant variant;

  /// サイズ
  final ChipSize size;

  /// 押下処理
  final VoidCallback? onPressed;

  /// 削除処理
  final VoidCallback? onDeleted;

  /// アバター
  final Widget? avatar;

  /// 削除アイコン
  final Widget? deleteIcon;

  /// 背景色
  final Color? backgroundColor;

  /// 前景色
  final Color? foregroundColor;

  /// 境界色
  final Color? borderColor;

  /// 削除アイコン色
  final Color? deleteIconColor;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  /// 影の高さ
  final double? elevation;

  /// 影の色
  final Color? shadowColor;

  /// 選択時色
  final Color? selectedColor;

  /// 選択時影色
  final Color? selectedShadowColor;

  /// ツールチップ
  final String? tooltip;

  /// パディング
  final EdgeInsetsGeometry? padding;

  /// ラベルパディング
  final EdgeInsetsGeometry? labelPadding;

  /// 視覚密度
  final VisualDensity? visualDensity;

  /// マテリアルタップターゲットサイズ
  final MaterialTapTargetSize? materialTapTargetSize;

  /// 形状
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    if (onPressed != null && onDeleted != null) {
      return _buildInputChip(context);
    } else if (onPressed != null) {
      return _buildActionChip(context);
    } else if (onDeleted != null) {
      return _buildInputChip(context);
    } else {
      return _buildChip(context);
    }
  }

  Widget _buildChip(BuildContext context) => Chip(
    label: _buildLabel(context),
    avatar: avatar,
    deleteIcon: deleteIcon,
    onDeleted: onDeleted,
    backgroundColor: backgroundColor ?? _getBackgroundColor(),
    deleteIconColor: deleteIconColor ?? _getDeleteIconColor(),
    elevation: elevation ?? 0,
    shadowColor: shadowColor,
    side: _getBorderSide(),
    padding: padding ?? _getPadding(),
    labelPadding: labelPadding ?? _getLabelPadding(),
    visualDensity: visualDensity ?? _getVisualDensity(),
    materialTapTargetSize: materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
    shape: shape ?? _getShape(),
    labelStyle: _getLabelStyle(context),
  );

  Widget _buildActionChip(BuildContext context) => ActionChip(
    label: _buildLabel(context),
    onPressed: enabled ? onPressed : null,
    avatar: avatar,
    backgroundColor: backgroundColor ?? _getBackgroundColor(),
    elevation: elevation ?? 0,
    shadowColor: shadowColor,
    side: _getBorderSide(),
    padding: padding ?? _getPadding(),
    labelPadding: labelPadding ?? _getLabelPadding(),
    visualDensity: visualDensity ?? _getVisualDensity(),
    materialTapTargetSize: materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
    shape: shape ?? _getShape(),
    labelStyle: _getLabelStyle(context),
  );

  Widget _buildInputChip(BuildContext context) => InputChip(
    label: _buildLabel(context),
    onPressed: enabled ? onPressed : null,
    onDeleted: enabled ? onDeleted : null,
    avatar: avatar,
    deleteIcon: deleteIcon ?? const Icon(LucideIcons.x, size: 16),
    selected: selected,
    backgroundColor: backgroundColor ?? _getBackgroundColor(),
    deleteIconColor: deleteIconColor ?? _getDeleteIconColor(),
    elevation: elevation ?? 0,
    shadowColor: shadowColor,
    side: _getBorderSide(),
    padding: padding ?? _getPadding(),
    labelPadding: labelPadding ?? _getLabelPadding(),
    visualDensity: visualDensity ?? _getVisualDensity(),
    materialTapTargetSize: materialTapTargetSize ?? MaterialTapTargetSize.shrinkWrap,
    shape: shape ?? _getShape(),
    labelStyle: _getLabelStyle(context),
  );

  Widget _buildLabel(BuildContext context) => Text(label, style: _getLabelStyle(context));

  Color _getBackgroundColor() {
    switch (variant) {
      case ChipVariant.basic:
        return AppColors.muted;
      case ChipVariant.outlined:
        return Colors.transparent;
      case ChipVariant.success:
        return AppColors.successMuted;
      case ChipVariant.warning:
        return AppColors.warningMuted;
      case ChipVariant.danger:
        return AppColors.dangerMuted;
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case ChipVariant.basic:
        return AppColors.foreground;
      case ChipVariant.outlined:
        return AppColors.foreground;
      case ChipVariant.success:
        return AppColors.success;
      case ChipVariant.warning:
        return AppColors.warning;
      case ChipVariant.danger:
        return AppColors.danger;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case ChipVariant.basic:
        return Colors.transparent;
      case ChipVariant.outlined:
        return AppColors.border;
      case ChipVariant.success:
        return AppColors.success.withValues(alpha: 0.3);
      case ChipVariant.warning:
        return AppColors.warning.withValues(alpha: 0.3);
      case ChipVariant.danger:
        return AppColors.danger.withValues(alpha: 0.3);
    }
  }

  Color _getDeleteIconColor() => _getForegroundColor();

  BorderSide _getBorderSide() => BorderSide(
    color: borderColor ?? _getBorderColor(),
    width: variant == ChipVariant.outlined ? 1 : 0,
  );

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ChipSize.small:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing2);
      case ChipSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing3);
      case ChipSize.large:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing4);
    }
  }

  EdgeInsetsGeometry _getLabelPadding() {
    switch (size) {
      case ChipSize.small:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing1);
      case ChipSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing2);
      case ChipSize.large:
        return const EdgeInsets.symmetric(horizontal: AppLayout.spacing3);
    }
  }

  VisualDensity _getVisualDensity() {
    switch (size) {
      case ChipSize.small:
        return VisualDensity.compact;
      case ChipSize.medium:
        return VisualDensity.standard;
      case ChipSize.large:
        return VisualDensity.comfortable;
    }
  }

  OutlinedBorder _getShape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.spacing6));

  TextStyle _getLabelStyle(BuildContext context) {
    final TextStyle? baseStyle = switch (size) {
      ChipSize.small => Theme.of(context).textTheme.bodySmall,
      ChipSize.medium => Theme.of(context).textTheme.bodyMedium,
      ChipSize.large => Theme.of(context).textTheme.bodyLarge,
    };

    return baseStyle?.copyWith(
          color: foregroundColor ?? _getForegroundColor(),
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: foregroundColor ?? _getForegroundColor(), fontWeight: FontWeight.w500);
  }
}
