import "package:flutter/material.dart";

import "../../../../shared/foundations/tokens/color_tokens.dart";
import "../../../../shared/foundations/tokens/spacing_tokens.dart";
import "../../../../shared/foundations/tokens/typography_tokens.dart";
import "../../../inventory/models/inventory_model.dart" as inventory;
import "../../dto/menu_recipe_detail.dart";

/// レシピ編集ダイアログの結果。
class MenuRecipeEditorResult {
  const MenuRecipeEditorResult({
    required this.materialId,
    required this.requiredAmount,
    required this.isOptional,
    this.notes,
  });

  /// 選択された材料ID。
  final String materialId;

  /// 必要量。
  final double requiredAmount;

  /// 任意材料かどうか。
  final bool isOptional;

  /// 備考。
  final String? notes;
}

/// メニューの材料レシピを編集するダイアログ。
class MenuRecipeEditorDialog extends StatefulWidget {
  const MenuRecipeEditorDialog({
    required this.menuItemName,
    required this.materialCandidates,
    required this.existingMaterialIds,
    this.initialRecipe,
    super.key,
  });

  /// メニュー名。
  final String menuItemName;

  /// 選択可能な材料候補。
  final List<inventory.Material> materialCandidates;

  /// 既に選択済みの材料ID集合（重複防止用）。
  final Set<String> existingMaterialIds;

  /// 編集対象の既存レシピ。
  final MenuRecipeDetail? initialRecipe;

  @override
  State<MenuRecipeEditorDialog> createState() => _MenuRecipeEditorDialogState();
}

class _MenuRecipeEditorDialogState extends State<MenuRecipeEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _materialSearchController;
  late final TextEditingController _requiredAmountController;
  late final TextEditingController _notesController;

  String? _selectedMaterialId;
  bool _isOptional = false;

  @override
  void initState() {
    super.initState();
    _materialSearchController = TextEditingController();
    _requiredAmountController = TextEditingController();
    _notesController = TextEditingController();

    final MenuRecipeDetail? initial = widget.initialRecipe;
    if (initial != null) {
      _selectedMaterialId = initial.materialId;
      _isOptional = initial.isOptional;
      _requiredAmountController.text = initial.requiredAmount.toString();
      _notesController.text = initial.notes ?? "";
    }
  }

  @override
  void dispose() {
    _materialSearchController.dispose();
    _requiredAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<inventory.Material> materialOptions = _resolveMaterialOptions();
    final inventory.Material? selectedMaterial = _resolveSelectedMaterial(materialOptions);
    final MenuRecipeDetail? initial = widget.initialRecipe;
    final bool hasRealOptions = materialOptions.isNotEmpty;
    final List<DropdownMenuItem<String>> dropdownItems = materialOptions
        .map(
          (inventory.Material material) =>
              DropdownMenuItem<String>(value: material.id, child: Text(material.name)),
        )
        .toList();

    if (_selectedMaterialId != null &&
        dropdownItems.every((DropdownMenuItem<String> item) => item.value != _selectedMaterialId)) {
      final String placeholderLabel = initial?.materialName ?? "未登録の材料";
      dropdownItems.insert(
        0,
        DropdownMenuItem<String>(
          value: _selectedMaterialId,
          child: Text("$placeholderLabel (未登録)"),
        ),
      );
    }

    final bool hasOptions = dropdownItems.isNotEmpty;

    final String unitSymbol =
        selectedMaterial?.unitType.symbol ?? initial?.materialUnitType?.symbol ?? "";
    final double? currentStock = selectedMaterial?.currentStock ?? initial?.materialCurrentStock;

    return AlertDialog(
      title: Text("${widget.menuItemName} の材料"),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _materialSearchController,
                decoration: const InputDecoration(
                  labelText: "材料検索",
                  hintText: "材料名でフィルター",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: YataSpacingTokens.sm),
              DropdownButtonFormField<String>(
                value: hasOptions ? _selectedMaterialId : null,
                decoration: const InputDecoration(labelText: "材料"),
                items: dropdownItems,
                onChanged: hasRealOptions
                    ? (String? value) => setState(() {
                        _selectedMaterialId = value;
                      })
                    : null,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "材料を選択してください";
                  }
                  return null;
                },
              ),
              if (!hasOptions)
                Padding(
                  padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                  child: Text(
                    "選択可能な材料がありません。材料候補を在庫管理で登録してください。",
                    style: textTheme.bodySmall?.copyWith(color: YataColorTokens.danger),
                  ),
                ),
              const SizedBox(height: YataSpacingTokens.md),
              TextFormField(
                controller: _requiredAmountController,
                decoration: InputDecoration(
                  labelText: "必要量",
                  suffixText: unitSymbol.isEmpty ? null : unitSymbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return "必要量を入力してください";
                  }
                  final double? parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return "1以上の数値を入力してください";
                  }
                  return null;
                },
              ),
              if (currentStock != null)
                Padding(
                  padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
                  child: Text(
                    "現在庫: $currentStock ${unitSymbol.isEmpty ? '' : unitSymbol}",
                    style: textTheme.bodySmall ?? YataTypographyTokens.bodySmall,
                  ),
                ),
              const SizedBox(height: YataSpacingTokens.sm),
              SwitchListTile.adaptive(
                value: _isOptional,
                onChanged: (bool value) => setState(() => _isOptional = value),
                title: const Text("任意材料"),
                contentPadding: EdgeInsets.zero,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "備考"),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("キャンセル")),
        FilledButton(onPressed: hasOptions ? _handleSubmit : null, child: const Text("保存")),
      ],
    );
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final double amount = double.parse(_requiredAmountController.text.trim());
    final String materialId = _selectedMaterialId!;
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    Navigator.of(context).pop(
      MenuRecipeEditorResult(
        materialId: materialId,
        requiredAmount: amount,
        isOptional: _isOptional,
        notes: notes,
      ),
    );
  }

  List<inventory.Material> _resolveMaterialOptions() {
    final Set<String> excluded = Set<String>.from(widget.existingMaterialIds);
    final MenuRecipeDetail? initial = widget.initialRecipe;
    if (initial != null) {
      excluded.remove(initial.materialId);
    }

    final String query = _materialSearchController.text.trim().toLowerCase();

    final List<inventory.Material> candidates = <inventory.Material>[...widget.materialCandidates];
    candidates.removeWhere(
      (inventory.Material material) => material.id == null || excluded.contains(material.id),
    );

    if (query.isNotEmpty) {
      candidates.retainWhere(
        (inventory.Material material) => material.name.toLowerCase().contains(query),
      );
    }

    candidates.sort(
      (inventory.Material a, inventory.Material b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return candidates;
  }

  inventory.Material? _resolveSelectedMaterial(List<inventory.Material> options) {
    if (_selectedMaterialId == null) {
      return null;
    }
    try {
      return options.firstWhere(
        (inventory.Material material) => material.id == _selectedMaterialId,
      );
    } catch (_) {
      final MenuRecipeDetail? initial = widget.initialRecipe;
      if (initial?.materialId == _selectedMaterialId) {
        return initial?.material;
      }
      return null;
    }
  }
}
