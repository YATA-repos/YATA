import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/elevetion_token.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// セクション単位のコンテンツを表示するカードコンポーネント。
///
/// 見出し、サブタイトル、アクション群を渡せるため、ダッシュボード画面の
/// セクション表現を手早く構築できる。
class YataSectionCard extends StatelessWidget {
  /// [YataSectionCard]を生成する。
  const YataSectionCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.padding = YataSpacingTokens.cardPadding,
    this.backgroundColor = YataColorTokens.surface,
    this.expandChild = false,
  });

  /// セクションタイトル。
  final String? title;

  /// タイトルの補足説明。
  final String? subtitle;

  /// タイトル右側に並べるアクションウィジェット群。
  final List<Widget>? actions;

  /// 内側のパディング。
  final EdgeInsetsGeometry padding;

  /// カードの背景色。
  final Color backgroundColor;

  /// 本文コンテンツ。
  final Widget child;

  /// 子コンテンツを縦方向に展開してレイアウトする（内部でExpandedを使用）。
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadow = YataElevationTokens.level0;
    final BorderRadius borderRadius = YataRadiusTokens.borderRadiusCard;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: YataColorTokens.border),
        boxShadow: shadow,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            if (title != null || subtitle != null || (actions?.isNotEmpty ?? false))
              _Header(title: title, subtitle: subtitle, actions: actions),
            if (title != null || subtitle != null || (actions?.isNotEmpty ?? false))
              const SizedBox(height: YataSpacingTokens.md),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle, this.actions});

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (title != null)
                Text(title!, style: textTheme.titleLarge ?? YataTypographyTokens.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                  child: Text(
                    subtitle!,
                    style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty)
          Wrap(spacing: YataSpacingTokens.sm, runSpacing: YataSpacingTokens.xs, children: actions!),
      ],
    );
  }
}
