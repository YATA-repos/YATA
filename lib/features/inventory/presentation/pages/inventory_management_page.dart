import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/mixins/route_aware_refresh_mixin.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../../shared/utils/unit_config.dart";
import "../../../order/presentation/pages/order_status_page.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../../models/inventory_model.dart" as inventory_models;
import "../controllers/inventory_management_controller.dart";
import "../widgets/inventory_category_panel.dart";
import "../widgets/inventory_management_header.dart";

/// 在庫管理画面。
class InventoryManagementPage extends ConsumerStatefulWidget {
  const InventoryManagementPage({super.key});

  static const String routeName = "/inventory";

  @override
  ConsumerState<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends ConsumerState<InventoryManagementPage>
    with RouteAwareRefreshMixin<InventoryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _tableKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get shouldRefreshOnPush => false;

  @override
  Future<void> onRouteReentered() async {
    if (!mounted) {
      return;
    }

    final InventoryManagementController controller = ref.read(
      inventoryManagementControllerProvider.notifier,
    );
    await _waitForStateIdle<InventoryManagementState>(
      controller,
      ref.read(inventoryManagementControllerProvider),
      (InventoryManagementState state) => !state.isLoading,
    );

    if (!mounted) {
      return;
    }

    await controller.loadInventory();
  }

  Future<void> _waitForStateIdle<S>(
    StateNotifier<S> controller,
    S currentState,
    bool Function(S state) isIdle,
  ) async {
    if (isIdle(currentState)) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    bool cancelled = false;
    late final StreamSubscription<S> subscription;

    subscription = controller.stream.listen(
      (S next) {
        if (isIdle(next) && !cancelled) {
          cancelled = true;
          unawaited(subscription.cancel());
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      onError: (Object _, StackTrace __) {
        if (!cancelled) {
          cancelled = true;
          unawaited(subscription.cancel());
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        if (!cancelled) {
          cancelled = true;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: false,
    );

    try {
      await completer.future;
    } finally {
      if (!cancelled) {
        await subscription.cancel();
      }
    }
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
            icon: Icons.refresh,
            tooltip: "在庫情報を再取得",
            onPressed: state.isLoading ? null : controller.refresh,
          ),
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
            InventoryManagementHeader(
              state: state,
              searchController: _searchController,
              onSearchChanged: controller.setSearchText,
              onStatusFilterChanged: (StockStatus? status) {
                controller.setStatusFilter(status);
                _scrollToTable();
              },
              onAddItem: _handleAddItem,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool showSidebar = constraints.maxWidth >= 1100;
                // 要注意・緊急補充のアイテムを抽出
                final List<InventoryItemViewData> attentionItems = state.items
                    .where(
                      (InventoryItemViewData item) =>
                          item.status == StockStatus.low || item.status == StockStatus.critical,
                    )
                    .toList(growable: false);

                final Widget attentionSection = _InventoryAttentionSection(
                  items: attentionItems,
                  onEditItem: _handleEditItem,
                  onShowAll: () {
                    // 要注意・緊急補充のフィルターは無いので、とりあえずすべて表示
                    controller.setStatusFilter(null);
                    _scrollToTable();
                  },
                );

                final Widget tableSection = _InventoryTable(
                  key: _tableKey,
                  state: state,
                  controller: controller,
                  onAddItem: _handleAddItem,
                  onEditItem: _handleEditItem,
                );

                final Widget sidebar = SizedBox(
                  width: showSidebar ? 260 : double.infinity,
                  child: InventoryCategoryPanel(
                    state: state,
                    onCategorySelected: controller.selectCategory,
                    onCreateCategory: _handleCreateCategory,
                    onEditCategory: (InventoryCategoryPanelData data) =>
                        unawaited(_handleRenameCategory(data)),
                    onDeleteCategory: (InventoryCategoryPanelData data) =>
                        unawaited(_handleDeleteCategory(data)),
                  ),
                );

                final Widget contentColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    attentionSection,
                    const SizedBox(height: YataSpacingTokens.lg),
                    tableSection,
                  ],
                );

                if (showSidebar) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      sidebar,
                      const SizedBox(width: YataSpacingTokens.lg),
                      Expanded(child: contentColumn),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    sidebar,
                    const SizedBox(height: YataSpacingTokens.lg),
                    contentColumn,
                  ],
                );
              },
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

  Future<void> _handleCreateCategory() async {
    await _showCreateCategoryDialog();
  }

  Future<bool> _showCreateCategoryDialog() async {
    final InventoryManagementController controller = ref.read(
      inventoryManagementControllerProvider.notifier,
    );

    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool created = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setDialogState) =>
            AlertDialog(
              title: const Text("カテゴリを追加"),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "カテゴリ名"),
                  enabled: !isSaving,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "カテゴリ名を入力してください";
                    }
                    return null;
                  },
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

                          setDialogState(() => isSaving = true);

                          final String? errorMessage = await controller.createCategory(
                            nameController.text,
                          );

                          if (!mounted || !dialogContext.mounted) {
                            return;
                          }

                          if (errorMessage != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(errorMessage)));
                            setDialogState(() => isSaving = false);
                            return;
                          }

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text("カテゴリを追加しました")));

                          created = true;
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text("追加"),
                ),
              ],
            ),
      ),
    );

    nameController.dispose();
    return created;
  }

  Future<void> _handleRenameCategory(InventoryCategoryPanelData data) async {
    if (data.categoryId == null) {
      return;
    }

    final String? newName = await _showRenameCategoryDialog(initialName: data.name);
    if (newName == null) {
      return;
    }

    final InventoryManagementController controller = ref.read(
      inventoryManagementControllerProvider.notifier,
    );

    final String? errorMessage = await controller.renameCategory(data.categoryId!, newName);

    if (!mounted) {
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("カテゴリ名を「$newName」に変更しました")));
  }

  Future<void> _handleDeleteCategory(InventoryCategoryPanelData data) async {
    if (data.categoryId == null) {
      return;
    }

    if (data.total > 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("在庫アイテムが残っているカテゴリは削除できません")));
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("カテゴリを削除"),
        content: Text("「${data.name}」を削除しますか？この操作は取り消せません。"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: YataColorTokens.danger),
            child: const Text("削除"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final InventoryManagementController controller = ref.read(
      inventoryManagementControllerProvider.notifier,
    );

    final String? errorMessage = await controller.deleteCategory(data.categoryId!);

    if (!mounted) {
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${data.name} を削除しました")));
  }

  Future<String?> _showRenameCategoryDialog({required String initialName}) async {
    final TextEditingController nameController = TextEditingController(text: initialName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setDialogState) =>
            AlertDialog(
              title: const Text("カテゴリ名を変更"),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "新しいカテゴリ名"),
                  enabled: !isSaving,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "カテゴリ名を入力してください";
                    }
                    if (value.trim().length > 30) {
                      return "カテゴリ名は30文字以下で入力してください";
                    }
                    return null;
                  },
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
                      : () {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          result = nameController.text.trim();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text("変更"),
                ),
              ],
            ),
      ),
    );

    nameController.dispose();
    return result;
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

    List<DropdownMenuItem<String>> buildCategoryItems(InventoryManagementState state) {
      final List<DropdownMenuItem<String>> items = state.categoryEntities
          .where((inventory_models.MaterialCategory category) => category.id != null)
          .map(
            (inventory_models.MaterialCategory category) =>
                DropdownMenuItem<String>(value: category.id!, child: Text(category.name)),
          )
          .toList(growable: true);

      if (initialItem != null &&
          initialItem.categoryId.isNotEmpty &&
          items.every((DropdownMenuItem<String> item) => item.value != initialItem.categoryId)) {
        items.add(
          DropdownMenuItem<String>(
            value: initialItem.categoryId,
            child: Text(initialItem.category),
          ),
        );
      }

      return items;
    }

    List<DropdownMenuItem<String>> categoryItems = buildCategoryItems(snapshot);

    if (categoryItems.isEmpty) {
      final bool created = await _showCreateCategoryDialog();
      if (!created) {
        showSnack("カテゴリが存在しません。先にカテゴリを作成してください");
        return;
      }

      final InventoryManagementState refreshedState = ref.read(
        inventoryManagementControllerProvider,
      );
      categoryItems = buildCategoryItems(refreshedState);

      if (categoryItems.isEmpty) {
        showSnack("カテゴリの取得に失敗しました。再度お試しください");
        return;
      }
    }

    String? selectedCategoryId = initialItem?.categoryId;
    if (selectedCategoryId == null ||
        selectedCategoryId.isEmpty ||
        categoryItems.every((DropdownMenuItem<String> item) => item.value != selectedCategoryId)) {
      selectedCategoryId = categoryItems.first.value;
    }
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final bool created = await _showCreateCategoryDialog();
                                    if (!created || !mounted || !dialogContext.mounted) {
                                      return;
                                    }

                                    final InventoryManagementState refreshedState = ref.read(
                                      inventoryManagementControllerProvider,
                                    );

                                    setDialogState(() {
                                      categoryItems = buildCategoryItems(refreshedState);
                                      if (categoryItems.isNotEmpty) {
                                        selectedCategoryId = categoryItems.last.value;
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text("カテゴリを追加"),
                          ),
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

    final List<InventoryRowViewData> rowViewData = controller.buildRowViewData();
    final Map<String, InventoryItemViewData> itemById = <String, InventoryItemViewData>{
      for (final InventoryItemViewData item in state.filteredItems) item.id: item,
    };

    final String? sortColumnId = _columnIdForSort(state.sortBy);

    final ThemeData theme = Theme.of(context);

    final List<YataTableColumnSpec> columnSpecs = <YataTableColumnSpec>[
      const YataTableColumnSpec(id: "item", label: Text("在庫アイテム")),
      YataTableColumnSpec(
        id: "category",
        label: const Text("カテゴリ"),
        onSort: (_) => controller.cycleSort(InventorySortBy.category),
      ),
      YataTableColumnSpec(
        id: "quantity",
        label: const Text("在庫状況"),
        onSort: (_) => controller.cycleSort(InventorySortBy.quantity),
      ),
      YataTableColumnSpec(
        id: "status",
        label: const Text("ステータス"),
        onSort: (_) => controller.cycleSort(InventorySortBy.state),
      ),
      YataTableColumnSpec(
        id: "adjustment",
        label: const Text("調整"),
        onSort: (_) => controller.cycleSort(InventorySortBy.delta),
      ),
      YataTableColumnSpec(
        id: "updated",
        label: const Text("更新"),
        onSort: (_) => controller.cycleSort(InventorySortBy.updatedAt),
      ),
    ];

    final List<YataTableRowSpec> rows = rowViewData
        .map((InventoryRowViewData row) {
          final bool canApplyItem = row.canApplyByRule && !row.isBusy;
          final Color deltaColor = _deltaColorFor(row.deltaTrend);

          final List<Widget> badgeWidgets = <Widget>[
            for (final InventoryRowBadgeViewData badge in row.badges)
              YataStatusBadge(label: badge.label, type: _toStatusBadgeType(badge.type)),
            if (row.isBusy)
              const YataStatusBadge(label: "処理中", type: YataStatusBadgeType.info, icon: Icons.sync),
          ];

          final Widget itemCell = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                row.name,
                style: (theme.textTheme.titleSmall ?? YataTypographyTokens.titleSmall).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                child: Text(
                  row.memo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: row.hasMemo
                        ? YataColorTokens.textSecondary
                        : YataColorTokens.textTertiary,
                    fontStyle: row.hasMemo ? null : FontStyle.italic,
                  ),
                ),
              ),
            ],
          );

          final Widget quantityCell = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(row.quantityLabel),
              const SizedBox(height: YataSpacingTokens.xs),
              Text(
                row.thresholdsLabel,
                style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                  color: YataColorTokens.textSecondary,
                ),
              ),
            ],
          );

          final String applyTooltip;
          if (!row.hasPendingDelta) {
            applyTooltip = "変更がありません";
          } else if (!row.canApplyByRule) {
            applyTooltip = "新在庫が0未満のため適用不可";
          } else if (row.isBusy) {
            applyTooltip = "処理中です";
          } else {
            applyTooltip = "この行の調整を適用";
          }

          final Widget adjustmentColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    row.deltaLabel,
                    style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                      color: deltaColor,
                    ),
                  ),
                  Text(row.afterChangeLabel, style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: Tooltip(
                        message: "未適用差分を調整",
                        child: YataQuantityStepper(
                          value: row.pendingDelta,
                          min: -9999,
                          onChanged: (int value) => controller.setPendingAdjustment(row.id, value),
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: YataSpacingTokens.sm),
                  SizedBox(
                    height: 36,
                    child: Tooltip(
                      message: applyTooltip,
                      child: ElevatedButton.icon(
                        onPressed: canApplyItem ? () => controller.applyAdjustment(row.id) : null,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text("適用"),
                        style: ElevatedButton.styleFrom(backgroundColor: YataColorTokens.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          return YataTableRowSpec(
            id: row.id,
            semanticLabel: row.name,
            isBusy: row.isBusy,
            cells: <YataTableCellSpec>[
              YataTableCellSpec.widget(builder: (_) => itemCell),
              YataTableCellSpec.text(label: row.categoryName),
              YataTableCellSpec.widget(builder: (_) => quantityCell),
              YataTableCellSpec.badges(
                badges: badgeWidgets,
                spacing: YataSpacingTokens.xs,
                runSpacing: YataSpacingTokens.xs,
              ),
              YataTableCellSpec.widget(
                builder: (_) => SizedBox(width: double.infinity, child: adjustmentColumn),
                applyRowBusyOverlay: true,
                errorMessage: row.errorMessage,
              ),
              YataTableCellSpec.widget(
                builder: (_) =>
                    Tooltip(message: row.updatedTooltip, child: Text(row.updatedAtLabel)),
              ),
            ],
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: YataSpacingTokens.xl,
              vertical: YataSpacingTokens.lg,
            ),
            decoration: BoxDecoration(
              color: YataColorTokens.neutral0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: YataColorTokens.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.inventory_2_outlined, size: 48, color: YataColorTokens.neutral400),
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  "登録済みの在庫アイテムがありません",
                  textAlign: TextAlign.center,
                  style: (theme.textTheme.titleSmall ?? YataTypographyTokens.titleSmall).copyWith(
                    color: YataColorTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: YataSpacingTokens.xs),
                Text(
                  "右上の「在庫を追加」から新しい在庫を登録してください。",
                  textAlign: TextAlign.center,
                  style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: YataColorTokens.textTertiary,
                  ),
                ),
              ],
            ),
          )
        else
          YataDataTable.fromSpecs(
            columns: columnSpecs,
            rows: rows,
            sortColumnId: sortColumnId,
            sortAscending: state.sortAsc,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 68,
            columnSpacing: YataSpacingTokens.xl,
            onRowTap: (int index) {
              final InventoryRowViewData tappedRow = rowViewData[index];
              final InventoryItemViewData? tappedItem = itemById[tappedRow.id];
              if (tappedItem != null && !tappedRow.isBusy) {
                widget.onEditItem(tappedItem);
              }
            },
          ),
      ],
    );
  }

  YataStatusBadgeType _toStatusBadgeType(InventoryRowBadgeType type) {
    switch (type) {
      case InventoryRowBadgeType.success:
        return YataStatusBadgeType.success;
      case InventoryRowBadgeType.warning:
        return YataStatusBadgeType.warning;
      case InventoryRowBadgeType.danger:
        return YataStatusBadgeType.danger;
      case InventoryRowBadgeType.info:
        return YataStatusBadgeType.info;
      case InventoryRowBadgeType.neutral:
        return YataStatusBadgeType.neutral;
    }
  }

  Color _deltaColorFor(InventoryDeltaTrend trend) {
    switch (trend) {
      case InventoryDeltaTrend.increase:
        return YataColorTokens.success;
      case InventoryDeltaTrend.decrease:
        return YataColorTokens.danger;
      case InventoryDeltaTrend.none:
        return YataColorTokens.textSecondary;
    }
  }

  String? _columnIdForSort(InventorySortBy sortBy) {
    switch (sortBy) {
      case InventorySortBy.category:
        return "category";
      case InventorySortBy.state:
        return "status";
      case InventorySortBy.quantity:
        return "quantity";
      case InventorySortBy.delta:
        return "adjustment";
      case InventorySortBy.updatedAt:
        return "updated";
      case InventorySortBy.none:
        return null;
    }
  }
}

/// 要注意在庫セクション。
class _InventoryAttentionSection extends StatelessWidget {
  const _InventoryAttentionSection({
    required this.items,
    required this.onEditItem,
    required this.onShowAll,
  });

  final List<InventoryItemViewData> items;
  final ValueChanged<InventoryItemViewData> onEditItem;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (items.isEmpty) {
      return YataSectionCard(
        title: "要注意在庫アイテム",
        subtitle: "対応が必要な在庫アイテムはありません",
        child: Text(
          "すべての在庫状態は良好です。",
          style: theme.textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
        ),
      );
    }

    final List<InventoryItemViewData> highlights = items.take(3).toList(growable: false);

    return YataSectionCard(
      title: "要注意在庫アイテム",
      subtitle: "優先して確認したい在庫アイテムをまとめました",
      actions: <Widget>[TextButton(onPressed: onShowAll, child: const Text("一覧で表示"))],
      child: Column(
        children: <Widget>[
          for (int index = 0; index < highlights.length; index++) ...<Widget>[
            _AttentionInventoryTile(item: highlights[index], onEditItem: onEditItem),
            if (index != highlights.length - 1) const SizedBox(height: YataSpacingTokens.sm),
          ],
        ],
      ),
    );
  }
}

class _Status {
  const _Status({required this.color, required this.bg});

  final Color color;
  final Color bg;
}

_Status _statusFor(StockStatus status) {
  switch (status) {
    case StockStatus.sufficient:
      return const _Status(color: YataColorTokens.success, bg: YataColorTokens.successSoft);
    case StockStatus.low:
      return const _Status(color: YataColorTokens.warning, bg: YataColorTokens.warningSoft);
    case StockStatus.critical:
      return const _Status(color: YataColorTokens.danger, bg: YataColorTokens.dangerSoft);
  }
}

/// 要注意在庫アイテムのタイル。
class _AttentionInventoryTile extends StatelessWidget {
  const _AttentionInventoryTile({required this.item, required this.onEditItem});

  final InventoryItemViewData item;
  final ValueChanged<InventoryItemViewData> onEditItem;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _Status status = _statusFor(item.status);
    final UnitType unitType = _unitFromSymbol(item.unit);

    final List<Widget> badges = <Widget>[
      if (item.status == StockStatus.critical)
        const YataStatusBadge(label: "緊急補充", type: YataStatusBadgeType.danger)
      else if (item.status == StockStatus.low)
        const YataStatusBadge(label: "要注意", type: YataStatusBadgeType.warning),
    ];

    final List<Widget> supplemental = <Widget>[
      YataTag(
        label: "現在: ${UnitFormatter.format(item.current, unitType)}",
        icon: Icons.inventory_2_outlined,
        backgroundColor: status.bg,
        foregroundColor: status.color,
      ),
      YataTag(
        label: "警告: ${UnitFormatter.format(item.alertThreshold, unitType)}",
        icon: Icons.warning_amber_outlined,
        backgroundColor: YataColorTokens.warningSoft,
        foregroundColor: YataColorTokens.warning,
      ),
      YataTag(
        label: "危険: ${UnitFormatter.format(item.criticalThreshold, unitType)}",
        icon: Icons.report_outlined,
        backgroundColor: YataColorTokens.dangerSoft,
        foregroundColor: YataColorTokens.danger,
      ),
    ];

    return Material(
      color: YataColorTokens.neutral50,
      borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
      child: InkWell(
        onTap: () => onEditItem(item),
        borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
        child: Padding(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: YataSpacingTokens.xs),
                        Text(
                          item.category,
                          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                            color: YataColorTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: YataSpacingTokens.xs,
                    runSpacing: YataSpacingTokens.xs,
                    children: badges,
                  ),
                ],
              ),
              const SizedBox(height: YataSpacingTokens.sm),
              Wrap(
                spacing: YataSpacingTokens.sm,
                runSpacing: YataSpacingTokens.xs,
                children: supplemental,
              ),
            ],
          ),
        ),
      ),
    );
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
