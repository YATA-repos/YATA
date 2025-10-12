import "dart:async";
import "dart:math" as math;

import "package:flutter/foundation.dart";
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
    final List<MenuItemViewData> attentionItems = state.menuItems
        .where((MenuItemViewData item) => item.needsAttention)
        .toList(growable: false);

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

                final bool isWideLayout = constraints.maxWidth >= 1100;

                final Widget sidebar = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MenuCategoryPanel(
                      categories: state.categories,
                      selectedCategoryId: state.selectedCategoryId,
                      onCategorySelected: _controller.selectCategory,
                      onAddCategory: _handleAddCategory,
                      onEditCategory: _handleEditCategory,
                      onDeleteCategory: _handleDeleteCategory,
                    ),
                  ],
                );

                final Widget tableSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _MenuAttentionSection(
                      items: attentionItems,
                      onShowAll: () =>
                          _controller.updateAvailabilityFilter(MenuAvailabilityFilter.attention),
                      onOpenDetail: (String id) => _controller.openDetail(id),
                    ),
                    const SizedBox(height: YataSpacingTokens.lg),
                    MenuItemTable(
                      items: state.filteredMenuItems,
                      onRowTap: (String id) => _controller.openDetail(id),
                      isBusy: state.isSubmitting,
                      busyMenuIds: state.pendingAvailabilityMenuIds,
                      availabilityErrors: state.availabilityErrorMessages,
                      onToggleAvailability: _controller.toggleMenuAvailability,
                    ),
                  ],
                );

                if (isWideLayout) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 260, child: sidebar),
                      const SizedBox(width: YataSpacingTokens.lg),
                      Expanded(child: tableSection),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    sidebar,
                    const SizedBox(height: YataSpacingTokens.lg),
                    tableSection,
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

  Future<String?> _showCategoryNameDialog({required String title, String? initialValue}) =>
      showDialog<String>(
        context: context,
        builder: (BuildContext _) => _CategoryNameDialog(title: title, initialValue: initialValue),
      );

  Future<MenuFormData?> _showMenuFormDialog({
    required List<MenuCategoryViewData> categories,
    required List<MaterialOption> materialOptions,
    MenuItemViewData? initial,
    List<MenuRecipeDetail> initialRecipes = const <MenuRecipeDetail>[],
  }) => showDialog<MenuFormData>(
    context: context,
    builder: (BuildContext _) => _MenuFormDialog(
      categories: categories,
      materialOptions: materialOptions,
      initial: initial,
      initialRecipes: initialRecipes,
    ),
  );
}

class _MenuAttentionSection extends StatelessWidget {
  const _MenuAttentionSection({
    required this.items,
    required this.onOpenDetail,
    required this.onShowAll,
  });

  final List<MenuItemViewData> items;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (items.isEmpty) {
      return YataSectionCard(
        title: "要確認メニュー",
        subtitle: "対応が必要なメニューはありません",
        child: Text(
          "在庫・レシピの状態は適切です。",
          style: theme.textTheme.bodyMedium?.copyWith(color: YataColorTokens.textSecondary),
        ),
      );
    }

    final List<MenuItemViewData> highlights = items.take(3).toList(growable: false);

    return YataSectionCard(
      title: "要確認メニュー",
      subtitle: "優先して確認したいメニューをまとめました",
      actions: <Widget>[TextButton(onPressed: onShowAll, child: const Text("一覧で表示"))],
      child: Column(
        children: <Widget>[
          for (int index = 0; index < highlights.length; index++) ...<Widget>[
            _AttentionMenuTile(item: highlights[index], onOpenDetail: onOpenDetail),
            if (index != highlights.length - 1) const SizedBox(height: YataSpacingTokens.sm),
          ],
        ],
      ),
    );
  }
}

class _AttentionMenuTile extends StatelessWidget {
  const _AttentionMenuTile({required this.item, required this.onOpenDetail});

  final MenuItemViewData item;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> badges = <Widget>[
      if (!item.isStockAvailable || item.missingMaterials.isNotEmpty)
        const YataStatusBadge(label: "在庫不足", type: YataStatusBadgeType.warning),
      if (!item.hasRecipe)
        const YataStatusBadge(label: "レシピ未登録", type: YataStatusBadgeType.warning),
    ];

    final List<Widget> supplemental = <Widget>[
      if (item.missingMaterials.isNotEmpty)
        YataTag(
          label: item.missingMaterials.length == 1
              ? item.missingMaterials.first
              : "${item.missingMaterials.first} ほか${item.missingMaterials.length - 1}件",
          icon: Icons.inventory_2_outlined,
          backgroundColor: YataColorTokens.warningSoft,
          foregroundColor: YataColorTokens.warning,
        ),
      if (item.estimatedServings != null)
        YataTag(label: "提供可能目安 ${item.estimatedServings}", icon: Icons.timelapse_outlined),
    ];

    return Material(
      color: YataColorTokens.neutral50,
      borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
      child: InkWell(
        onTap: () => onOpenDetail(item.id),
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
                          item.categoryName,
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
              if (item.description != null && item.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.sm),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: YataColorTokens.textSecondary,
                  ),
                ),
              ],
              if (supplemental.isNotEmpty) ...<Widget>[
                const SizedBox(height: YataSpacingTokens.sm),
                Wrap(
                  spacing: YataSpacingTokens.sm,
                  runSpacing: YataSpacingTokens.xs,
                  children: supplemental,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element

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
        child: _MenuFormEditor(
          title: widget.initial == null ? "メニューを追加" : "メニューを編集",
          categories: widget.categories,
          materialOptions: widget.materialOptions,
          initial: widget.initial,
          initialRecipes: widget.initialRecipes,
          submitLabel: widget.initial == null ? "追加" : "保存",
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: (MenuFormData data) => Navigator.of(context).pop(data),
          headerActions: <Widget>[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "閉じる",
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuFormEditor extends StatefulWidget {
  const _MenuFormEditor({
    required this.title,
    required this.categories,
    required this.materialOptions,
    required this.onSubmit,
    required this.onCancel,
    this.initial,
    this.initialRecipes = const <MenuRecipeDetail>[],
    this.headerActions = const <Widget>[],
    this.footerLeading,
    this.submitLabel = "保存",
    this.cancelLabel = "キャンセル",
    this.isBusy = false,
    this.errorMessage,
  });

  final String title;
  final List<MenuCategoryViewData> categories;
  final List<MaterialOption> materialOptions;
  final MenuItemViewData? initial;
  final List<MenuRecipeDetail> initialRecipes;
  final ValueChanged<MenuFormData> onSubmit;
  final VoidCallback onCancel;
  final List<Widget> headerActions;
  final Widget? footerLeading;
  final String submitLabel;
  final String cancelLabel;
  final bool isBusy;
  final String? errorMessage;

  @override
  State<_MenuFormEditor> createState() => _MenuFormEditorState();
}

class _MenuFormEditorState extends State<_MenuFormEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final ScrollController _scrollController;
  late List<MenuCategoryViewData> _availableCategories;
  late List<MaterialOption> _materialOptions;
  late String _selectedCategoryId;
  late bool _isAvailable;
  final List<_RecipeFormFieldSet> _recipeForms = <_RecipeFormFieldSet>[];
  final Set<String> _removedRecipeIds = <String>{};
  String? _recipeValidationMessage;

  bool get _isBusy => widget.isBusy;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeForm();
  }

  @override
  void didUpdateWidget(covariant _MenuFormEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.categories, widget.categories)) {
      _updateCategories(widget.categories);
    }
    if (!listEquals(oldWidget.materialOptions, widget.materialOptions)) {
      _materialOptions = List<MaterialOption>.from(widget.materialOptions);
      _ensureMaterialOptionsForRecipes();
    }
    if (oldWidget.initial != widget.initial && widget.initial != null) {
      _applyInitialMenu(widget.initial!);
    }
    if (!listEquals(oldWidget.initialRecipes, widget.initialRecipes)) {
      _resetRecipeForms(widget.initialRecipes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    for (final _RecipeFormFieldSet form in _recipeForms) {
      form.dispose();
    }
    super.dispose();
  }

  void _initializeForm() {
    _availableCategories = widget.categories
        .where((MenuCategoryViewData category) => category.id != null)
        .toList();

    assert(_availableCategories.isNotEmpty, "カテゴリが存在しない状態でメニューフォームは生成できません");

    _materialOptions = List<MaterialOption>.from(widget.materialOptions);
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _applyInitialMenu(widget.initial);
    _resetRecipeForms(widget.initialRecipes);
  }

  void _applyInitialMenu(MenuItemViewData? menu) {
    final String? initialCategoryId = menu?.categoryId;
    _selectedCategoryId =
        initialCategoryId != null &&
            _availableCategories.any(
              (MenuCategoryViewData category) => category.id == initialCategoryId,
            )
        ? initialCategoryId
        : _availableCategories.first.id!;

    _isAvailable = menu?.isAvailable ?? true;
    _nameController.text = menu?.name ?? "";
    _priceController.text = menu != null ? menu.price.toString() : "";
    _descriptionController.text = menu?.description ?? "";
  }

  void _resetRecipeForms(List<MenuRecipeDetail> recipes) {
    _removedRecipeIds.clear();
    for (final _RecipeFormFieldSet form in _recipeForms) {
      form.dispose();
    }
    _recipeForms
      ..clear()
      ..addAll(recipes.map<_RecipeFormFieldSet>(_RecipeFormFieldSet.fromDetail));
    _ensureMaterialOptionsForRecipes();
  }

  void _ensureMaterialOptionsForRecipes() {
    for (final _RecipeFormFieldSet form in _recipeForms) {
      final String? materialId = form.materialId;
      if (materialId == null) {
        continue;
      }
      if (_findMaterialOption(materialId) == null) {
        _materialOptions.add(
          MaterialOption(
            id: materialId,
            name: "${form.materialName ?? '不明な材料'} (未登録)",
            unitType: form.materialUnitType ?? UnitType.piece,
            currentStock: form.materialCurrentStock,
          ),
        );
      }
    }
  }

  void _updateCategories(List<MenuCategoryViewData> categories) {
    final List<MenuCategoryViewData> filtered = categories
        .where((MenuCategoryViewData category) => category.id != null)
        .toList();
    if (filtered.isEmpty) {
      return;
    }
    setState(() {
      _availableCategories = filtered;
      if (_availableCategories.every(
        (MenuCategoryViewData category) => category.id != _selectedCategoryId,
      )) {
        _selectedCategoryId = _availableCategories.first.id!;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Form(
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
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
              ...widget.headerActions,
            ],
          ),
        ),
        const Divider(height: 1),
        if (_isBusy)
          const Padding(
            padding: EdgeInsets.only(top: YataSpacingTokens.xs),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: false,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(YataSpacingTokens.lg),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool useColumns = constraints.maxWidth >= 520;
                  final List<Widget> primary = <Widget>[_buildPrimaryFormFields()];
                  final List<Widget> secondary = <Widget>[_buildSecondaryFormFields()];

                  Widget bodyChild;
                  if (useColumns) {
                    bodyChild = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: Column(children: primary)),
                        const SizedBox(width: YataSpacingTokens.lg),
                        Expanded(child: Column(children: secondary)),
                      ],
                    );
                  } else {
                    bodyChild = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ...primary,
                        const SizedBox(height: YataSpacingTokens.lg),
                        ...secondary,
                      ],
                    );
                  }

                  if (widget.errorMessage != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: YataColorTokens.dangerSoft,
                            borderRadius: BorderRadius.circular(YataRadiusTokens.medium),
                            border: Border.all(color: YataColorTokens.danger),
                          ),
                          padding: const EdgeInsets.all(YataSpacingTokens.md),
                          margin: const EdgeInsets.only(bottom: YataSpacingTokens.md),
                          child: Text(
                            widget.errorMessage!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: YataColorTokens.danger),
                          ),
                        ),
                        bodyChild,
                      ],
                    );
                  }

                  return bodyChild;
                },
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(YataSpacingTokens.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (widget.footerLeading != null) ...<Widget>[
                widget.footerLeading!,
                const Spacer(),
              ] else
                const Spacer(),
              TextButton(
                onPressed: _isBusy ? null : widget.onCancel,
                child: Text(widget.cancelLabel),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              FilledButton(
                onPressed: _isBusy ? null : _handleSubmit,
                child: Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildPrimaryFormFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: "メニュー名"),
        autofocus: true,
        enabled: !_isBusy,
        validator: (String? value) {
          if (value == null || value.trim().isEmpty) {
            return "名称を入力してください";
          }
          return null;
        },
      ),
      const SizedBox(height: YataSpacingTokens.md),
      DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedCategoryId,
        decoration: const InputDecoration(labelText: "カテゴリ"),
        items: _availableCategories
            .map(
              (MenuCategoryViewData category) =>
                  DropdownMenuItem<String>(value: category.id, child: Text(category.name)),
            )
            .toList(growable: false),
        onChanged: _isBusy
            ? null
            : (String? value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedCategoryId = value);
              },
      ),
      const SizedBox(height: YataSpacingTokens.md),
      TextFormField(
        controller: _priceController,
        enabled: !_isBusy,
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
        onChanged: _isBusy ? null : (bool value) => setState(() => _isAvailable = value),
        title: const Text("販売可能にする"),
        contentPadding: EdgeInsets.zero,
      ),
    ],
  );

  Widget _buildSecondaryFormFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextFormField(
        controller: _descriptionController,
        enabled: !_isBusy,
        decoration: const InputDecoration(labelText: "説明", hintText: "任意"),
        maxLines: 4,
      ),
      const SizedBox(height: YataSpacingTokens.md),
      _buildRecipeSection(),
    ],
  );

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
            onPressed: _isBusy || _materialOptions.isEmpty ? null : _addRecipeEntry,
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
                  onPressed: _isBusy ? null : () => _removeRecipeAt(index),
                ),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
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
              onChanged: _isBusy
                  ? null
                  : (String? value) {
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
              enabled: !_isBusy,
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
                  onChanged: _isBusy
                      ? null
                      : (bool value) => setState(() => form.isOptional = value),
                ),
                const SizedBox(width: YataSpacingTokens.xs),
                const Expanded(child: Text("任意材料")),
              ],
            ),
            const SizedBox(height: YataSpacingTokens.xs),
            TextFormField(
              controller: form.notesController,
              enabled: !_isBusy,
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

    widget.onSubmit(
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
      materialName = null,
      materialUnitType = null,
      materialCurrentStock = null,
      isOptional = false,
      amountController = TextEditingController(),
      notesController = TextEditingController();

  _RecipeFormFieldSet.fromDetail(MenuRecipeDetail detail)
    : existingRecipeId = detail.recipeId,
      originalMaterialId = detail.materialId,
      materialId = detail.materialId,
      materialName = detail.materialName,
      materialUnitType = detail.materialUnitType,
      materialCurrentStock = detail.materialCurrentStock,
      isOptional = detail.isOptional,
      amountController = TextEditingController(text: detail.requiredAmount.toString()),
      notesController = TextEditingController(text: detail.notes ?? "");

  final String? existingRecipeId;
  final String? originalMaterialId;
  String? materialId;
  final String? materialName;
  final UnitType? materialUnitType;
  final double? materialCurrentStock;
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
                    separatorBuilder: (BuildContext context, int _) =>
                        const SizedBox(height: YataSpacingTokens.sm),
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

class _MenuDetailDialogContent extends ConsumerStatefulWidget {
  const _MenuDetailDialogContent({
    required this.onClose,
    required this.onDeleteMenu,
    this.onEditRecipes,
  });

  final VoidCallback onClose;
  final ValueChanged<MenuItemViewData> onDeleteMenu;
  final ValueChanged<String>? onEditRecipes;

  @override
  ConsumerState<_MenuDetailDialogContent> createState() => _MenuDetailDialogContentState();
}

class _MenuDetailDialogContentState extends ConsumerState<_MenuDetailDialogContent> {
  MenuDetailViewData? _detail;
  List<MenuCategoryViewData> _categories = const <MenuCategoryViewData>[];
  List<MaterialOption> _materialOptions = const <MaterialOption>[];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final MenuManagementState current = ref.read(menuManagementControllerProvider);
    final MenuDetailViewData? detail = current.detail;
    if (!mounted) {
      return;
    }

    if (detail == null) {
      setState(() {
        _loadErrorMessage = "メニュー詳細が取得できませんでした";
        _isLoading = false;
      });
      return;
    }

    final List<MenuCategoryViewData> categories = current.categories
        .where((MenuCategoryViewData category) => !category.isAll)
        .toList(growable: false);

    setState(() {
      _detail = detail;
      _categories = categories;
      _loadErrorMessage = categories.isEmpty ? "カテゴリが存在しません。先にカテゴリを作成してください" : null;
    });

    try {
      final List<MaterialOption> options = await ref
          .read(menuManagementControllerProvider.notifier)
          .loadMaterialOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _materialOptions = options;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadErrorMessage = "材料情報の取得に失敗しました。再試行してください";
      });
    }
  }

  Future<void> _handleSubmit(MenuFormData data) async {
    final MenuDetailViewData? detail = _detail;
    if (detail == null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _formErrorMessage = null;
    });

    await ref.read(menuManagementControllerProvider.notifier).updateMenu(detail.menu.id, data);

    if (!mounted) {
      return;
    }

    final MenuManagementState latest = ref.read(menuManagementControllerProvider);
    if (latest.errorMessage != null && latest.errorMessage!.isNotEmpty) {
      setState(() {
        _isSubmitting = false;
        _formErrorMessage = latest.errorMessage;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${data.name} を更新しました")));
    widget.onClose();
  }

  void _handleEditRecipes() {
    final MenuDetailViewData? detail = _detail;
    if (detail == null || widget.onEditRecipes == null) {
      return;
    }
    widget.onEditRecipes!(detail.menu.id);
  }

  void _handleDeleteMenu() {
    final MenuDetailViewData? detail = _detail;
    if (detail == null) {
      return;
    }
    widget.onDeleteMenu(detail.menu);
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: OrderedTraversalPolicy(),
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: "メニュー詳細モーダル",
      child: _buildBody(context),
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(YataSpacingTokens.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadErrorMessage != null || _detail == null || _categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(YataSpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _loadErrorMessage ?? "詳細データが利用できません。",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: YataColorTokens.textSecondary),
            ),
            const SizedBox(height: YataSpacingTokens.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (_loadErrorMessage != null)
                  TextButton(onPressed: _handleRetry, child: const Text("再試行")),
                const SizedBox(width: YataSpacingTokens.sm),
                FilledButton(onPressed: widget.onClose, child: const Text("閉じる")),
              ],
            ),
          ],
        ),
      );
    }

    final MenuDetailViewData detail = _detail!;
    final List<Widget> headerActions = <Widget>[
      IconButton(icon: const Icon(Icons.close), tooltip: "閉じる", onPressed: widget.onClose),
    ];

    final Widget footerLeading = TextButton.icon(
      onPressed: _isSubmitting ? null : _handleDeleteMenu,
      icon: const Icon(Icons.delete_outline),
      style: TextButton.styleFrom(foregroundColor: YataColorTokens.danger),
      label: const Text("削除"),
    );

    return _MenuFormEditor(
      title: "${detail.menu.name} を編集",
      categories: _categories,
      materialOptions: _materialOptions,
      initial: detail.menu,
      initialRecipes: detail.recipes,
      onSubmit: _handleSubmit,
      onCancel: widget.onClose,
      headerActions: headerActions,
      footerLeading: footerLeading,
      cancelLabel: "閉じる",
      isBusy: _isSubmitting,
      errorMessage: _formErrorMessage,
    );
  }
}
