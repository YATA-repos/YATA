import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../../shared/utils/unit_config.dart";
import "../controllers/inventory_management_controller.dart";

/// 在庫管理画面。
class InventoryManagementPage extends ConsumerStatefulWidget {
  const InventoryManagementPage({super.key});

  static const String routeName = "/inventory";

  @override
  ConsumerState<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends ConsumerState<InventoryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _tableKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InventoryManagementState state = ref.watch(inventoryManagementControllerProvider);
    final InventoryManagementController controller = ref.watch(
      inventoryManagementControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: YataColorTokens.background,
      appBar: YataAppTopBar(
        navItems: <YataNavItem>[
          YataNavItem(
            label: "注文",
            icon: Icons.shopping_cart_outlined,
            onTap: () => context.go("/"),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          const YataNavItem(label: "在庫管理", icon: Icons.inventory_2_outlined, isActive: true),
          const YataNavItem(label: "売上分析", icon: Icons.query_stats_outlined),
        ],
      ),
      body: YataPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: YataSpacingTokens.lg),
            _HeaderStats(
              state: state,
              controller: controller,
              onDrillDown: _scrollToTable,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            _ControlsRow(searchController: _searchController, state: state, controller: controller),
            const SizedBox(height: YataSpacingTokens.lg),
            _InventoryTable(key: _tableKey, state: state, controller: controller),
            const SizedBox(height: YataSpacingTokens.lg),
          ],
        ),
      ),
    );
  }

  void _scrollToTable() {
    final BuildContext? ctx = _tableKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.state, required this.controller, required this.onDrillDown});
  final InventoryManagementState state;
  final InventoryManagementController controller;
  final VoidCallback onDrillDown;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoCols = constraints.maxWidth >= 900;
          final double gap = YataSpacingTokens.lg;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              SizedBox(
                width: twoCols ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth,
                child: YataStatCard(
                  title: "登録アイテム",
                  value: "${state.totalItems}",
                  trend: YataStatTrend.steady,
                  trendLabel: "今週",
                ),
              ),
              SizedBox(
                width: twoCols ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth,
                child: YataSectionCard(
                  title: "在庫ステータス",
                  child: Row(
                    children: <Widget>[
                      _StatusPill(
                        color: YataColorTokens.success,
                        bg: YataColorTokens.successSoft,
                        label: "十分: ${state.totalItems - state.lowCount - state.criticalCount}",
                        isActive: state.selectedStatusFilter == StockStatus.sufficient,
                        onTap: () {
                          controller.toggleStatusFilter(StockStatus.sufficient);
                          onDrillDown();
                        },
                      ),
                      const SizedBox(width: YataSpacingTokens.md),
                      _StatusPill(
                        color: YataColorTokens.warning,
                        bg: YataColorTokens.warningSoft,
                        label: "少: ${state.lowCount}",
                        isActive: state.selectedStatusFilter == StockStatus.low,
                        onTap: () {
                          controller.toggleStatusFilter(StockStatus.low);
                          onDrillDown();
                        },
                      ),
                      const SizedBox(width: YataSpacingTokens.md),
                      _StatusPill(
                        color: YataColorTokens.danger,
                        bg: YataColorTokens.dangerSoft,
                        label: "危険: ${state.criticalCount}",
                        isActive: state.selectedStatusFilter == StockStatus.critical,
                        onTap: () {
                          controller.toggleStatusFilter(StockStatus.critical);
                          onDrillDown();
                        },
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onDrillDown,
                        icon: const Icon(Icons.south),
                        label: const Text("一覧へ移動"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.bg,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final Color color;
  final Color bg;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBg = isActive ? color.withValues(alpha: 0.1) : bg;
    final Color effectiveBorder = isActive ? color : color.withValues(alpha: 0.6);
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YataSpacingTokens.md,
        vertical: YataSpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        border: Border.all(color: effectiveBorder, width: isActive ? 2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: (Theme.of(context).textTheme.labelLarge ?? YataTypographyTokens.labelLarge)
                .copyWith(color: color),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      child: chip,
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.searchController,
    required this.state,
    required this.controller,
  });

  final TextEditingController searchController;
  final InventoryManagementState state;
  final InventoryManagementController controller;

  @override
  Widget build(BuildContext context) {
    final List<YataFilterSegment> segments = state.categories
        .map((String c) => YataFilterSegment(label: c))
        .toList(growable: false);

    return Row(
      children: <Widget>[
        Expanded(
          child: YataSearchField(
            controller: searchController,
            hintText: "在庫を検索...",
            onChanged: controller.setSearchText,
          ),
        ),
        const SizedBox(width: YataSpacingTokens.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: YataSegmentedFilter(
            segments: segments,
            selectedIndex: state.selectedCategoryIndex,
            onSegmentSelected: controller.selectCategory,
          ),
        ),
      ],
    );
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.state, required this.controller, super.key});
  final InventoryManagementState state;
  final InventoryManagementController controller;

  @override
  Widget build(BuildContext context) {
    // ヘッダの全選択チェックボックス表示判定
    final Set<String> visibleIds = state.filteredItems.map((InventoryItemViewData i) => i.id).toSet();
    final int selectedVisibleCount =
        state.selectedIds.where(visibleIds.contains).length;
    final bool noneSelected = selectedVisibleCount == 0;
    final bool allSelected = selectedVisibleCount == visibleIds.length && visibleIds.isNotEmpty;

    int? sortIndex;
    switch (state.sortBy) {
      case InventorySortBy.state:
        sortIndex = 5; // 状態 (先頭に選択列を追加したため+1)
        break;
      case InventorySortBy.quantity:
        sortIndex = 3; // 在庫量
        break;
      case InventorySortBy.delta:
        sortIndex = 6; // 調整(差分)
        break;
      case InventorySortBy.updatedAt:
        sortIndex = 7; // 更新日時
        break;
      case InventorySortBy.none:
        sortIndex = null;
        break;
    }

    final List<DataColumn> columns = <DataColumn>[
      DataColumn(
        label: Checkbox(
          tristate: true,
          value: allSelected ? true : (noneSelected ? false : null),
          onChanged: (bool? v) => controller.selectAll(v ?? false),
        ),
      ),
      const DataColumn(label: Text("カテゴリ")),
      const DataColumn(label: Text("品目")),
      DataColumn(
        label: const Text("在庫量"),
        numeric: true,
        onSort: (_, __) => controller.cycleSort(InventorySortBy.quantity),
      ),
      DataColumn(
        label: Row(
          children: <Widget>[
            const Text("閾値"),
            const SizedBox(width: 4),
            Tooltip(
              message: "警告閾値: 在庫がこの値以下で\n警告状態に。\n危険閾値: 在庫がこの値以下で\n危険状態に。",
              child: InkWell(
                onTap: () => _showThresholdHelp(context),
                child: const Icon(Icons.help_outline, size: 16),
              ),
            ),
          ],
        ),
      ),
      DataColumn(
        label: const Text("状態"),
        onSort: (_, __) => controller.cycleSort(InventorySortBy.state),
      ),
      DataColumn(
        label: const Text("調整"),
        onSort: (_, __) => controller.cycleSort(InventorySortBy.delta),
      ),
      DataColumn(
        label: const Text("更新日時"),
        onSort: (_, __) => controller.cycleSort(InventorySortBy.updatedAt),
      ),
      const DataColumn(label: Text("適用")),
    ];

    final List<DataRow> rows = state.filteredItems
        .map((InventoryItemViewData i) {
          final int delta = state.pendingAdjustments[i.id] ?? 0;
          final double after = (i.current + delta).clamp(0, double.infinity);
      final UnitType unitType = _unitFromSymbol(i.unit);
      final String threshold =
        "警告閾値:${UnitFormatter.format(i.alertThreshold, unitType)} / 危険閾値:${UnitFormatter.format(i.criticalThreshold, unitType)}";
          final _Status status = _statusFor(i.status);
          final Color deltaColor = delta == 0
              ? YataColorTokens.textSecondary
              : (delta > 0 ? YataColorTokens.success : YataColorTokens.danger);
          final bool selected = state.selectedIds.contains(i.id);
          String fmtDate(DateTime d) {
            final DateTime dd = d.toLocal();
            final String ymd =
                "${dd.year.toString().padLeft(4, '0')}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}";
            final String hm =
                "${dd.hour.toString().padLeft(2, '0')}:${dd.minute.toString().padLeft(2, '0')}";
            return "$ymd $hm";
          }

          return DataRow(
            cells: <DataCell>[
              DataCell(Checkbox(
                value: selected,
                onChanged: (bool? v) => controller.toggleSelect(i.id),
              )),
              DataCell(Text(i.category)),
              DataCell(Text(i.name)),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: i.current.toStringAsFixed(0)),
                        const TextSpan(text: " "),
                        TextSpan(
                          text: i.unit,
                          style: TextStyle(color: YataColorTokens.textSecondary),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              DataCell(Text(threshold)),
              DataCell(_StatusChip(status: status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      delta == 0 ? "±0" : (delta > 0 ? "+$delta" : "$delta"),
                      style: (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
                        color: deltaColor,
                      ),
                    ),
                    const SizedBox(width: YataSpacingTokens.sm),
                    Text(
                      "→ ${UnitFormatter.format(after, unitType)} ${i.unit}",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: YataSpacingTokens.md),
                    YataQuantityStepper(
                      value: delta,
                      min: -9999,
                      onChanged: (int v) => controller.setPendingAdjustment(i.id, v),
                      compact: true,
                    ),
                    const SizedBox(width: YataSpacingTokens.sm),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: TextEditingController(text: "$delta"),
                        onSubmitted: (String v) {
                          final int? parsed = int.tryParse(v.trim());
                          if (parsed == null) return;
                          controller.setPendingAdjustment(i.id, parsed);
                        },
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(isDense: true, hintText: "0"),
                      ),
                    ),
                  ],
                ),
              ),
              // 更新日時列
              DataCell(Text(fmtDate(i.updatedAt))),
              DataCell(
                Tooltip(
                  message: delta == 0
                      ? "変更がありません"
                      : ((i.current + delta) < 0 ? "新在庫が0未満のため適用不可" : "この行の調整を適用"),
                  child: ElevatedButton.icon(
                    onPressed: delta == 0 || (i.current + delta) < 0
                        ? null
                        : () => controller.applyAdjustment(i.id),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text("適用"),
                    style: ElevatedButton.styleFrom(backgroundColor: YataColorTokens.primary),
                  ),
                ),
              ),
            ],
          );
        })
        .toList(growable: false);

    return YataSectionCard(
      title: "在庫一覧",
      expandChild: true,
      subtitle: "数量の調整はその場で編集できます",
      actions: <Widget>[
        Row(
          children: <Widget>[
            Text(
              () {
                final int t = state.pendingDeltaTotal;
                final String tLabel = t > 0 ? "+$t" : "$t";
                return "未適用: ${state.pendingCount}件 / 合計: $tLabel";
              }(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: YataSpacingTokens.md),
          ],
        ),
        OutlinedButton.icon(
          onPressed: state.pendingAdjustments.isEmpty ? null : controller.clearAllAdjustments,
          icon: const Icon(Icons.undo),
          label: const Text("未適用の調整をクリア"),
        ),
      ],
      child: YataDataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: sortIndex,
        sortAscending: state.sortAsc,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 72,
      ),
    );
  }
}

class _Status {
  const _Status(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

_Status _statusFor(StockStatus s) {
  switch (s) {
    case StockStatus.sufficient:
      return _Status("十分", YataColorTokens.success, YataColorTokens.successSoft);
    case StockStatus.low:
      return _Status("少", YataColorTokens.warning, YataColorTokens.warningSoft);
    case StockStatus.critical:
      return _Status("危険", YataColorTokens.danger, YataColorTokens.dangerSoft);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: YataSpacingTokens.sm,
      vertical: YataSpacingTokens.xs,
    ),
    decoration: BoxDecoration(
      color: status.bg,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      border: Border.all(color: status.color.withValues(alpha: 0.6)),
    ),
    child: Text(
      status.label,
      style: (Theme.of(context).textTheme.labelMedium ?? YataTypographyTokens.labelMedium).copyWith(
        color: status.color,
      ),
    ),
  );
}

// --- Helpers & dialogs ---

void _showThresholdHelp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text("閾値の説明"),
      content: const Text(
        "警告閾値: 在庫がこの値以下になると『少』状態になります。\n"
        "危険閾値: 在庫がこの値以下になると『危険』状態になります。",
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("閉じる")),
      ],
    ),
  );
}

void _showHistory(BuildContext context, InventoryItemViewData item) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text("履歴: ${item.name}"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text("過去の変更履歴は今後API実装で取得します。今はダミー表示です。"),
            SizedBox(height: YataSpacingTokens.md),
            Text("- 2025-09-20 10:32 by tanaka: -3"),
            Text("- 2025-09-18 16:05 by suzuki: +5"),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("閉じる")),
      ],
    ),
  );
}

UnitType _unitFromSymbol(String symbol) {
  switch (symbol) {
    case "個":
      return UnitType.piece;
    case "g":
      return UnitType.gram;
    case "kg":
      return UnitType.kilogram;
    case "L":
      return UnitType.liter;
    default:
      return UnitType.piece;
  }
}

// removed unused legacy helper
