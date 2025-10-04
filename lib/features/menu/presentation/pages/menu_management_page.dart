import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/mixins/route_aware_refresh_mixin.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../analytics/presentation/pages/sales_analytics_page.dart";
import "../../../inventory/presentation/pages/inventory_management_page.dart";
import "../../../order/presentation/pages/order_history_page.dart";
import "../../../order/presentation/pages/order_status_page.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../../dto/menu_recipe_detail.dart";
import "../controllers/menu_management_controller.dart";
import "../controllers/menu_management_state.dart";
import "../widgets/menu_category_panel.dart";
import "../widgets/menu_detail_panel.dart";
import "../widgets/menu_item_table.dart";
import "../widgets/menu_management_header.dart";

/// メニュー管理画面。
class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  static const String routeName = "/menu";

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with RouteAwareRefreshMixin<MenuManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _detailDialogOpen = false;
  Completer<void>? _refreshCompleter;

  MenuManagementController get _controller => ref.read(menuManagementControllerProvider.notifier);

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
    await _controller.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final MenuManagementState state = ref.watch(menuManagementControllerProvider);
    final bool isRefreshInProgress = state.isLoading || !(_refreshCompleter?.isCompleted ?? true);

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

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
            onTap: () => context.go(OrderHistoryPage.routeName),
          ),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go(InventoryManagementPage.routeName),
          ),
          const YataNavItem(label: "メニュー管理", icon: Icons.restaurant_menu_outlined, isActive: true),
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go(SalesAnalyticsPage.routeName),
          ),
        ],
        trailing: <Widget>[
          Semantics(
            button: true,
            enabled: !isRefreshInProgress,
            label: "メニュー情報を再取得",
            child: YataIconButton(
              icon: Icons.refresh_outlined,
              tooltip: "メニュー情報を再取得",
              onPressed: isRefreshInProgress ? null : _handleRefreshAll,
            ),
          ),
          YataIconButton(
            icon: Icons.settings,
            tooltip: "設定",
            onPressed: () => context.go(SettingsPage.routeName),
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
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: YataSpacingTokens.md),
              _ErrorBanner(message: state.errorMessage!, onDismissed: _controller.refreshAll),
            ],
            const SizedBox(height: YataSpacingTokens.lg),
            MenuManagementHeader(
              state: state,
              searchController: _searchController,
              onSearchChanged: _controller.updateSearchQuery,
              onFilterChanged: _controller.updateAvailabilityFilter,
              onCreateMenu: _handleCreateMenu,
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _openDetailDialogIfNeeded(context, state);

                final Widget categoryPanel = SizedBox(
                  width: 260,
                  child: MenuCategoryPanel(
                    categories: state.categories,
                    selectedCategoryId: state.selectedCategoryId,
                    onCategorySelected: _controller.selectCategory,
                    onAddCategory: _handleAddCategory,
                    onEditCategory: _handleEditCategory,
                    onDeleteCategory: _handleDeleteCategory,
                  ),
                );

                final Widget table = MenuItemTable(
                  items: state.filteredMenuItems,
                  onRowTap: (String id) => _controller.openDetail(id),
                  isBusy: state.isSubmitting,
                  busyMenuIds: state.pendingAvailabilityMenuIds,
                  availabilityErrors: state.availabilityErrorMessages,
                  onToggleAvailability: _controller.toggleMenuAvailability,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    categoryPanel,
                    const SizedBox(width: YataSpacingTokens.lg),
                    Expanded(child: table),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleRefreshAll() {
    final MenuManagementState current = ref.read(menuManagementControllerProvider);
    final bool isBusy = current.isLoading || !(_refreshCompleter?.isCompleted ?? true);
    if (isBusy) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    setState(() {
      _refreshCompleter = completer;
    });

    unawaited(
      _controller.refreshAll().whenComplete(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
        if (!mounted) {
          return;
        }
        if (identical(_refreshCompleter, completer)) {
          setState(() {
            _refreshCompleter = null;
          });
        }
      }),
    );
  }

  void _openDetailDialogIfNeeded(BuildContext context, MenuManagementState state) {
    if (state.detail == null) {
      if (_detailDialogOpen) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _detailDialogOpen = false;
      }
      return;
    }

    if (_detailDialogOpen) {
      return;
    }

    _detailDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _detailDialogOpen = false;
        return;
      }
      final MenuDetailViewData? latestDetail = ref.read(menuManagementControllerProvider).detail;
      if (latestDetail == null) {
        _detailDialogOpen = false;
        return;
      }
      _presentDetailDialog(context);
    });
  }

  void _presentDetailDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MediaQueryData mediaQuery = MediaQuery.of(dialogContext);
        final double maxWidth = math.min(mediaQuery.size.width * 0.9, 600);
        final double minWidth = math.min(320, maxWidth);
        final double maxHeight = mediaQuery.size.height * 0.9;
        final EdgeInsets inset = EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width < 768 ? 16 : 24,
          vertical: 24,
        );

        return Dialog(
          insetPadding: inset,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: minWidth,
              maxHeight: maxHeight,
            ),
            child: _MenuDetailDialogContent(
              onClose: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              onEditMenu: (MenuItemViewData menu) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _handleEditMenu(menu);
                  }
                });
              },
              onEditRecipes: (String menuId) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _handleOpenRecipeEditor(menuId);
                  }
                });
              },
              onDeleteMenu: (MenuItemViewData menu) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _handleDeleteMenu(menu);
                  }
                });
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) {
        return;
      }
      _detailDialogOpen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.closeDetail();
        }
      });
    });
  }

  Future<void> _handleAddCategory() async {
    final String? name = await _showCategoryNameDialog(title: "カテゴリを追加");
    if (name == null) {
      return;
    }
    await _controller.createCategory(name);
  }

  Future<void> _handleEditCategory(MenuCategoryViewData category) async {
    if (category.isAll || category.id == null) {
      return;
    }
    final String? name = await _showCategoryNameDialog(
      title: "カテゴリ名を編集",
      initialValue: category.name,
    );
    if (name == null) {
      return;
    }
    await _controller.renameCategory(category.id!, name);
  }

  Future<void> _handleDeleteCategory(MenuCategoryViewData category) async {
    if (category.isAll || category.id == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("カテゴリを削除"),
        content: Text("「${category.name}」カテゴリを削除しますか？\n所属するメニューは未分類になります。"),
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
    if (confirmed ?? false) {
      await _controller.deleteCategory(category.id!);
    }
  }

  Future<void> _handleCreateMenu() async {
    final MenuManagementState current = ref.read(menuManagementControllerProvider);
    final List<MenuCategoryViewData> categories = current.categories
        .where((MenuCategoryViewData c) => !c.isAll)
        .toList(growable: false);
    if (categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("メニューを追加する前にカテゴリを作成してください")));
      return;
    }
    final MenuFormData? result = await _showMenuFormDialog(categories: categories);
    if (result == null) {
      return;
    }
    await _controller.createMenu(result);
  }

  Future<void> _handleEditMenu(MenuItemViewData item) async {
    final MenuManagementState current = ref.read(menuManagementControllerProvider);
    final List<MenuCategoryViewData> categories = current.categories
        .where((MenuCategoryViewData c) => !c.isAll)
        .toList(growable: false);
    if (categories.isEmpty) {
      return;
    }
    final MenuFormData? result = await _showMenuFormDialog(categories: categories, initial: item);
    if (result == null) {
      return;
    }
    await _controller.updateMenu(item.id, result);
  }

  Future<void> _handleDeleteMenu(MenuItemViewData item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("メニューを削除"),
        content: Text("「${item.name}」を削除しますか？\nこの操作は取り消せません。"),
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

    await _controller.deleteMenu(item.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} を削除しました")));
  }

  Future<void> _handleOpenRecipeEditor(String menuItemId) async {
    await _controller.openDetail(menuItemId);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _RecipeEditorDialog(menuItemId: menuItemId),
    );
  }

  Future<String?> _showCategoryNameDialog({required String title, String? initialValue}) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext _) => _CategoryNameDialog(
        title: title,
        initialValue: initialValue,
      ),
    );
  }

  Future<MenuFormData?> _showMenuFormDialog({
    required List<MenuCategoryViewData> categories,
    MenuItemViewData? initial,
  }) async {
    final TextEditingController nameController = TextEditingController(text: initial?.name ?? "");
    final TextEditingController priceController = TextEditingController(
      text: initial != null ? initial.price.toString() : "",
    );
    final TextEditingController descriptionController = TextEditingController(
      text: initial?.description ?? "",
    );
    final TextEditingController imageController = TextEditingController(
      text: initial?.imageUrl ?? "",
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String selectedCategoryId = initial?.categoryId ?? categories.first.id!;
    bool isAvailable = initial?.isAvailable ?? true;

    final MenuFormData? result = await showDialog<MenuFormData>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setState) => AlertDialog(
          title: Text(initial == null ? "メニューを追加" : "メニューを編集"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "メニュー名"),
                    autofocus: true,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return "名称を入力してください";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: YataSpacingTokens.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(labelText: "カテゴリ"),
                    items: categories
                        .map(
                          (MenuCategoryViewData category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => selectedCategoryId = value);
                      }
                    },
                  ),
                  const SizedBox(height: YataSpacingTokens.sm),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: "価格"),
                    keyboardType: TextInputType.number,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return "価格を入力してください";
                      }
                      final int? price = int.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return "0以上の数値を入力してください";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: YataSpacingTokens.sm),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "説明", hintText: "任意"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: YataSpacingTokens.sm),
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: "画像URL", hintText: "任意"),
                  ),
                  const SizedBox(height: YataSpacingTokens.sm),
                  SwitchListTile(
                    value: isAvailable,
                    onChanged: (bool value) => setState(() => isAvailable = value),
                    title: const Text("販売可能にする"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("キャンセル"),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final int price = int.parse(priceController.text.trim());
                Navigator.of(dialogContext).pop(
                  MenuFormData(
                    name: nameController.text.trim(),
                    categoryId: selectedCategoryId,
                    price: price,
                    isAvailable: isAvailable,
                    description: descriptionController.text,
                    imageUrl: imageController.text,
                  ),
                );
              },
              child: const Text("保存"),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    return result;
  }
}

/// カテゴリ名の入力ダイアログ。
class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, this.initialValue});

  final String title;
  final String? initialValue;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: "カテゴリ名"),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return "名称を入力してください";
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("キャンセル"),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop(_controller.text.trim());
              }
            },
            child: const Text("保存"),
          ),
        ],
      );
}

class _RecipeEditorDialog extends ConsumerStatefulWidget {
  const _RecipeEditorDialog({required this.menuItemId});

  final String menuItemId;

  @override
  ConsumerState<_RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends ConsumerState<_RecipeEditorDialog> {
  late Future<List<MaterialOption>> _optionsFuture;
  String? _selectedMaterialId;
  bool _isOptional = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  MenuManagementController get _controller => ref.read(menuManagementControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _optionsFuture = _controller.loadMaterialOptions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MenuManagementState state = ref.watch(menuManagementControllerProvider);
    final MenuDetailViewData? detail = state.selectedMenuId == widget.menuItemId
        ? state.detail
        : null;
    final List<MenuRecipeDetail> recipes = detail?.recipes ?? <MenuRecipeDetail>[];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(YataSpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text("レシピ編集", style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (detail == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: YataSpacingTokens.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final MenuRecipeDetail recipe = recipes[index];
                      return Card(
                        color: YataColorTokens.neutral100,
                        child: Padding(
                          padding: const EdgeInsets.all(YataSpacingTokens.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      recipe.materialName,
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: YataColorTokens.danger,
                                    ),
                                    tooltip: "削除",
                                    onPressed: state.isSubmitting
                                        ? null
                                        : () async {
                                            if (recipe.recipeId != null) {
                                              await _controller.deleteMenuRecipe(
                                                recipe.recipeId!,
                                                widget.menuItemId,
                                              );
                                            }
                                          },
                                  ),
                                ],
                              ),
                              const SizedBox(height: YataSpacingTokens.xs),
                              Text("必要量: ${recipe.requiredAmount}"),
                              Text(recipe.isOptional ? "任意材料" : "必須材料"),
                              if (recipe.notes != null && recipe.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                                  child: Text(
                                    recipe.notes!,
                                    style: const TextStyle(color: YataColorTokens.textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              FutureBuilder<List<MaterialOption>>(
                future: _optionsFuture,
                builder: (BuildContext context, AsyncSnapshot<List<MaterialOption>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: YataSpacingTokens.md),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final List<MaterialOption> options = snapshot.data ?? <MaterialOption>[];
                  if (options.isEmpty) {
                    return const Text("材料が登録されていません");
                  }
                  _selectedMaterialId ??= options.first.id;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text("レシピを追加", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: YataSpacingTokens.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMaterialId,
                        items: options
                            .map(
                              (MaterialOption option) => DropdownMenuItem<String>(
                                value: option.id,
                                child: Text(option.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) => setState(() => _selectedMaterialId = value),
                        decoration: const InputDecoration(labelText: "材料"),
                      ),
                      const SizedBox(height: YataSpacingTokens.sm),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: "必要量"),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SwitchListTile(
                        value: _isOptional,
                        title: const Text("任意材料"),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool value) => setState(() => _isOptional = value),
                      ),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: "備考", hintText: "任意"),
                      ),
                      const SizedBox(height: YataSpacingTokens.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  final String? materialId = _selectedMaterialId;
                                  final double? amount = double.tryParse(
                                    _amountController.text.trim(),
                                  );
                                  if (materialId == null || amount == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("材料と必要量を入力してください")),
                                    );
                                    return;
                                  }
                                  final MenuRecipeFormData payload = MenuRecipeFormData(
                                    menuItemId: widget.menuItemId,
                                    materialId: materialId,
                                    requiredAmount: amount,
                                    isOptional: _isOptional,
                                    notes: _notesController.text,
                                  );
                                  await _controller.upsertMenuRecipe(payload);
                                  setState(() {
                                    _amountController.clear();
                                    _notesController.clear();
                                    _isOptional = false;
                                  });
                                },
                          icon: const Icon(Icons.add),
                          label: const Text("追加"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismissed});

  final String message;
  final FutureOr<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(YataSpacingTokens.md),
    decoration: BoxDecoration(
      color: YataColorTokens.dangerSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: YataColorTokens.danger),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.error_outline, color: YataColorTokens.danger),
        const SizedBox(width: YataSpacingTokens.md),
        Expanded(child: Text(message)),
        TextButton.icon(
          onPressed: onDismissed,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text("再試行"),
        ),
      ],
    ),
  );
}

class _MenuDetailDialogContent extends ConsumerWidget {
  const _MenuDetailDialogContent({
    required this.onClose,
    required this.onEditMenu,
    required this.onEditRecipes,
    required this.onDeleteMenu,
  });

  final VoidCallback onClose;
  final ValueChanged<MenuItemViewData> onEditMenu;
  final ValueChanged<String> onEditRecipes;
  final ValueChanged<MenuItemViewData> onDeleteMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MenuManagementState state = ref.watch(menuManagementControllerProvider);
    final MenuDetailViewData? detail = state.detail;
    final bool isDetailBusy =
        state.isSubmitting ||
        (detail != null && state.pendingAvailabilityMenuIds.contains(detail.menu.id));

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: "メニュー詳細モーダル",
        child: Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(YataSpacingTokens.lg),
            child: MenuDetailPanel(
              detail: detail,
              isBusy: isDetailBusy,
              onClose: onClose,
              onEditMenu: detail == null ? null : () => onEditMenu(detail.menu),
              onEditRecipes: detail == null ? null : () => onEditRecipes(detail.menu.id),
              onDeleteMenu: detail == null ? null : () => onDeleteMenu(detail.menu),
              enableInternalScroll: false,
            ),
          ),
        ),
      ),
    );
  }
}
