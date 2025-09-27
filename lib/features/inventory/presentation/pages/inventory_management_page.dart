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
import "../../../order/presentation/pages/order_status_page.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../../models/inventory_model.dart";
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
            onTap: () => context.go("/order"),
          ),
          YataNavItem(
            label: "注文状況",
            icon: Icons.dashboard_customize_outlined,
            onTap: () => context.go(OrderStatusPage.routeName),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          const YataNavItem(label: "在庫管理", icon: Icons.inventory_2_outlined, isActive: true),
          YataNavItem(
            label: "メニュー管理",
            icon: Icons.restaurant_menu_outlined,
            onTap: () => context.go("/menu"),
          ),
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go("/analytics"),
          ),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.settings,
            onPressed: () => context.go(SettingsPage.routeName),
            tooltip: "設定",
          ),
        ],
      ),
      body: YataPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: YataSpacingTokens.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
            ),
            if (state.isLoading) const SizedBox(height: YataSpacingTokens.md),
            if (state.errorMessage != null) ...<Widget>[
              _ErrorBanner(message: state.errorMessage!, onRetry: controller.refresh),
              const SizedBox(height: YataSpacingTokens.md),
            ],
            _HeaderStats(state: state, controller: controller, onDrillDown: _scrollToTable),
            const SizedBox(height: YataSpacingTokens.lg),
            _ControlsRow(searchController: _searchController, state: state, controller: controller),
            const SizedBox(height: YataSpacingTokens.lg),
            _InventoryTable(
              key: _tableKey,
              state: state,
              controller: controller,
              onAddItem: _handleAddItem,
              onEditItem: _handleEditItem,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddItem() async {
    await _showInventoryItemDialog();
  }

  Future<void> _handleEditItem(InventoryItemViewData item) async {
    await _showInventoryItemDialog(initialItem: item);
  }

  Future<void> _showInventoryItemDialog({InventoryItemViewData? initialItem}) async {
    final InventoryManagementState snapshot = ref.read(inventoryManagementControllerProvider);
    final InventoryManagementController controller = ref.read(
      inventoryManagementControllerProvider.notifier,
    );

    void showSnack(String message) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    final List<DropdownMenuItem<String>> categoryItems = snapshot.categoryEntities
        .where((MaterialCategory category) => category.id != null)
        .map(
          (MaterialCategory category) =>
              DropdownMenuItem<String>(value: category.id!, child: Text(category.name)),
        )
        .toList(growable: true);

    if (initialItem != null &&
        initialItem.categoryId.isNotEmpty &&
        categoryItems.every(
          (DropdownMenuItem<String> item) => item.value != initialItem.categoryId,
        )) {
      categoryItems.add(
        DropdownMenuItem<String>(value: initialItem.categoryId, child: Text(initialItem.category)),
      );
    }

    if (categoryItems.isEmpty) {
      showSnack("カテゴリが存在しません。先にカテゴリを作成してください");
      return;
    }

    String? selectedCategoryId = initialItem?.categoryId ?? categoryItems.first.value;
    UnitType selectedUnit = initialItem?.unitType ?? UnitType.piece;

    String formatNumber(double value) =>
        value % 1 == 0 ? value.toInt().toString() : value.toString();

    final TextEditingController nameController = TextEditingController(
      text: initialItem?.name ?? "",
    );
    final TextEditingController quantityController = TextEditingController(
      text: initialItem != null ? formatNumber(initialItem.current) : "0",
    );
    final TextEditingController alertController = TextEditingController(
      text: initialItem != null ? formatNumber(initialItem.alertThreshold) : "0",
    );
    final TextEditingController criticalController = TextEditingController(
      text: initialItem != null ? formatNumber(initialItem.criticalThreshold) : "0",
    );
    final TextEditingController notesController = TextEditingController(
      text: initialItem?.notes ?? "",
    );

    bool isSaving = false;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setDialogState) =>
            AlertDialog(
              title: Text(initialItem == null ? "在庫を追加" : "在庫を編集"),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: "品目名"),
                          enabled: !isSaving,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "品目名を入力してください";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: selectedCategoryId,
                          decoration: const InputDecoration(labelText: "カテゴリ"),
                          items: categoryItems,
                          onChanged: isSaving
                              ? null
                              : (String? value) {
                                  setDialogState(() => selectedCategoryId = value);
                                },
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "カテゴリを選択してください";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        DropdownButtonFormField<UnitType>(
                          // ignore: deprecated_member_use
                          value: selectedUnit,
                          decoration: const InputDecoration(labelText: "単位"),
                          items: UnitType.values
                              .map(
                                (UnitType type) => DropdownMenuItem<UnitType>(
                                  value: type,
                                  child: Text(type.displayName),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isSaving
                              ? null
                              : (UnitType? value) {
                                  if (value != null) {
                                    setDialogState(() => selectedUnit = value);
                                  }
                                },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(labelText: "現在在庫(${selectedUnit.symbol})"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !isSaving,
                          validator: (String? value) {
                            final double? parsed = double.tryParse(value?.trim() ?? "");
                            if (parsed == null || parsed < 0) {
                              return "0以上の数値を入力してください";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        TextFormField(
                          controller: alertController,
                          decoration: const InputDecoration(labelText: "警告閾値"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !isSaving,
                          validator: (String? value) {
                            final double? parsed = double.tryParse(value?.trim() ?? "");
                            if (parsed == null || parsed < 0) {
                              return "0以上の数値を入力してください";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        TextFormField(
                          controller: criticalController,
                          decoration: const InputDecoration(labelText: "危険閾値"),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !isSaving,
                          validator: (String? value) {
                            final double? parsed = double.tryParse(value?.trim() ?? "");
                            if (parsed == null || parsed < 0) {
                              return "0以上の数値を入力してください";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(labelText: "メモ", hintText: "仕入れ先や補足など"),
                          enabled: !isSaving,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text("キャンセル"),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
                            showSnack("カテゴリを選択してください");
                            return;
                          }

                          final double quantity = double.parse(quantityController.text.trim());
                          final double alert = double.parse(alertController.text.trim());
                          final double critical = double.parse(criticalController.text.trim());

                          if (critical > alert) {
                            showSnack("危険閾値は警告閾値以下で入力してください");
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          final String trimmedNotes = notesController.text.trim();
                          final String? errorMessage = initialItem == null
                              ? await controller.createInventoryItem(
                                  name: nameController.text.trim(),
                                  categoryId: selectedCategoryId!,
                                  unitType: selectedUnit,
                                  currentStock: quantity,
                                  alertThreshold: alert,
                                  criticalThreshold: critical,
                                  notes: trimmedNotes.isEmpty ? null : trimmedNotes,
                                )
                              : await controller.updateInventoryItem(
                                  initialItem.id,
                                  name: nameController.text.trim(),
                                  categoryId: selectedCategoryId!,
                                  unitType: selectedUnit,
                                  currentStock: quantity,
                                  alertThreshold: alert,
                                  criticalThreshold: critical,
                                  notes: trimmedNotes.isEmpty ? null : trimmedNotes,
                                );

                          if (!mounted || !dialogContext.mounted) {
                            return;
                          }

                          if (errorMessage != null) {
                            showSnack(errorMessage);
                            setDialogState(() => isSaving = false);
                            return;
                          }

                          showSnack(initialItem == null ? "在庫を追加しました" : "在庫を更新しました");

                          Navigator.of(dialogContext).pop();
                        },
                  child: Text(initialItem == null ? "追加" : "保存"),
                ),
              ],
            ),
      ),
    );

    nameController.dispose();
    quantityController.dispose();
    alertController.dispose();
    criticalController.dispose();
    notesController.dispose();
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
    final Widget interactive = onTap == null
        ? chip
        : InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
            child: chip,
          );
    final String tooltipMessage = onTap == null
        ? label
        : (isActive ? "$label を表示中です。\nタップでフィルタを解除します。" : "$label の在庫を表示します。\nタップでフィルタを適用します。");

    return Tooltip(message: tooltipMessage, child: interactive);
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

class _InventoryTable extends StatefulWidget {
  const _InventoryTable({
    required this.state,
    required this.controller,
    required this.onAddItem,
    required this.onEditItem,
    super.key,
  });
  final InventoryManagementState state;
  final InventoryManagementController controller;
  final VoidCallback onAddItem;
  final void Function(InventoryItemViewData) onEditItem;

  @override
  State<_InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<_InventoryTable> {
  @override
  Widget build(BuildContext context) {
    final InventoryManagementState state = widget.state;
    final InventoryManagementController controller = widget.controller;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final Set<String> visibleIds = state.filteredItems
        .map((InventoryItemViewData i) => i.id)
        .toSet();
    final int selectedVisibleCount = state.selectedIds.where(visibleIds.contains).length;
    final bool noneSelected = selectedVisibleCount == 0;
    final bool allSelected = selectedVisibleCount == visibleIds.length && visibleIds.isNotEmpty;

    int? sortIndex;
    switch (state.sortBy) {
      case InventorySortBy.state:
        sortIndex = 5;
        break;
      case InventorySortBy.quantity:
        sortIndex = 3;
        break;
      case InventorySortBy.delta:
        sortIndex = 6;
        break;
      case InventorySortBy.updatedAt:
        sortIndex = 7;
        break;
      case InventorySortBy.none:
        sortIndex = null;
        break;
    }

    final List<DataColumn> columns = <DataColumn>[
      DataColumn(
        label: Tooltip(
          message: "表示中の行を全選択/全解除",
          child: Checkbox(
            tristate: true,
            value: allSelected ? true : (noneSelected ? false : null),
            onChanged: (bool? v) => controller.selectAll(v ?? false),
          ),
        ),
      ),
      const DataColumn(label: Text("カテゴリ")),
      const DataColumn(label: Text("品目")),
      DataColumn(
        label: const Text("在庫量"),
        numeric: true,
        onSort: (int columnIndex, bool ascending) {
          columnIndex;
          ascending;
          controller.cycleSort(InventorySortBy.quantity);
        },
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
        onSort: (int columnIndex, bool ascending) {
          columnIndex;
          ascending;
          controller.cycleSort(InventorySortBy.state);
        },
      ),
      DataColumn(
        label: const Text("調整"),
        onSort: (int columnIndex, bool ascending) {
          columnIndex;
          ascending;
          controller.cycleSort(InventorySortBy.delta);
        },
      ),
      DataColumn(
        label: const Text("更新日時"),
        onSort: (int columnIndex, bool ascending) {
          columnIndex;
          ascending;
          controller.cycleSort(InventorySortBy.updatedAt);
        },
      ),
      const DataColumn(label: Text("編集")),
      const DataColumn(label: Text("適用")),
    ];

    final List<DataRow> rows = state.filteredItems
        .map((InventoryItemViewData item) {
          final int delta = state.pendingAdjustments[item.id] ?? 0;
          final double after = (item.current + delta).clamp(0, double.infinity);
          final UnitType unitType = _unitFromSymbol(item.unit);
          final String threshold =
              "警告閾値:${UnitFormatter.format(item.alertThreshold, unitType)} / 危険閾値:${UnitFormatter.format(item.criticalThreshold, unitType)}";
          final _Status status = _statusFor(item.status);
          final Color deltaColor = delta == 0
              ? YataColorTokens.textSecondary
              : (delta > 0 ? YataColorTokens.success : YataColorTokens.danger);
          final bool selected = state.selectedIds.contains(item.id);

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
              DataCell(
                Tooltip(
                  message: selected ? "選択解除" : "この行を選択",
                  child: Checkbox(
                    value: selected,
                    onChanged: (bool? v) => controller.toggleSelect(item.id),
                  ),
                ),
              ),
              DataCell(Text(item.category)),
              DataCell(Text(item.name)),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: item.current.toStringAsFixed(0)),
                        const TextSpan(text: " "),
                        TextSpan(
                          text: item.unit,
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
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            delta == 0 ? "±0" : (delta > 0 ? "+$delta" : "$delta"),
                            style: (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
                                .copyWith(color: deltaColor),
                          ),
                          const SizedBox(width: YataSpacingTokens.sm),
                          Text(
                            "→ ${UnitFormatter.format(after, unitType)} ${item.unit}",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 36,
                        child: Tooltip(
                          message: "未適用差分を調整",
                          child: YataQuantityStepper(
                            value: delta,
                            min: -9999,
                            onChanged: (int value) =>
                                controller.setPendingAdjustment(item.id, value),
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Tooltip(
                  message: "最終更新: ${fmtDate(item.updatedAt)} / by ${item.updatedBy}",
                  child: Text(fmtDate(item.updatedAt)),
                ),
              ),
              DataCell(
                Tooltip(
                  message: "在庫情報を編集",
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => widget.onEditItem(item),
                  ),
                ),
              ),
              DataCell(
                Tooltip(
                  message: delta == 0
                      ? "変更がありません"
                      : ((item.current + delta) < 0 ? "新在庫が0未満のため適用不可" : "この行の調整を適用"),
                  child: ElevatedButton.icon(
                    onPressed: delta == 0 || (item.current + delta) < 0
                        ? null
                        : () => controller.applyAdjustment(item.id),
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

    final int visibleApplicableCount = state.filteredItems.where((InventoryItemViewData item) {
      final int delta = state.pendingAdjustments[item.id] ?? 0;
      if (delta == 0) {
        return false;
      }
      return controller.canApply(item.id);
    }).length;
    final bool canApplyVisible = visibleApplicableCount > 0;
    final bool hasPending = state.pendingAdjustments.isNotEmpty;
    final int pendingTotal = state.pendingDeltaTotal;
    final String pendingTotalLabel = pendingTotal > 0 ? "+$pendingTotal" : "$pendingTotal";
    final String pendingSummary = "未適用: ${state.pendingCount}件 / 合計: $pendingTotalLabel";

    return YataSectionCard(
      title: "在庫一覧",
      expandChild: true,
      subtitle: "数量の調整はその場で編集できます",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<double> curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              return FadeTransition(
                opacity: curve,
                child: SizeTransition(sizeFactor: curve, child: child),
              );
            },
            child: state.selectedIds.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: YataSpacingTokens.sm),
                    child: Wrap(
                      spacing: YataSpacingTokens.sm,
                      runSpacing: YataSpacingTokens.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Tooltip(
                          message: "選択行に一括で減算 (−1)",
                          child: OutlinedButton(
                            onPressed: () => controller.incrementSelectedBy(-1),
                            child: const Icon(Icons.remove),
                          ),
                        ),
                        Tooltip(
                          message: "選択行に一括で加算 (+1)",
                          child: OutlinedButton(
                            onPressed: () => controller.incrementSelectedBy(1),
                            child: const Icon(Icons.add),
                          ),
                        ),
                        Tooltip(
                          message: "選択を解除",
                          child: OutlinedButton.icon(
                            onPressed: controller.clearSelection,
                            icon: const Icon(Icons.clear),
                            label: const Text("選択解除"),
                          ),
                        ),
                        Tooltip(
                          message: "選択行を削除（モック）",
                          child: TextButton.icon(
                            onPressed: () async {
                              final int count = state.selectedIds.length;
                              final bool confirmed = await _confirmBulkAction(
                                context: context,
                                title: "選択行を削除",
                                message: "$count件の行を削除します。よろしいですか？",
                                confirmLabel: "削除する",
                                confirmColor: Colors.redAccent,
                              );
                              if (!confirmed || !mounted) {
                                return;
                              }
                              controller.deleteSelected();
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            label: const Text("削除", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: YataSpacingTokens.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool narrow = constraints.maxWidth < 720;
              final TextStyle summaryStyle =
                  Theme.of(context).textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium;
              final Widget summaryLabel = Text(pendingSummary, style: summaryStyle);
              final List<Widget> actions = <Widget>[
                OutlinedButton.icon(
                  onPressed: hasPending ? controller.clearAllAdjustments : null,
                  icon: const Icon(Icons.undo),
                  label: const Text("全てクリア"),
                ),
                OutlinedButton.icon(
                  onPressed: canApplyVisible ? controller.applyAllVisible : null,
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text("表示分を適用"),
                ),
                FilledButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add),
                  label: const Text("在庫を追加"),
                  style: FilledButton.styleFrom(backgroundColor: YataColorTokens.primary),
                ),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    summaryLabel,
                    const SizedBox(height: YataSpacingTokens.sm),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: YataSpacingTokens.sm,
                      runSpacing: YataSpacingTokens.sm,
                      children: actions,
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: summaryLabel),
                  Wrap(
                    spacing: YataSpacingTokens.sm,
                    runSpacing: YataSpacingTokens.sm,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: YataSpacingTokens.md),
          YataDataTable(
            columns: columns,
            rows: rows,
            sortColumnIndex: sortIndex,
            sortAscending: state.sortAsc,
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmBulkAction({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
    String cancelLabel = "キャンセル",
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: confirmColor == null
                ? null
                : FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: BoxDecoration(
      color: YataColorTokens.dangerSoft,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      border: Border.all(color: YataColorTokens.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.error_outline, color: YataColorTokens.danger),
        const SizedBox(width: YataSpacingTokens.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: YataColorTokens.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("再試行"),
        ),
      ],
    ),
  );
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
