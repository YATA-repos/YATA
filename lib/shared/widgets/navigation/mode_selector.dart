import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../core/utils/responsive_helper.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";
import "../common/app_badge.dart";

/// ModeSelector - モード切り替えセレクター
///
/// 既存のAppColors・AppTextThemeを活用し、
/// ダッシュボードのオーダー/在庫モード切り替え等に特化したセレクターです。
class ModeSelector extends StatelessWidget {
  const ModeSelector({
    required this.options,
    required this.selectedMode,
    this.onModeChanged,
    this.variant = ModeSelectorVariant.segmented,
    this.direction = Axis.horizontal,
    super.key,
  });

  final List<ModeOption> options;
  final String selectedMode;
  final ValueChanged<String>? onModeChanged;
  final ModeSelectorVariant variant;
  final Axis direction;

  @override
  Widget build(BuildContext context) => switch (variant) {
    ModeSelectorVariant.segmented => _buildSegmentedControl(context),
    ModeSelectorVariant.tabs => _buildTabControl(context),
    ModeSelectorVariant.buttons => _buildButtonControl(context),
    ModeSelectorVariant.cards => _buildCardControl(context),
  };

  Widget _buildSegmentedControl(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: options.map((ModeOption option) {
        final bool isSelected = option.id == selectedMode;

        return Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged?.call(option.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.card : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: _buildOptionContent(option, isSelected, true),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildTabControl(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: options.map((ModeOption option) {
        final bool isSelected = option.id == selectedMode;

        return Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged?.call(option.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: _buildOptionContent(option, isSelected, true),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildButtonControl(BuildContext context) {
    final Widget content = direction == Axis.horizontal
        ? Row(children: _buildButtonList())
        : Column(children: _buildButtonList());

    return content;
  }

  Widget _buildCardControl(BuildContext context) {
    final bool isHorizontal = direction == Axis.horizontal;
    final int crossAxisCount = ResponsiveHelper.isMobile(context) ? 1 : 2;

    if (isHorizontal && !ResponsiveHelper.isMobile(context)) {
      return Row(
        children: options
            .map(
              (ModeOption option) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildModeCard(option),
                ),
              ),
            )
            .toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: options.map(_buildModeCard).toList(),
      );
    }
  }

  List<Widget> _buildButtonList() => options.map((ModeOption option) {
    final bool isSelected = option.id == selectedMode;
    final bool isLast = option == options.last;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          right: direction == Axis.horizontal && !isLast ? 8 : 0,
          bottom: direction == Axis.vertical && !isLast ? 8 : 0,
        ),
        child: GestureDetector(
          onTap: () => onModeChanged?.call(option.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: _buildOptionContent(
              option,
              isSelected,
              true,
              textColor: isSelected ? AppColors.primaryForeground : null,
            ),
          ),
        ),
      ),
    );
  }).toList();

  Widget _buildModeCard(ModeOption option) {
    final bool isSelected = option.id == selectedMode;

    return GestureDetector(
      onTap: () => onModeChanged?.call(option.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryHover : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  option.icon,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                  size: 24,
                ),
                if (option.badgeCount != null && option.badgeCount! > 0) ...<Widget>[
                  const SizedBox(width: 8),
                  CountBadge(
                    count: option.badgeCount!,
                    variant: isSelected ? BadgeVariant.primary : BadgeVariant.warning,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              style: AppTextTheme.cardTitle.copyWith(
                fontSize: 14,
                color: isSelected ? AppColors.primary : AppColors.foreground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (option.description != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                option.description!,
                style: AppTextTheme.cardDescription.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionContent(ModeOption option, bool isSelected, bool center, {Color? textColor}) {
    final Color effectiveTextColor =
        textColor ?? (isSelected ? AppColors.primary : AppColors.foreground);

    return Row(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(option.icon, color: effectiveTextColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            option.label,
            style: AppTextTheme.navigationText.copyWith(
              color: effectiveTextColor,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (option.badgeCount != null && option.badgeCount! > 0) ...<Widget>[
          const SizedBox(width: 8),
          CountBadge(
            count: option.badgeCount!,
            variant: isSelected ? BadgeVariant.primary : BadgeVariant.warning,
          ),
        ],
      ],
    );
  }
}

/// ダッシュボード用モードセレクター
class DashboardModeSelector extends StatelessWidget {
  const DashboardModeSelector({
    required this.selectedMode,
    this.onModeChanged,
    this.pendingOrdersCount = 0,
    this.lowStockCount = 0,
    super.key,
  });

  final String selectedMode;
  final ValueChanged<String>? onModeChanged;
  final int pendingOrdersCount;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) => ModeSelector(
    options: <ModeOption>[
      ModeOption(
        id: "order",
        label: "オーダー作成",
        icon: LucideIcons.shoppingCart,
        badgeCount: pendingOrdersCount,
        description: "新規注文の作成・管理",
      ),
      ModeOption(
        id: "inventory",
        label: "在庫状況",
        icon: LucideIcons.layers,
        badgeCount: lowStockCount,
        description: "在庫レベルの確認",
      ),
    ],
    selectedMode: selectedMode,
    onModeChanged: onModeChanged,
    variant: ResponsiveHelper.isMobile(context)
        ? ModeSelectorVariant.segmented
        : ModeSelectorVariant.cards,
  );
}

/// 注文ステータス用モードセレクター
class OrderStatusModeSelector extends StatelessWidget {
  const OrderStatusModeSelector({
    required this.selectedMode,
    this.onModeChanged,
    this.preparingCount = 0,
    this.cookingCount = 0,
    this.readyCount = 0,
    super.key,
  });

  final String selectedMode;
  final ValueChanged<String>? onModeChanged;
  final int preparingCount;
  final int cookingCount;
  final int readyCount;

  @override
  Widget build(BuildContext context) => ModeSelector(
    options: <ModeOption>[
      ModeOption(id: "all", label: "すべて", icon: LucideIcons.list),
      ModeOption(
        id: "preparing",
        label: "準備中",
        icon: LucideIcons.clock,
        badgeCount: preparingCount,
      ),
      ModeOption(id: "cooking", label: "調理中", icon: LucideIcons.flame, badgeCount: cookingCount),
      ModeOption(id: "ready", label: "完成", icon: LucideIcons.checkCircle, badgeCount: readyCount),
    ],
    selectedMode: selectedMode,
    onModeChanged: onModeChanged,
    variant: ModeSelectorVariant.tabs,
  );
}

/// モードオプション
class ModeOption {
  const ModeOption({
    required this.id,
    required this.label,
    required this.icon,
    this.badgeCount,
    this.description,
  });

  final String id;
  final String label;
  final IconData icon;
  final int? badgeCount;
  final String? description;
}

/// モードセレクターバリアント
enum ModeSelectorVariant {
  segmented, // セグメント型
  tabs, // タブ型
  buttons, // ボタン型
  cards, // カード型
}
