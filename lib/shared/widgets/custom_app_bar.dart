import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../core/constants/constants.dart";
import "../themes/themes.dart";

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => AppBar(
    title: Apptitle(title: title),
    actions: <Widget>[
      NavigationTabBar(
        items: <NavigationTabItem>[
          NavigationTabItem(icon: LucideIcons.home, label: AppStrings.buttonHome),
          NavigationTabItem(icon: LucideIcons.list, label: AppStrings.buttonOrderHistory),
          NavigationTabItem(icon: LucideIcons.barChart, label: AppStrings.buttonAnalytics),
        ],
      ),
      ActionButtonRow(
        children: <Widget>[
          ActionButton(
            icon: LucideIcons.settings,
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
    ],
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class Apptitle extends StatelessWidget {
  const Apptitle({required this.title, this.icon = LucideIcons.coffee, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 24),
      const SizedBox(width: 8),
      Text(title, style: AppTextStyles.textXl, overflow: TextOverflow.ellipsis, maxLines: 1),
    ],
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(icon: Icon(icon, size: 24), onPressed: onPressed);
}

class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.end, children: children);
}

class NavigationTabItem extends StatelessWidget {
  const NavigationTabItem({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      // アイコンとテキスト
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.textSm),
        ],
      ),
      // 下線
      Container(height: 2, width: 24, color: Theme.of(context).colorScheme.primary),
    ],
  );
}

class NavigationTabBar extends StatelessWidget {
  const NavigationTabBar({required this.items, super.key});

  final List<NavigationTabItem> items;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: items.map((NavigationTabItem item) => Expanded(child: item)).toList(),
  );
}
