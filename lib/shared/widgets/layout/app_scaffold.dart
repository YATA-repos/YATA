import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.showBackButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.appBarElevation = 0,
    this.padding,
    this.safe = true,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final double appBarElevation;
  final EdgeInsetsGeometry? padding;
  final bool safe;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    Widget scaffoldBody = body;

    if (padding != null) {
      scaffoldBody = Padding(padding: padding!, child: scaffoldBody);
    }

    if (safe) {
      scaffoldBody = SafeArea(child: scaffoldBody);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: _buildAppBar(context, canPop),
      body: scaffoldBody,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, bool canPop) {
    if (title == null && actions == null && leading == null && !showBackButton) {
      return null;
    }

    return AppBar(
      title: title != null
          ? Text(title!, style: Theme.of(context).appBarTheme.titleTextStyle)
          : null,
      centerTitle: centerTitle,
      elevation: appBarElevation,
      backgroundColor: backgroundColor ?? AppColors.background,
      foregroundColor: AppColors.foreground,
      leading: _buildLeading(context, canPop),
      actions: actions,
      automaticallyImplyLeading: false,
    );
  }

  Widget? _buildLeading(BuildContext context, bool canPop) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton && canPop) {
      return IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      );
    }

    return null;
  }
}

class AppScaffoldAction extends StatelessWidget {
  const AppScaffoldAction({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: tooltip);

    if (badge != null) {
      iconButton = Badge(label: badge, child: iconButton);
    }

    return iconButton;
  }
}

class AppScaffoldTitle extends StatelessWidget {
  const AppScaffoldTitle({required this.title, super.key, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (icon != null) ...<Widget>[icon!, const SizedBox(width: AppLayout.spacing2)],
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).appBarTheme.titleTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ],
  );
}

class ResponsiveAppScaffold extends StatelessWidget {
  const ResponsiveAppScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.drawer,
    this.rail,
    this.showBackButton = true,
    this.backgroundColor,
    this.padding,
    this.breakpoint = AppLayout.breakpointTablet,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? rail;
  final bool showBackButton;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= breakpoint;

    if (isWideScreen && rail != null) {
      return AppScaffold(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        backgroundColor: backgroundColor,
        padding: padding,
        body: Row(
          children: <Widget>[
            rail!,
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return AppScaffold(
      title: title,
      actions: actions,
      drawer: drawer,
      showBackButton: showBackButton,
      backgroundColor: backgroundColor,
      padding: padding,
      body: body,
    );
  }
}
