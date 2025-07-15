import "package:flutter/material.dart";

import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

/// リストアイテムコンポーネント
///
/// 統一されたリスト項目構造、左右アイコン配置対応
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.dense = false,
    this.visualDensity,
    this.contentPadding,
    this.focusColor,
    this.hoverColor,
    this.selectedColor,
    this.splashColor,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback = true,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.titleAlignment,
    this.borderRadius,
  });

  /// 先頭要素
  final Widget? leading;

  /// タイトル
  final Widget? title;

  /// サブタイトル
  final Widget? subtitle;

  /// 末尾要素
  final Widget? trailing;

  /// タップ処理
  final VoidCallback? onTap;

  /// 長押し処理
  final VoidCallback? onLongPress;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  /// 密度
  final bool dense;

  /// 視覚密度
  final VisualDensity? visualDensity;

  /// コンテンツパディング
  final EdgeInsetsGeometry? contentPadding;

  /// フォーカス色
  final Color? focusColor;

  /// ホバー色
  final Color? hoverColor;

  /// 選択色
  final Color? selectedColor;

  /// スプラッシュ色
  final Color? splashColor;

  /// タイル色
  final Color? tileColor;

  /// 選択タイル色
  final Color? selectedTileColor;

  /// フィードバック有効
  final bool enableFeedback;

  /// 水平タイトル間隔
  final double? horizontalTitleGap;

  /// 最小垂直パディング
  final double? minVerticalPadding;

  /// 最小先頭幅
  final double? minLeadingWidth;

  /// タイトル配置
  final ListTileTitleAlignment? titleAlignment;

  /// 角丸
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget listTile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      selected: selected,
      enabled: enabled,
      dense: dense,
      visualDensity: visualDensity,
      contentPadding: contentPadding ?? AppLayout.padding4,
      focusColor: focusColor,
      hoverColor: hoverColor ?? AppColors.muted.withValues(alpha: 0.5),
      selectedColor: selectedColor,
      splashColor: splashColor,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor ?? AppColors.primary.withValues(alpha: 0.1),
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap ?? AppLayout.spacing3,
      minVerticalPadding: minVerticalPadding ?? AppLayout.spacing2,
      minLeadingWidth: minLeadingWidth ?? 40,
      titleAlignment: titleAlignment,
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: listTile);
    }

    return listTile;
  }
}

/// シンプルなテキストリストタイル
class AppTextListTile extends StatelessWidget {
  const AppTextListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.dense = false,
  });

  /// タイトルテキスト
  final String title;

  /// サブタイトルテキスト
  final String? subtitle;

  /// 先頭アイコン
  final IconData? leading;

  /// 末尾アイコン
  final IconData? trailing;

  /// タップ処理
  final VoidCallback? onTap;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  /// 密度
  final bool dense;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: leading != null
        ? Icon(leading, color: enabled ? AppColors.foreground : AppColors.mutedForeground)
        : null,
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: enabled ? AppColors.foreground : AppColors.mutedForeground,
        fontWeight: selected ? FontWeight.w500 : null,
      ),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: enabled
                  ? AppColors.mutedForeground
                  : AppColors.mutedForeground.withValues(alpha: 0.5),
            ),
          )
        : null,
    trailing: trailing != null
        ? Icon(
            trailing,
            size: AppLayout.iconSizeSm,
            color: enabled
                ? AppColors.mutedForeground
                : AppColors.mutedForeground.withValues(alpha: 0.5),
          )
        : null,
    onTap: onTap,
    selected: selected,
    enabled: enabled,
    dense: dense,
  );
}

/// アバター付きリストタイル
class AppAvatarListTile extends StatelessWidget {
  const AppAvatarListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.avatarText,
    this.avatarImage,
    this.avatarBackgroundColor,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  /// タイトルテキスト
  final String title;

  /// サブタイトルテキスト
  final String? subtitle;

  /// アバターテキスト
  final String? avatarText;

  /// アバター画像
  final ImageProvider? avatarImage;

  /// アバター背景色
  final Color? avatarBackgroundColor;

  /// 末尾要素
  final Widget? trailing;

  /// タップ処理
  final VoidCallback? onTap;

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: CircleAvatar(
      backgroundColor: avatarBackgroundColor ?? AppColors.primary,
      backgroundImage: avatarImage,
      child: avatarImage == null && avatarText != null
          ? Text(
              avatarText!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            )
          : null,
    ),
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: enabled ? AppColors.foreground : AppColors.mutedForeground,
        fontWeight: selected ? FontWeight.w500 : null,
      ),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: enabled
                  ? AppColors.mutedForeground
                  : AppColors.mutedForeground.withValues(alpha: 0.5),
            ),
          )
        : null,
    trailing: trailing,
    onTap: onTap,
    selected: selected,
    enabled: enabled,
  );
}
