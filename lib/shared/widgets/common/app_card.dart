import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.variant = CardVariant.basic,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.width,
    this.height,
  });

  final Widget child;
  final CardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final _CardStyle cardStyle = _getCardStyle();

    Widget cardChild = Container(
      width: width,
      height: height,
      padding: padding ?? AppLayout.padding4,
      child: child,
    );

    if (onTap != null) {
      cardChild = InkWell(onTap: onTap, borderRadius: AppLayout.radiusLg, child: cardChild);
    }

    Widget result;

    switch (variant) {
      case CardVariant.basic:
      case CardVariant.highlighted:
        result = Card(
          elevation: elevation ?? cardStyle.elevation,
          color: cardStyle.backgroundColor,
          shadowColor: cardStyle.shadowColor,
          shape: RoundedRectangleBorder(borderRadius: AppLayout.radiusLg),
          margin: margin ?? EdgeInsets.zero,
          child: cardChild,
        );
      case CardVariant.outlined:
        result = Container(
          width: width,
          height: height,
          margin: margin ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            color: cardStyle.backgroundColor,
            border: Border.all(color: cardStyle.borderColor),
            borderRadius: AppLayout.radiusLg,
          ),
          child: Container(padding: padding ?? AppLayout.padding4, child: child),
        );
    }

    return result;
  }

  _CardStyle _getCardStyle() {
    switch (variant) {
      case CardVariant.basic:
        return _CardStyle(
          backgroundColor: AppColors.card,
          borderColor: AppColors.border,
          shadowColor: Colors.black12,
          elevation: AppLayout.elevationSm,
        );
      case CardVariant.highlighted:
        return _CardStyle(
          backgroundColor: AppColors.muted,
          borderColor: AppColors.border,
          shadowColor: Colors.black12,
          elevation: AppLayout.elevation,
        );
      case CardVariant.outlined:
        return _CardStyle(
          backgroundColor: AppColors.background,
          borderColor: AppColors.border,
          shadowColor: Colors.transparent,
          elevation: 0,
        );
    }
  }
}

class _CardStyle {
  const _CardStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.elevation,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double elevation;
}

class AppCardHeader extends StatelessWidget {
  const AppCardHeader({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.padding,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? AppLayout.paddingVertical4,
    child: Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, const SizedBox(width: AppLayout.spacing3)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null) title!,
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppLayout.spacing1),
                DefaultTextStyle(
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.mutedForeground),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: AppLayout.spacing3), trailing!],
      ],
    ),
  );
}

class AppCardContent extends StatelessWidget {
  const AppCardContent({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) =>
      Container(padding: padding ?? AppLayout.paddingVertical2, child: child);
}

class AppCardActions extends StatelessWidget {
  const AppCardActions({
    required this.children,
    super.key,
    this.alignment = MainAxisAlignment.end,
    this.padding,
  });

  final List<Widget> children;
  final MainAxisAlignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? AppLayout.paddingVertical2,
    child: Row(
      mainAxisAlignment: alignment,
      children: children
          .map(
            (Widget child) => Padding(
              padding: const EdgeInsets.only(left: AppLayout.spacing2),
              child: child,
            ),
          )
          .toList(),
    ),
  );
}
