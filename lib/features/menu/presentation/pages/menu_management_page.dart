import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../core/constants/exceptions/base/validation_exception.dart";
import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/mixins/route_aware_refresh_mixin.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../../dto/menu_recipe_detail.dart";
import "../controllers/menu_management_controller.dart";
import "../widgets/menu_category_panel.dart";
import "../widgets/menu_item_detail_panel.dart";
import "../widgets/menu_item_table.dart";
import "../widgets/menu_recipe_editor_dialog.dart";

/// メニュー管理画面。
class MenuManagementPage extends ConsumerStatefulWidget {
  /// [MenuManagementPage]を生成する。
  const MenuManagementPage({super.key});

  /// ルート名。
  static const String routeName = "/menu";

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with RouteAwareRefreshMixin<MenuManagementPage> {
  late final TextEditingController _categorySearchController;
  late final TextEditingController _itemSearchController;

  Future<void> _showRecipeEditorDialog(
    BuildContext context,
    MenuManagementController controller,
    MenuItemViewData menuItem, {
    MenuRecipeDetail? initialRecipe,
  }) async {
    final MenuManagementState snapshot = ref.read(menuManagementControllerProvider);

    final Set<String> existingMaterialIds = snapshot
        .recipesFor(menuItem.id)
        .map((MenuRecipeDetail detail) => detail.materialId)
        .toSet();

    if (initialRecipe != null) {
      existingMaterialIds.remove(initialRecipe.materialId);
    }

    final MenuRecipeEditorResult? result = await showDialog<MenuRecipeEditorResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => MenuRecipeEditorDialog(
        menuItemName: menuItem.name,
        materialCandidates: snapshot.materialCandidates,
        existingMaterialIds: existingMaterialIds,
        initialRecipe: initialRecipe,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await controller.saveRecipe(
        menuItemId: menuItem.id,
        materialId: result.materialId,
        requiredAmount: result.requiredAmount,
        isOptional: result.isOptional,
        notes: result.notes,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(initialRecipe == null ? "材料を追加しました" : "材料を更新しました")),
      );
    } on ValidationException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.errors.join("\n"))),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text("材料の保存に失敗しました: $error")),
      );
    }
  }

  Future<void> _confirmRecipeDeletion(
    BuildContext context,
    MenuManagementController controller,
    MenuItemViewData menuItem,
    MenuRecipeDetail recipe,
  ) async {
    final String? recipeId = recipe.recipeId;
    if (recipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("未保存の材料は削除できません")),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("材料の削除"),
        content: Text(
          "${recipe.materialName} を削除しますか？\n${menuItem.name} の材料リストから除外されます。",
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("キャンセル")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YataColorTokens.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("削除"),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await controller.deleteRecipe(menuItemId: menuItem.id, recipeId: recipeId);
      messenger.showSnackBar(const SnackBar(content: Text("材料を削除しました")));
    } on ValidationException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.errors.join("\n"))),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text("材料の削除に失敗しました: $error")),
      );
    }
  }

  /// 状態の検索クエリとテキストコントローラーを同期する。
  void _syncSearchControllers(MenuManagementState state) {
    if (_categorySearchController.text != state.categoryQuery) {
      _categorySearchController
        ..text = state.categoryQuery
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _categorySearchController.text.length),
        );
    }
    if (_itemSearchController.text != state.itemQuery) {
      _itemSearchController
        ..text = state.itemQuery
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _itemSearchController.text.length),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _categorySearchController = TextEditingController();
    _itemSearchController = TextEditingController();

    final MenuManagementState initialState = ref.read(menuManagementControllerProvider);
    _syncSearchControllers(initialState);
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  @override
  bool get shouldRefreshOnPush => false;

  @override
  Future<void> onRouteReentered() async {
    if (!mounted) {
      return;
    }

    final MenuManagementController controller = ref.read(menuManagementControllerProvider.notifier);
    await _waitForStateIdle<MenuManagementState>(
      controller,
      ref.read(menuManagementControllerProvider),
      (MenuManagementState state) => !state.isInitializing,
    );

    if (!mounted) {
      return;
    }

    await controller.refreshAll();
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
    ref.listen<MenuManagementState>(menuManagementControllerProvider, (
      MenuManagementState? previous,
      MenuManagementState next,
    ) {
      if (!mounted) {
        return;
      }
      _syncSearchControllers(next);
    });

    final MenuManagementState state = ref.watch(menuManagementControllerProvider);
    final MenuManagementController controller = ref.watch(
      menuManagementControllerProvider.notifier,
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
            onTap: () => context.go("/order-status"),
          ),
          YataNavItem(
            label: "履歴",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go("/history"),
          ),
          YataNavItem(
            label: "在庫管理",
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go("/inventory"),
          ),
          const YataNavItem(label: "メニュー管理", icon: Icons.restaurant_menu_outlined, isActive: true),
          YataNavItem(
            label: "売上分析",
            icon: Icons.query_stats_outlined,
            onTap: () => context.go("/analytics"),
          ),
        ],
        trailing: <Widget>[
          YataIconButton(
            icon: Icons.refresh,
            tooltip: "メニュー情報を再取得",
            onPressed: state.isInitializing ? null : controller.refreshAll,
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
            _PageHeader(
              state: state,
              // ignore: unnecessary_lambdas
              onAddItem: () {
                _showMenuItemDialog(context, controller);
              },
              // ignore: unnecessary_lambdas
              onRefreshAvailability: () {
                // ignore: unnecessary_lambdas, リスナー登録のため明示的にラップする
                controller.refreshAvailability();
              },
              // ignore: unnecessary_lambdas
              onFullRefresh: () {
                // ignore: unnecessary_lambdas, オプション引数なしで呼び出すためにラップ
                controller.refreshAll();
              },
            ),
            const SizedBox(height: YataSpacingTokens.lg),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isWide = constraints.maxWidth >= 960;
                final Widget leftPanel = MenuCategoryPanel(
                  state: state,
                  controller: controller,
                  searchController: _categorySearchController,
                  onCreateCategory: () {
                    _showMenuCategoryDialog(context, controller);
                  },
                  onEditCategory: (MenuCategoryViewData category) {
                    _showMenuCategoryDialog(context, controller, initialCategory: category);
                  },
                  onDeleteCategory: (MenuCategoryViewData category) {
                    _confirmCategoryDeletion(context, controller, category);
                  },
                );

                final Widget rightPanel = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    YataSectionCard(
                      title: "メニュー一覧",
                      actions: <Widget>[
                        OutlinedButton.icon(
                          // ignore: unnecessary_lambdas
                          onPressed: () {
                            // ignore: unnecessary_lambdas, onPressed は void 戻り値を要求
                            controller.refreshAvailability();
                          },
                          icon: const Icon(Icons.refresh_outlined),
                          label: const Text("在庫再取得"),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            _showMenuItemDialog(context, controller);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("メニュー追加"),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          YataSearchField(
                            controller: _itemSearchController,
                            hintText: "メニュー名・説明で検索",
                            onChanged: controller.updateItemSearch,
                          ),
                          const SizedBox(height: YataSpacingTokens.md),
                          MenuItemTable(
                            items: state.visibleItems,
                            selectedItemId: state.selectedItemId,
                            availabilityFor: state.availabilityFor,
                            onSelectItem: (MenuItemViewData item) => controller.selectItem(item.id),
                            onToggleAvailability: controller.toggleItemAvailability,
                            isBusy: state.isInitializing,
                            savingItemIds: state.savingItemIds,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: YataSpacingTokens.lg),
                    MenuItemDetailPanel(
                      item: state.selectedItem,
                      availability: state.selectedItem == null
                          ? null
                          : state.availabilityFor(state.selectedItem!.id),
                      onEdit: () {
                        _showMenuItemDialog(context, controller, initialItem: state.selectedItem);
                      },
                      onOpenOptions: () {
                        _showOptionsDialog(context);
                      },
                      onRefreshAvailability: () {
                        final MenuItemViewData? selected = state.selectedItem;
                        if (selected != null) {
                          controller.refreshAvailability(<String>[selected.id]);
                        }
                      },
                      onDelete: () {
                        final MenuItemViewData? selected = state.selectedItem;
                        if (selected != null) {
                          _confirmMenuItemDeletion(context, controller, selected);
                        }
                      },
                      recipes: state.selectedItem == null
                          ? const <MenuRecipeDetail>[]
                          : state.recipesFor(state.selectedItem!.id),
                      isRecipeLoading: state.isRecipeLoading,
                      recipeErrorMessage: state.recipeErrorMessage,
                      onReloadRecipes: () {
                        final MenuItemViewData? selected = state.selectedItem;
                        if (selected != null) {
                          controller.loadRecipesForItem(selected.id, force: true);
                        }
                      },
                      onOpenRecipeEditor: (MenuRecipeDetail? recipe) {
                        final MenuItemViewData? selected = state.selectedItem;
                        if (selected != null) {
                          _showRecipeEditorDialog(context, controller, selected, initialRecipe: recipe);
                        }
                      },
                      onRequestRecipeDelete: (MenuRecipeDetail recipe) {
                        final MenuItemViewData? selected = state.selectedItem;
                        if (selected != null) {
                          _confirmRecipeDeletion(context, controller, selected, recipe);
                        }
                      },
                      savingRecipeMaterialIds: state.savingRecipeMaterialIds,
                      deletingRecipeIds: state.deletingRecipeIds,
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 320, child: leftPanel),
                      const SizedBox(width: YataSpacingTokens.lg),
                      Expanded(child: rightPanel),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    leftPanel,
                    const SizedBox(height: YataSpacingTokens.lg),
                    rightPanel,
                  ],
                );
              },
            ),
            const SizedBox(height: YataSpacingTokens.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenuCategoryDialog(
    BuildContext context,
    MenuManagementController controller, {
    MenuCategoryViewData? initialCategory,
  }) async {
    final MenuManagementState snapshot = ref.read(menuManagementControllerProvider);
    final int defaultOrder =
        initialCategory?.displayOrder ?? _nextCategoryOrder(snapshot.categories);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => _MenuCategoryDialog(
        controller: controller,
        initialCategory: initialCategory,
        defaultDisplayOrder: defaultOrder,
      ),
    );
  }

  Future<void> _confirmCategoryDeletion(
    BuildContext context,
    MenuManagementController controller,
    MenuCategoryViewData category,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("カテゴリの削除"),
        content: Text("${category.name} を削除しますか？関連するメニューも削除される場合があります。"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("キャンセル")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YataColorTokens.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("削除"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await controller.deleteCategory(category.id);
        messenger.showSnackBar(SnackBar(content: Text("${category.name} を削除しました")));
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text("カテゴリ削除に失敗しました: $error")));
      }
    }
  }

  Future<void> _showMenuItemDialog(
    BuildContext context,
    MenuManagementController controller, {
    MenuItemViewData? initialItem,
  }) async {
    final MenuManagementState snapshot = ref.read(menuManagementControllerProvider);
    if (snapshot.categories.isEmpty && initialItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("先にカテゴリを作成してください")));
      return;
    }

    final List<MenuCategoryViewData> categoryOptions = List<MenuCategoryViewData>.from(
      snapshot.categories,
    );
    if (initialItem != null &&
        categoryOptions.every(
          (MenuCategoryViewData category) => category.id != initialItem.categoryId,
        )) {
      categoryOptions.add(
        MenuCategoryViewData(
          id: initialItem.categoryId,
          name: initialItem.categoryName,
          displayOrder: initialItem.displayOrder,
        ),
      );
    }

    final int defaultDisplayOrder = initialItem?.displayOrder ?? _nextItemOrder(snapshot.items);
    final String? initialSelectedCategoryId =
        initialItem?.categoryId ?? (categoryOptions.isNotEmpty ? categoryOptions.first.id : null);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => _MenuItemDialog(
        controller: controller,
        initialItem: initialItem,
        categoryOptions: categoryOptions,
        initialSelectedCategoryId: initialSelectedCategoryId,
        defaultDisplayOrder: defaultDisplayOrder,
      ),
    );
  }

  Future<void> _showOptionsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("オプション編集"),
        content: const Text("オプション編集UIは後続タスクで実装予定です。"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("閉じる")),
        ],
      ),
    );
  }

  Future<void> _confirmMenuItemDeletion(
    BuildContext context,
    MenuManagementController controller,
    MenuItemViewData item,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("メニューの削除"),
        content: Text("${item.name} を削除しますか？"),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("キャンセル")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YataColorTokens.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("削除"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await controller.deleteMenuItem(item.id);
        messenger.showSnackBar(SnackBar(content: Text("${item.name} を削除しました")));
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text("メニュー削除に失敗しました: $error")));
      }
    }
  }

  int _nextCategoryOrder(List<MenuCategoryViewData> categories) {
    if (categories.isEmpty) {
      return 1;
    }
    final int maxOrder = categories
        .map((MenuCategoryViewData category) => category.displayOrder)
        .reduce(math.max);
    return maxOrder + 1;
  }

  int _nextItemOrder(List<MenuItemViewData> items) {
    if (items.isEmpty) {
      return 1;
    }
    final int maxOrder = items.map((MenuItemViewData item) => item.displayOrder).reduce(math.max);
    return maxOrder + 1;
  }
}

/// カテゴリ編集/作成ダイアログ。
class _MenuCategoryDialog extends StatefulWidget {
  const _MenuCategoryDialog({
    required this.controller,
    required this.defaultDisplayOrder,
    this.initialCategory,
  });

  /// 状態制御用のコントローラー。
  final MenuManagementController controller;

  /// 編集対象カテゴリ。新規作成時はnull。
  final MenuCategoryViewData? initialCategory;

  /// 新規作成時に使用する表示順のデフォルト値。
  final int defaultDisplayOrder;

  @override
  State<_MenuCategoryDialog> createState() => _MenuCategoryDialogState();
}

class _MenuCategoryDialogState extends State<_MenuCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? "");
    _orderController = TextEditingController(
      text: (widget.initialCategory?.displayOrder ?? widget.defaultDisplayOrder).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    _isSavingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final int displayOrder = int.parse(_orderController.text.trim());
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    _isSavingNotifier.value = true;
    try {
      if (widget.initialCategory == null) {
        await widget.controller.createCategory(name: name, displayOrder: displayOrder);
        messenger.showSnackBar(const SnackBar(content: Text("カテゴリを追加しました")));
      } else {
        await widget.controller.updateCategory(
          widget.initialCategory!.id,
          name: name,
          displayOrder: displayOrder,
        );
        messenger.showSnackBar(const SnackBar(content: Text("カテゴリを更新しました")));
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text("カテゴリ処理に失敗しました: $error")));
    } finally {
      if (mounted) {
        _isSavingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _isSavingNotifier,
    builder: (BuildContext context, bool isSaving, Widget? _) => AlertDialog(
      title: Text(widget.initialCategory == null ? "カテゴリを追加" : "カテゴリを編集"),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "カテゴリ名"),
                autofocus: true,
                enabled: !isSaving,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return "カテゴリ名を入力してください";
                  }
                  return null;
                },
              ),
              const SizedBox(height: YataSpacingTokens.md),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(labelText: "表示順"),
                keyboardType: TextInputType.number,
                enabled: !isSaving,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return "表示順を入力してください";
                  }
                  final int? parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return "1以上の数値を入力してください";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        FilledButton(
          onPressed: isSaving ? null : _handleSubmit,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("保存"),
        ),
      ],
    ),
  );
}

/// メニューアイテム編集/作成ダイアログ。
class _MenuItemDialog extends StatefulWidget {
  const _MenuItemDialog({
    required this.controller,
    required this.categoryOptions,
    required this.initialSelectedCategoryId,
    required this.defaultDisplayOrder,
    this.initialItem,
  });

  /// 状態制御用のコントローラー。
  final MenuManagementController controller;

  /// 編集対象のメニューアイテム。新規の場合はnull。
  final MenuItemViewData? initialItem;

  /// 選択可能なカテゴリ一覧。
  final List<MenuCategoryViewData> categoryOptions;

  /// 初期選択するカテゴリID。
  final String? initialSelectedCategoryId;

  /// 新規作成時に利用する表示順のデフォルト。
  final int defaultDisplayOrder;

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _displayOrderController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ValueNotifier<String?> _selectedCategoryIdNotifier;
  late final ValueNotifier<bool> _isAvailableNotifier;
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name ?? "");
    _priceController = TextEditingController(text: widget.initialItem?.price.toString() ?? "");
    _displayOrderController = TextEditingController(
      text: (widget.initialItem?.displayOrder ?? widget.defaultDisplayOrder).toString(),
    );
    _descriptionController = TextEditingController(text: widget.initialItem?.description ?? "");
    _imageUrlController = TextEditingController(text: widget.initialItem?.imageUrl ?? "");
    _selectedCategoryIdNotifier = ValueNotifier<String?>(widget.initialSelectedCategoryId);
    _isAvailableNotifier = ValueNotifier<bool>(widget.initialItem?.isAvailable ?? true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _displayOrderController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _selectedCategoryIdNotifier.dispose();
    _isAvailableNotifier.dispose();
    _isSavingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String? selectedCategoryId = _selectedCategoryIdNotifier.value;
    if (selectedCategoryId == null || selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("カテゴリを選択してください")));
      return;
    }

    final int? price = int.tryParse(_priceController.text.trim());
    final int? displayOrder = int.tryParse(_displayOrderController.text.trim());
    if (price == null || price < 0 || displayOrder == null || displayOrder <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("入力値を確認してください")));
      return;
    }

    final bool isAvailable = _isAvailableNotifier.value;
    final String description = _descriptionController.text.trim();
    final String imageUrl = _imageUrlController.text.trim();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    _isSavingNotifier.value = true;
    try {
      if (widget.initialItem == null) {
        await widget.controller.createMenuItem(
          name: _nameController.text.trim(),
          categoryId: selectedCategoryId,
          price: price,
          isAvailable: isAvailable,
          displayOrder: displayOrder,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );
        messenger.showSnackBar(const SnackBar(content: Text("メニューを追加しました")));
      } else {
        await widget.controller.updateMenuItem(
          widget.initialItem!.id,
          name: _nameController.text.trim(),
          categoryId: selectedCategoryId,
          price: price,
          isAvailable: isAvailable,
          displayOrder: displayOrder,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );
        messenger.showSnackBar(const SnackBar(content: Text("メニューを更新しました")));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text("メニュー処理に失敗しました: $error")));
    } finally {
      if (mounted) {
        _isSavingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _isSavingNotifier,
    builder: (BuildContext context, bool isSaving, Widget? _) => AlertDialog(
      title: Text(widget.initialItem == null ? "メニューを追加" : "メニューを編集"),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "商品名"),
                  enabled: !isSaving,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "商品名を入力してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: YataSpacingTokens.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryIdNotifier.value,
                  decoration: const InputDecoration(labelText: "カテゴリ"),
                  items: <DropdownMenuItem<String>>[
                    for (final MenuCategoryViewData category in widget.categoryOptions)
                      DropdownMenuItem<String>(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: isSaving
                      ? null
                      : (String? value) {
                          _selectedCategoryIdNotifier.value = value;
                        },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "カテゴリを選択してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: YataSpacingTokens.md),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "価格"),
                  keyboardType: TextInputType.number,
                  enabled: !isSaving,
                  validator: (String? value) {
                    final int? parsed = int.tryParse(value ?? "");
                    if (parsed == null || parsed < 0) {
                      return "0以上の整数を入力してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: YataSpacingTokens.md),
                TextFormField(
                  controller: _displayOrderController,
                  decoration: const InputDecoration(labelText: "表示順"),
                  keyboardType: TextInputType.number,
                  enabled: !isSaving,
                  validator: (String? value) {
                    final int? parsed = int.tryParse(value ?? "");
                    if (parsed == null || parsed <= 0) {
                      return "1以上の整数を入力してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: YataSpacingTokens.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "説明", hintText: "メニューの説明"),
                  maxLines: 3,
                  enabled: !isSaving,
                ),
                const SizedBox(height: YataSpacingTokens.md),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: "画像URL",
                    hintText: "https://example.com",
                  ),
                  enabled: !isSaving,
                ),
                const SizedBox(height: YataSpacingTokens.sm),
                ValueListenableBuilder<bool>(
                  valueListenable: _isAvailableNotifier,
                  builder: (BuildContext context, bool isAvailable, Widget? _) => SwitchListTile(
                    title: const Text("販売を有効にする"),
                    value: isAvailable,
                    onChanged: isSaving
                        ? null
                        : (bool value) {
                            _isAvailableNotifier.value = value;
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        FilledButton(
          onPressed: isSaving ? null : _handleSubmit,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("保存"),
        ),
      ],
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.state,
    required this.onAddItem,
    required this.onRefreshAvailability,
    required this.onFullRefresh,
  });

  final MenuManagementState state;
  final VoidCallback onAddItem;
  final VoidCallback onRefreshAvailability;
  final VoidCallback onFullRefresh;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat("HH:mm:ss");
    final String updatedAt = state.lastSyncedAt != null
        ? formatter.format(state.lastSyncedAt!)
        : "未同期";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "メニュー管理",
                    style: textTheme.headlineSmall ?? YataTypographyTokens.headlineSmall,
                  ),
                  const SizedBox(height: YataSpacingTokens.xs),
                  Text(
                    "最終同期: $updatedAt / 表示中 ${state.visibleItems.length} 件",
                    style: textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
                  ),
                  const SizedBox(height: YataSpacingTokens.xs),
                  Row(
                    children: <Widget>[
                      YataStatusBadge(
                        label: state.isRealtimeEnabled ? "リアルタイム同期中" : "リアルタイム停止中",
                        type: state.isRealtimeEnabled
                            ? YataStatusBadgeType.success
                            : YataStatusBadgeType.neutral,
                        icon: state.isRealtimeEnabled ? Icons.wifi_tethering : Icons.wifi_off,
                      ),
                      const SizedBox(width: YataSpacingTokens.sm),
                      YataStatusBadge(
                        label: formatter.format(now),
                        type: YataStatusBadgeType.info,
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.isInitializing) ...<Widget>[
          const SizedBox(height: YataSpacingTokens.md),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}
