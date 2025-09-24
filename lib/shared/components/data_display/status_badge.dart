import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// ステータスを意味する色付きバッジ種別。
enum YataStatusBadgeType {
  /// 処理完了や在庫ありを表す。
  success,

  /// 注意喚起や残りわずかを表す。
  warning,

  /// エラーや致命的な状態を表す。
  danger,

  /// 情報通知やニュートラルな案内を表す。
  info,

  /// グレー系のニュートラル状態。
  neutral,
}

/// ステータス表示用のピル型バッジ。
class YataStatusBadge extends StatelessWidget {
  /// [YataStatusBadge]を生成する。
  const YataStatusBadge({
    required this.label,
    this.type = YataStatusBadgeType.neutral,
    this.icon,
    super.key,
  });

  /// 表示するラベル。
  final String label;

  /// バッジのタイプ。
  final YataStatusBadgeType type;

  /// ラベルの左側に表示するアイコン。
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _resolveStyle(type);
    final TextStyle baseStyle =
        Theme.of(context).textTheme.labelMedium ?? YataTypographyTokens.labelMedium;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YataSpacingTokens.sm,
        vertical: YataSpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: YataRadiusTokens.borderRadiusPill,
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: style.foreground),
            const SizedBox(width: YataSpacingTokens.xs),
          ],
          Text(label, style: baseStyle.copyWith(color: style.foreground)),
        ],
      ),
    );
  }

  _StatusStyle _resolveStyle(YataStatusBadgeType type) {
    switch (type) {
      case YataStatusBadgeType.success:
        return _StatusStyle(
          foreground: YataColorTokens.success,
          background: YataColorTokens.successSoft,
          borderColor: YataColorTokens.success,
        );
      case YataStatusBadgeType.warning:
        return _StatusStyle(
          foreground: YataColorTokens.warning,
          background: YataColorTokens.warningSoft,
          borderColor: YataColorTokens.warning,
        );
      case YataStatusBadgeType.danger:
        return _StatusStyle(
          foreground: YataColorTokens.danger,
          background: YataColorTokens.dangerSoft,
          borderColor: YataColorTokens.danger,
        );
      case YataStatusBadgeType.info:
        return _StatusStyle(
          foreground: YataColorTokens.info,
          background: YataColorTokens.infoSoft,
          borderColor: YataColorTokens.info,
        );
      case YataStatusBadgeType.neutral:
        return _StatusStyle(
          foreground: YataColorTokens.textSecondary,
          background: YataColorTokens.neutral100,
          borderColor: YataColorTokens.neutral200,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.foreground,
    required this.background,
    required this.borderColor,
  });

  final Color foreground;
  final Color background;
  final Color borderColor;
}
