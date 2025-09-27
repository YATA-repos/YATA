import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../shared/components/components.dart";
import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../../shared/patterns/patterns.dart";
import "../../../settings/presentation/pages/settings_page.dart";
import "../controllers/menu_management_controller.dart";
import "../widgets/menu_category_panel.dart";
import "../widgets/menu_item_detail_panel.dart";
import "../widgets/menu_item_table.dart";

/// メニュー管理画面。
class MenuManagementPage extends ConsumerStatefulWidget {
  /// [MenuManagementPage]を生成する。
  const MenuManagementPage({super.key});

  /// ルート名。
  static const String routeName = "/menu";

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage> {
  late final TextEditingController _categorySearchController;
  late final TextEditingController _itemSearchController;

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
    final TextEditingController nameController = TextEditingController(
      text: initialCategory?.name ?? "",
    );
    final TextEditingController orderController = TextEditingController(
      text: defaultOrder.toString(),
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setDialogState) =>
            AlertDialog(
              title: Text(initialCategory == null ? "カテゴリを追加" : "カテゴリを編集"),
              content: SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
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
                        controller: orderController,
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final String name = nameController.text.trim();
                          final int displayOrder = int.parse(orderController.text.trim());

                          setDialogState(() => isSaving = true);
                          try {
                            if (initialCategory == null) {
                              await controller.createCategory(
                                name: name,
                                displayOrder: displayOrder,
                              );
                              messenger.showSnackBar(const SnackBar(content: Text("カテゴリを追加しました")));
                            } else {
                              await controller.updateCategory(
                                initialCategory.id,
                                name: name,
                                displayOrder: displayOrder,
                              );
                              messenger.showSnackBar(const SnackBar(content: Text("カテゴリを更新しました")));
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text("カテゴリ処理に失敗しました: $error")),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
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
      ),
    );

    nameController.dispose();
    orderController.dispose();
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

    final TextEditingController nameController = TextEditingController(
      text: initialItem?.name ?? "",
    );
    final TextEditingController priceController = TextEditingController(
      text: initialItem?.price.toString() ?? "",
    );
    final TextEditingController displayOrderController = TextEditingController(
      text: (initialItem?.displayOrder ?? _nextItemOrder(snapshot.items)).toString(),
    );
    final TextEditingController prepTimeController = TextEditingController(
      text: (initialItem?.estimatedPrepTimeMinutes ?? 5).toString(),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: initialItem?.description ?? "",
    );
    final TextEditingController imageUrlController = TextEditingController(
      text: initialItem?.imageUrl ?? "",
    );

    String? selectedCategoryId =
        initialItem?.categoryId ?? (categoryOptions.isNotEmpty ? categoryOptions.first.id : null);
    bool isAvailable = initialItem?.isAvailable ?? true;
    bool isSaving = false;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setDialogState) =>
            AlertDialog(
              title: Text(initialItem == null ? "メニューを追加" : "メニューを編集"),
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
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(labelText: "カテゴリ"),
                          items: <DropdownMenuItem<String>>[
                            for (final MenuCategoryViewData category in categoryOptions)
                              DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                          ],
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
                        TextFormField(
                          controller: priceController,
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
                          controller: displayOrderController,
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
                          controller: prepTimeController,
                          decoration: const InputDecoration(labelText: "調理時間(分)"),
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
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: "説明", hintText: "メニューの説明"),
                          maxLines: 3,
                          enabled: !isSaving,
                        ),
                        const SizedBox(height: YataSpacingTokens.md),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: "画像URL",
                            hintText: "https://example.com",
                          ),
                          enabled: !isSaving,
                        ),
                        const SizedBox(height: YataSpacingTokens.sm),
                        SwitchListTile(
                          title: const Text("販売を有効にする"),
                          value: isAvailable,
                          onChanged: isSaving
                              ? null
                              : (bool value) {
                                  setDialogState(() => isAvailable = value);
                                },
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          if (selectedCategoryId == null) {
                            messenger.showSnackBar(const SnackBar(content: Text("カテゴリを選択してください")));
                            return;
                          }
                          final int price = int.parse(priceController.text.trim());
                          final int displayOrder = int.parse(displayOrderController.text.trim());
                          final int prepMinutes = int.parse(prepTimeController.text.trim());

                          setDialogState(() => isSaving = true);
                          try {
                            if (initialItem == null) {
                              await controller.createMenuItem(
                                name: nameController.text.trim(),
                                categoryId: selectedCategoryId!,
                                price: price,
                                isAvailable: isAvailable,
                                estimatedPrepTimeMinutes: prepMinutes,
                                displayOrder: displayOrder,
                                description: descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                imageUrl: imageUrlController.text.trim().isEmpty
                                    ? null
                                    : imageUrlController.text.trim(),
                              );
                              messenger.showSnackBar(const SnackBar(content: Text("メニューを追加しました")));
                            } else {
                              await controller.updateMenuItem(
                                initialItem.id,
                                name: nameController.text.trim(),
                                categoryId: selectedCategoryId,
                                price: price,
                                isAvailable: isAvailable,
                                estimatedPrepTimeMinutes: prepMinutes,
                                displayOrder: displayOrder,
                                description: descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                imageUrl: imageUrlController.text.trim().isEmpty
                                    ? null
                                    : imageUrlController.text.trim(),
                              );
                              messenger.showSnackBar(const SnackBar(content: Text("メニューを更新しました")));
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text("メニュー処理に失敗しました: $error")),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
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
      ),
    );

    nameController.dispose();
    priceController.dispose();
    displayOrderController.dispose();
    prepTimeController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
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
            Wrap(
              spacing: YataSpacingTokens.sm,
              runSpacing: YataSpacingTokens.sm,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onFullRefresh,
                  icon: const Icon(Icons.sync_outlined),
                  label: const Text("全体更新"),
                ),
                OutlinedButton.icon(
                  onPressed: onRefreshAvailability,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text("在庫チェック"),
                ),
                FilledButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("メニュー追加"),
                ),
              ],
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
