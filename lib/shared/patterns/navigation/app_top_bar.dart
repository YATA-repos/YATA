import "package:flutter/material.dart";

import "../../components/data_display/status_badge.dart";
import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// トップバーに表示するナビゲーション項目定義。
class YataNavItem {
  /// [YataNavItem]を生成する。
  const YataNavItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isActive = false,
    this.badge,
  });

  /// 表示ラベル。
  final String label;

  /// アイコン。
  final IconData? icon;

  /// タップ時のコールバック。
  final VoidCallback? onTap;

  /// アクティブ状態かどうか。
  final bool isActive;

  /// 補助バッジ。
  final String? badge;
}

/// アプリ共通のトップナビゲーションバー。
class YataAppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// [YataAppTopBar]を生成する。
  const YataAppTopBar({
    required this.navItems,
    super.key,
    this.logo,
    this.title = "YATA",
    this.trailing,
  });

  /// 左側に表示するロゴ。
  final Widget? logo;

  /// ブランドタイトル。
  final String title;

  /// 中央ナビゲーション項目。
  final List<YataNavItem> navItems;

  /// 右側に表示するアクション群。
  final List<Widget>? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Container(
    height: preferredSize.height,
    padding: const EdgeInsets.only(
      left: YataSpacingTokens.xl,
      right: YataSpacingTokens.xl,
      top: YataSpacingTokens.xs,
      bottom: 0,
    ),
    decoration: BoxDecoration(
      color: YataColorTokens.surface,
      border: Border(bottom: BorderSide(color: YataColorTokens.border)),
    ),
    child: Row(
      children: <Widget>[
        if (logo != null) logo!,
        if (logo != null) const SizedBox(width: YataSpacingTokens.md) else const SizedBox(width: 0),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge ?? YataTypographyTokens.titleLarge,
        ),
        const SizedBox(width: YataSpacingTokens.xl),
        Expanded(child: _NavItems(items: navItems)),
        if (trailing != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int index = 0; index < trailing!.length; index++) ...<Widget>[
                trailing![index],
                if (index != trailing!.length - 1) const SizedBox(width: YataSpacingTokens.sm),
              ],
            ],
          ),
      ],
    ),
  );
}

class _NavItems extends StatelessWidget {
  const _NavItems({required this.items});

  final List<YataNavItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        final YataNavItem item = items[index];
        return _NavItem(item: item);
      },
      separatorBuilder: (BuildContext context, int _) =>
          const SizedBox(width: YataSpacingTokens.lg),
      itemCount: items.length,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item});

  final YataNavItem item;

  @override
  Widget build(BuildContext context) {
    final bool isActive = item.isActive;
    final Color foreground = isActive ? YataColorTokens.primary : YataColorTokens.textSecondary;
    final TextStyle labelStyle =
        (Theme.of(context).textTheme.titleSmall ?? YataTypographyTokens.titleSmall).copyWith(
          color: foreground,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.only(
            left: YataSpacingTokens.md,
            right: YataSpacingTokens.md,
            top: YataSpacingTokens.sm,
            bottom: YataSpacingTokens.xxs,
          ),
          decoration: BoxDecoration(
            color: isActive ? YataColorTokens.primarySoft : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (item.icon != null) ...<Widget>[
                    Icon(item.icon, size: 18, color: foreground),
                    const SizedBox(width: YataSpacingTokens.xs),
                  ],
                  Text(item.label, style: labelStyle),
                  if (item.badge != null) ...<Widget>[
                    const SizedBox(width: YataSpacingTokens.xs),
                    YataStatusBadge(label: item.badge!, type: YataStatusBadgeType.info),
                  ],
                ],
              ),
              if (isActive) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.xs),
                Container(
                  height: 2,
                  width: 36,
                  decoration: BoxDecoration(
                    color: YataColorTokens.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
