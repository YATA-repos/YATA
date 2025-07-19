import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../core/core.dart";
import "../themes/themes.dart";

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) => AppBar(
      title: AppTitle(),
    );

  @override
  Size get preferredSize => const Size.fromHeight(AppLayout.appBarHeight);
}

class AppTitle extends StatelessWidget {
  const AppTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
      children: <Widget>[
        Icon(LucideIcons.coffee, size: AppLayout.iconSize),
        SizedBox(width: AppLayout.spacingXs),
        const Text(AppStrings.titleApp, style: AppTextStyles.textTitle, textAlign: TextAlign.center, maxLines: 1),
      ],
    );
}

