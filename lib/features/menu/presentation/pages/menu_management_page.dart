import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/constants/enums.dart";
import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
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
  bool _isRecipeEditorOpen = false;
  String? _pendingRecipeEditorMenuId;
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

    if (_isRecipeEditorOpen) {
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
                if (mounted) {
                  setState(() {
                    _pendingRecipeEditorMenuId = menuId;
                    _isRecipeEditorOpen = true;
                  });
                }
                Navigator.of(dialogContext, rootNavigator: true).pop();
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
        _pendingRecipeEditorMenuId = null;
        _isRecipeEditorOpen = false;
        return;
      }
      _detailDialogOpen = false;
      final String? pendingMenuId = _pendingRecipeEditorMenuId;
      _pendingRecipeEditorMenuId = null;
      if (pendingMenuId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _handleOpenRecipeEditor(pendingMenuId);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.closeDetail();
          }
        });
      }
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
    final List<MaterialOption> materialOptions = await _controller.loadMaterialOptions();
    final MenuFormData? result = await _showMenuFormDialog(
      categories: categories,
      materialOptions: materialOptions,
    );
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
    final List<MaterialOption> materialOptions = await _controller.loadMaterialOptions();
    final List<MenuRecipeDetail> initialRecipes = await _controller.loadRecipesForMenu(item.id);
    final MenuFormData? result = await _showMenuFormDialog(
      categories: categories,
      materialOptions: materialOptions,
      initial: item,
      initialRecipes: initialRecipes,
    );
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
    final MenuManagementState current = ref.read(menuManagementControllerProvider);
    if (current.detail == null || current.selectedMenuId != menuItemId) {
      await _controller.openDetail(menuItemId);
    }
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _RecipeEditorDialog(menuItemId: menuItemId),
    );

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.closeDetail();
      if (_isRecipeEditorOpen) {
        setState(() {
          _isRecipeEditorOpen = false;
        });
      }
    });
  }

  Future<String?> _showCategoryNameDialog({required String title, String? initialValue}) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext _) => _CategoryNameDialog(title: title, initialValue: initialValue),
    );
  }

  Future<MenuFormData?> _showMenuFormDialog({
    required List<MenuCategoryViewData> categories,
    required List<MaterialOption> materialOptions,
    MenuItemViewData? initial,
    List<MenuRecipeDetail> initialRecipes = const <MenuRecipeDetail>[],
  }) {
    return showDialog<MenuFormData>(
      context: context,
      builder: (BuildContext _) => _MenuFormDialog(
        categories: categories,
        materialOptions: materialOptions,
        initial: initial,
        initialRecipes: initialRecipes,
      ),
    );
  }
}

class _MenuFormDialog extends StatefulWidget {
  const _MenuFormDialog({
    required this.categories,
    required this.materialOptions,
    this.initial,
    this.initialRecipes = const <MenuRecipeDetail>[],
  });

  final List<MenuCategoryViewData> categories;
  final List<MaterialOption> materialOptions;
  final MenuItemViewData? initial;
  final List<MenuRecipeDetail> initialRecipes;

  @override
  State<_MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<_MenuFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final List<MenuCategoryViewData> _availableCategories;
  late final List<MaterialOption> _materialOptions;
  late String _selectedCategoryId;
  late bool _isAvailable;
  final List<_RecipeFormFieldSet> _recipeForms = <_RecipeFormFieldSet>[];
  final Set<String> _removedRecipeIds = <String>{};
  String? _recipeValidationMessage;

  @override
  void initState() {
    super.initState();
    _availableCategories = widget.categories
        .where((MenuCategoryViewData category) => category.id != null)
        .toList();

    assert(_availableCategories.isNotEmpty, "カテゴリが存在しない状態でメニュー追加ダイアログは開けません");

    final String? initialCategoryId = widget.initial?.categoryId;
    _selectedCategoryId =
        initialCategoryId != null &&
            _availableCategories.any(
              (MenuCategoryViewData category) => category.id == initialCategoryId,
            )
        ? initialCategoryId
        : _availableCategories.first.id!;

    _isAvailable = widget.initial?.isAvailable ?? true;
    _nameController = TextEditingController(text: widget.initial?.name ?? "");
    _priceController = TextEditingController(
      text: widget.initial != null ? widget.initial!.price.toString() : "",
    );
    _descriptionController = TextEditingController(text: widget.initial?.description ?? "");
    _materialOptions = List<MaterialOption>.from(widget.materialOptions);

    for (final MenuRecipeDetail detail in widget.initialRecipes) {
      if (_findMaterialOption(detail.materialId) == null) {
        _materialOptions.add(
          MaterialOption(
            id: detail.materialId,
            name: "${detail.materialName} (未登録)",
            unitType: detail.materialUnitType ?? UnitType.piece,
            currentStock: detail.materialCurrentStock,
          ),
        );
      }
      _recipeForms.add(_RecipeFormFieldSet.fromDetail(detail));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    for (final _RecipeFormFieldSet form in _recipeForms) {
      form.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double maxWidth = math.min(mediaQuery.size.width * 0.9, 640);
    final double minWidth = math.min(mediaQuery.size.width * 0.9, 560);
    final double maxHeight = mediaQuery.size.height * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mediaQuery.size.width < 768 ? 16 : 32,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: minWidth, maxHeight: maxHeight),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: YataSpacingTokens.lg,
                  vertical: YataSpacingTokens.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.initial == null ? "メニューを追加" : "メニューを編集",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: "閉じる",
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(YataSpacingTokens.lg),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool useColumns = constraints.maxWidth >= 520;
                      if (useColumns) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: _buildPrimaryFormFields()),
                            const SizedBox(width: YataSpacingTokens.lg),
                            Expanded(child: _buildSecondaryFormFields()),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildPrimaryFormFields(),
                          const SizedBox(height: YataSpacingTokens.lg),
                          _buildSecondaryFormFields(),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(YataSpacingTokens.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("キャンセル"),
                    ),
                    const SizedBox(width: YataSpacingTokens.sm),
                    FilledButton(onPressed: _handleSubmit, child: const Text("保存")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "メニュー名"),
          autofocus: true,
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return "名称を入力してください";
            }
            return null;
          },
        ),
        const SizedBox(height: YataSpacingTokens.md),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: const InputDecoration(labelText: "カテゴリ"),
          items: _availableCategories
              .map(
                (MenuCategoryViewData category) =>
                    DropdownMenuItem<String>(value: category.id, child: Text(category.name)),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedCategoryId = value);
          },
        ),
        const SizedBox(height: YataSpacingTokens.md),
        TextFormField(
          controller: _priceController,
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
        const SizedBox(height: YataSpacingTokens.md),
        SwitchListTile(
          value: _isAvailable,
          onChanged: (bool value) => setState(() => _isAvailable = value),
          title: const Text("販売可能にする"),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSecondaryFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: "説明", hintText: "任意"),
          maxLines: 4,
        ),
        const SizedBox(height: YataSpacingTokens.md),
        _buildRecipeSection(),
      ],
    );
  }

  Widget _buildRecipeSection() {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text("レシピ設定", style: textTheme.titleSmall),
        const SizedBox(height: YataSpacingTokens.sm),
        if (_recipeValidationMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: YataSpacingTokens.xs),
            child: Text(
              _recipeValidationMessage!,
              style: textTheme.bodySmall?.copyWith(color: YataColorTokens.danger),
            ),
          ),
        if (_recipeForms.isEmpty)
          Container(
            padding: const EdgeInsets.all(YataSpacingTokens.md),
            decoration: BoxDecoration(
              color: YataColorTokens.neutral100,
              borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
            ),
            child: Text(
              _materialOptions.isEmpty ? "材料マスタが未登録のため、レシピを追加できません。" : "レシピに材料が追加されていません。",
              style: textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
            ),
          )
        else
          Column(
            children: <Widget>[
              for (int index = 0; index < _recipeForms.length; index++) ...<Widget>[
                _buildRecipeCard(index),
                if (index != _recipeForms.length - 1) const SizedBox(height: YataSpacingTokens.sm),
              ],
            ],
          ),
        const SizedBox(height: YataSpacingTokens.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _materialOptions.isEmpty ? null : _addRecipeEntry,
            icon: const Icon(Icons.add),
            label: const Text("材料を追加"),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(int index) {
    final _RecipeFormFieldSet form = _recipeForms[index];
    final MaterialOption? option = _findMaterialOption(form.materialId);
    final String? unitSymbol = option?.unitType.symbol;

    return Card(
      margin: EdgeInsets.zero,
      color: YataColorTokens.neutral0,
      child: Padding(
        padding: const EdgeInsets.all(YataSpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    option?.name ?? "材料を選択",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: YataColorTokens.danger,
                  tooltip: "削除",
                  onPressed: () => _removeRecipeAt(index),
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            DropdownButtonFormField<String>(
              value: form.materialId,
              decoration: const InputDecoration(labelText: "材料"),
              isExpanded: true,
              items: _materialOptions
                  .map(
                    (MaterialOption material) => DropdownMenuItem<String>(
                      value: material.id,
                      child: Text(material.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                setState(() {
                  form.materialId = value;
                  _recipeValidationMessage = null;
                });
              },
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return "材料を選択してください";
                }
                return null;
              },
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            TextFormField(
              controller: form.amountController,
              decoration: InputDecoration(labelText: "必要量", suffixText: unitSymbol),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return "必要量を入力してください";
                }
                final double? parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return "数値を入力してください";
                }
                if (parsed <= 0) {
                  return "0より大きい数値を入力してください";
                }
                return null;
              },
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            Row(
              children: <Widget>[
                Switch.adaptive(
                  value: form.isOptional,
                  onChanged: (bool value) => setState(() => form.isOptional = value),
                ),
                const SizedBox(width: YataSpacingTokens.xs),
                const Expanded(child: Text("任意材料")),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            TextFormField(
              controller: form.notesController,
              decoration: const InputDecoration(labelText: "備考", hintText: "任意"),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _addRecipeEntry() {
    setState(() {
      _recipeForms.add(_RecipeFormFieldSet());
      _recipeValidationMessage = null;
    });
  }

  void _removeRecipeAt(int index) {
    if (index < 0 || index >= _recipeForms.length) {
      return;
    }
    final _RecipeFormFieldSet removed = _recipeForms.removeAt(index);
    if (removed.existingRecipeId != null) {
      _removedRecipeIds.add(removed.existingRecipeId!);
    }
    removed.dispose();
    setState(() {
      _recipeValidationMessage = null;
    });
  }

  void _handleSubmit() {
    final FormState? formState = _formKey.currentState;
    if (formState == null) {
      return;
    }
    if (!formState.validate()) {
      return;
    }

    final Set<String> duplicateMaterials = <String>{};
    final Set<String> seenMaterials = <String>{};
    final Set<String> removedByChange = <String>{};

    for (final _RecipeFormFieldSet form in _recipeForms) {
      final String? materialId = form.materialId;
      if (materialId == null) {
        continue;
      }
      if (!seenMaterials.add(materialId)) {
        duplicateMaterials.add(_materialNameFor(materialId));
      }
      if (form.existingRecipeId != null &&
          form.originalMaterialId != null &&
          form.originalMaterialId != materialId) {
        removedByChange.add(form.existingRecipeId!);
      }
    }

    if (duplicateMaterials.isNotEmpty) {
      setState(() {
        _recipeValidationMessage = "同じ材料が複数選択されています: ${duplicateMaterials.join('、 ')}";
      });
      return;
    }

    _removedRecipeIds.addAll(removedByChange);
    setState(() {
      _recipeValidationMessage = null;
    });

    final List<MenuRecipeDraft> drafts = <MenuRecipeDraft>[];
    for (final _RecipeFormFieldSet form in _recipeForms) {
      final String? materialId = form.materialId;
      if (materialId == null) {
        continue;
      }
      final MaterialOption? option = _findMaterialOption(materialId);
      final double amount = double.parse(form.amountController.text.trim());
      drafts.add(
        MenuRecipeDraft(
          recipeId: form.existingRecipeId,
          materialId: materialId,
          materialName: option?.name ?? _materialNameFor(materialId),
          unitType: option?.unitType,
          requiredAmount: amount,
          isOptional: form.isOptional,
          notes: _normalizedTextOrNull(form.notesController.text),
        ),
      );
    }

    Navigator.of(context).pop(
      MenuFormData(
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        price: int.parse(_priceController.text.trim()),
        isAvailable: _isAvailable,
        description: _descriptionController.text,
        recipes: drafts,
        removedRecipeIds: _removedRecipeIds.toList(growable: false),
      ),
    );
  }

  MaterialOption? _findMaterialOption(String? materialId) {
    if (materialId == null) {
      return null;
    }
    for (final MaterialOption option in _materialOptions) {
      if (option.id == materialId) {
        return option;
      }
    }
    return null;
  }

  String _materialNameFor(String materialId) {
    final MaterialOption? option = _findMaterialOption(materialId);
    return option?.name ?? "材料ID: $materialId";
  }

  String? _normalizedTextOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _RecipeFormFieldSet {
  _RecipeFormFieldSet()
    : existingRecipeId = null,
      originalMaterialId = null,
      materialId = null,
      isOptional = false,
      amountController = TextEditingController(),
      notesController = TextEditingController();

  _RecipeFormFieldSet.fromDetail(MenuRecipeDetail detail)
    : existingRecipeId = detail.recipeId,
      originalMaterialId = detail.materialId,
      materialId = detail.materialId,
      isOptional = detail.isOptional,
      amountController = TextEditingController(text: detail.requiredAmount.toString()),
      notesController = TextEditingController(text: detail.notes ?? "");

  final String? existingRecipeId;
  final String? originalMaterialId;
  String? materialId;
  bool isOptional;
  final TextEditingController amountController;
  final TextEditingController notesController;

  void dispose() {
    amountController.dispose();
    notesController.dispose();
  }
}

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
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
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
