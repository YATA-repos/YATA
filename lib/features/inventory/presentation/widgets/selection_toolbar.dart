import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/radius_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../controllers/inventory_management_controller.dart";

/// テーブル選択時に画面下部に現れる一括操作ツールバー。
/// - 選択件数を表示
/// - 削除
/// - 増減用の数値入力 + +/-適用
/// - 選択行の差分を適用
/// - 選択解除
class InventorySelectionToolbar extends ConsumerStatefulWidget {
  const InventorySelectionToolbar({super.key});

  @override
  ConsumerState<InventorySelectionToolbar> createState() => _InventorySelectionToolbarState();
}

class _InventorySelectionToolbarState extends ConsumerState<InventorySelectionToolbar> {
  final TextEditingController _amountCtrl = TextEditingController(text: "1");

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int _parseAmount() => int.tryParse(_amountCtrl.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final InventoryManagementState state = ref.watch(inventoryManagementControllerProvider);
    final InventoryManagementController controller = ref.watch(
      inventoryManagementControllerProvider.notifier,
    );

    if (state.selectedIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final int count = state.selectedIds.length;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Container(
        margin: const EdgeInsets.only(top: YataSpacingTokens.md),
        padding: const EdgeInsets.symmetric(
          horizontal: YataSpacingTokens.lg,
          vertical: YataSpacingTokens.md,
        ),
        decoration: BoxDecoration(
          color: YataColorTokens.surface,
          border: Border(
            top: BorderSide(color: YataColorTokens.neutral200),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(YataRadiusTokens.large),
            topRight: Radius.circular(YataRadiusTokens.large),
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool narrow = constraints.maxWidth < 720;
            final List<Widget> left = <Widget>[
              Icon(Icons.check_box, color: YataColorTokens.primary),
              const SizedBox(width: YataSpacingTokens.sm),
              Text("選択: $count件"),
              const SizedBox(width: YataSpacingTokens.lg),
              TextButton.icon(
                onPressed: controller.clearSelection,
                icon: const Icon(Icons.clear_all),
                label: const Text("選択解除"),
              ),
            ];

            final List<Widget> right = <Widget>[
              // 増減入力
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: "増減量",
                    hintText: "1",
                  ),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              OutlinedButton.icon(
                onPressed: () {
                  final int v = _parseAmount();
                  if (v == 0) {
                    return;
                  }
                  controller.incrementSelectedBy(-v);
                },
                icon: const Icon(Icons.remove),
                label: const Text("一括-"),
              ),
              const SizedBox(width: YataSpacingTokens.sm),
              OutlinedButton.icon(
                onPressed: () {
                  final int v = _parseAmount();
                  if (v == 0) {
                    return;
                  }
                  controller.incrementSelectedBy(v);
                },
                icon: const Icon(Icons.add),
                label: const Text("一括+"),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              Tooltip(
                message: "選択行の調整を適用（0未満になる行はスキップ）",
                child: ElevatedButton.icon(
                  onPressed: controller.applySelected,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text("選択を適用"),
                  style: ElevatedButton.styleFrom(backgroundColor: YataColorTokens.primary),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              Tooltip(
                message: "選択行の未適用調整をクリア",
                child: OutlinedButton.icon(
                  onPressed: controller.clearAdjustmentsForSelected,
                  icon: const Icon(Icons.undo),
                  label: const Text("差分クリア"),
                ),
              ),
              const SizedBox(width: YataSpacingTokens.md),
              Tooltip(
                message: "選択行を削除（モック）",
                child: TextButton.icon(
                  onPressed: () async {
                    final bool? ok = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                        title: const Text("選択行を削除"),
                        content: Text("$count件の行を削除します。よろしいですか？"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text("キャンセル"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text("削除する"),
                          ),
                        ],
                      ),
                    );
                    if (ok ?? false) {
                      controller.deleteSelected();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text("削除", style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ];

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...left,
                  const SizedBox(height: YataSpacingTokens.sm),
                  Wrap(
                    spacing: YataSpacingTokens.sm,
                    runSpacing: YataSpacingTokens.sm,
                    alignment: WrapAlignment.end,
                    children: right,
                  ),
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: Row(children: left)),
                Wrap(
                  spacing: YataSpacingTokens.sm,
                  runSpacing: YataSpacingTokens.sm,
                  children: right,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
