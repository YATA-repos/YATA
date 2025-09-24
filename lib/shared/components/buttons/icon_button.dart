import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";

/// ボーダー付きのラウンドアイコンボタン。
class YataIconButton extends StatelessWidget {
  /// [YataIconButton]を生成する。
  const YataIconButton({
    required this.icon,
    super.key,
    this.onPressed,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.tooltip,
  });

  /// 表示するアイコン。
  final IconData icon;

  /// 押下時のコールバック。
  final VoidCallback? onPressed;

  /// ボタンサイズ。
  final double size;

  /// 背景色。
  final Color? backgroundColor;

  /// アイコン色。
  final Color? iconColor;

  /// 枠線カラー。
  final Color? borderColor;

  /// ツールチップ。
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackground = backgroundColor ?? YataColorTokens.neutral0;
    final Color resolvedIconColor = iconColor ?? YataColorTokens.textSecondary;
    final Color resolvedBorderColor = borderColor ?? YataColorTokens.border;

    final Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: resolvedBackground,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: resolvedBorderColor),
          ),
          child: Center(
            child: Icon(icon, size: size / 2, color: resolvedIconColor),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// アイコンとラベルを並べたトグルボタン。
class YataIconLabelButton extends StatelessWidget {
  /// [YataIconLabelButton]を生成する。
  const YataIconLabelButton({
    required this.icon,
    required this.label,
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.labelColor,
    this.iconColor,
  });

  /// 表示するアイコン。
  final IconData icon;

  /// 表示ラベル。
  final String label;

  /// 押下時のコールバック。
  final VoidCallback? onPressed;

  /// 背景色。
  final Color? backgroundColor;

  /// ラベル色。
  final Color? labelColor;

  /// アイコン色。
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackground = backgroundColor ?? YataColorTokens.primary;
    final Color resolvedLabelColor = labelColor ?? YataColorTokens.neutral0;
    final Color resolvedIconColor = iconColor ?? resolvedLabelColor;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: resolvedIconColor),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: resolvedLabelColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: resolvedBackground,
        foregroundColor: resolvedLabelColor,
        padding: const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.xl,
          vertical: YataSpacingTokens.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        ),
      ),
    );
  }
}
