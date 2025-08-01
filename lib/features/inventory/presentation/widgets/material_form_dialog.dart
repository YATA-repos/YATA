import "package:flutter/material.dart" hide Material;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../../../shared/widgets/forms/app_text_field.dart";
import "../../../auth/presentation/providers/auth_providers.dart";
import "../../models/inventory_model.dart";
import "../../services/material_management_service.dart";
import "../providers/inventory_providers.dart";

/// 材料フォームダイアログ
///
/// 材料の追加・編集を行うダイアログ
class MaterialFormDialog extends ConsumerStatefulWidget {
  const MaterialFormDialog({
    this.material,
    super.key,
  });

  /// 編集対象の材料（nullの場合は追加モード）
  final Material? material;

  @override
  ConsumerState<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends ConsumerState<MaterialFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // フォームコントローラー
  late final TextEditingController _nameController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _alertThresholdController;
  late final TextEditingController _criticalThresholdController;
  late final TextEditingController _notesController;
  
  // フォーム状態
  String? _selectedCategoryId;
  UnitType _selectedUnitType = UnitType.piece;
  bool _isLoading = false;
  
  String? get userId => ref.read(currentUserProvider)?.id;
  bool get isEditMode => widget.material != null;

  @override
  void initState() {
    super.initState();
    
    // コントローラーを初期化
    final Material? material = widget.material;
    _nameController = TextEditingController(text: material?.name ?? "");
    _currentStockController = TextEditingController(
      text: material?.currentStock.toString() ?? "0",
    );
    _alertThresholdController = TextEditingController(
      text: material?.alertThreshold.toString() ?? AppConfig.defaultAlertThreshold.toString(),
    );
    _criticalThresholdController = TextEditingController(
      text: material?.criticalThreshold.toString() ?? "5",
    );
    _notesController = TextEditingController(text: material?.notes ?? "");
    
    // 初期値を設定
    if (material != null) {
      _selectedCategoryId = material.categoryId;
      _selectedUnitType = material.unitType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentStockController.dispose();
    _alertThresholdController.dispose();
    _criticalThresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return AlertDialog(
        title: const Text("エラー"),
        content: const Text("ユーザー情報が取得できません"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("閉じる"),
          ),
        ],
      );
    }

    return ref.watch(materialCategoriesProvider).when(
      data: _buildDialog,
      loading: () => const AlertDialog(
        title: Text("読み込み中"),
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => AlertDialog(
        title: const Text("エラー"),
        content: Text("カテゴリー情報の取得に失敗しました: $error"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("閉じる"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialog(List<MaterialCategory> categories) => AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(
            isEditMode ? LucideIcons.edit : LucideIcons.plus,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isEditMode ? "材料編集" : "材料追加",
            style: AppTextTheme.cardTitle,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 材料名
                AppTextField.forMaterialName(
                  controller: _nameController,
                ),
                AppLayout.vSpacerDefault,

                // カテゴリー選択と単位選択
                Row(
                  children: <Widget>[
                    // カテゴリー選択
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "カテゴリー",
                            style: AppTextTheme.inputLabel,
                          ),
                          AppLayout.vSpacerSmall,
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text("カテゴリーを選択"),
                            items: categories.map((MaterialCategory category) => DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              )).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return "カテゴリーを選択してください";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 単位選択
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "管理単位",
                            style: AppTextTheme.inputLabel,
                          ),
                          AppLayout.vSpacerSmall,
                          DropdownButtonFormField<UnitType>(
                            value: _selectedUnitType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: UnitType.values.map((UnitType unit) => DropdownMenuItem<UnitType>(
                                value: unit,
                                child: Text("${unit.displayName} (${unit.symbol})"),
                              )).toList(),
                            onChanged: (UnitType? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedUnitType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppLayout.vSpacerDefault,

                // 在庫量
                AppTextField(
                  controller: _currentStockController,
                  labelText: "現在在庫量",
                  inputType: const TextInputType.numberWithOptions(decimal: true),
                  validation: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "現在在庫量は必須です";
                    }
                    final double? number = double.tryParse(value);
                    if (number == null || number < 0) {
                      return "0以上の数値を入力してください";
                    }
                    return null;
                  },
                ),
                AppLayout.vSpacerDefault,

                // 閾値設定
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        controller: _alertThresholdController,
                        labelText: "アラート閾値",
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        validation: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "アラート閾値は必須です";
                          }
                          final double? number = double.tryParse(value);
                          if (number == null || number < 0) {
                            return "0以上の数値を入力してください";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _criticalThresholdController,
                        labelText: "緊急閾値",
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        validation: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "緊急閾値は必須です";
                          }
                          final double? number = double.tryParse(value);
                          if (number == null || number < 0) {
                            return "0以上の数値を入力してください";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                AppLayout.vSpacerSmall,
                
                // 閾値説明
                Text(
                  "緊急閾値はアラート閾値以下である必要があります",
                  style: AppTextTheme.inputHint.copyWith(fontSize: 12),
                ),
                AppLayout.vSpacerDefault,

                // メモ
                AppTextField(
                  controller: _notesController,
                  labelText: "メモ（オプション）",
                  hintText: "材料に関する備考を入力...",
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        AppButton(
          onPressed: _isLoading ? null : _handleSave,
          text: isEditMode ? "更新" : "追加",
          size: ButtonSize.small,
          isLoading: _isLoading,
        ),
      ],
    );

  /// 保存処理
  Future<void> _handleSave() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    // 閾値の相関チェック
    final double? alertThreshold = double.tryParse(_alertThresholdController.text);
    final double? criticalThreshold = double.tryParse(_criticalThresholdController.text);
    
    if (alertThreshold == null || criticalThreshold == null) {
      _showErrorSnackBar("閾値は有効な数値で入力してください");
      return;
    }
    
    if (criticalThreshold > alertThreshold) {
      _showErrorSnackBar("緊急閾値はアラート閾値以下である必要があります");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Material material = Material(
        id: widget.material?.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        unitType: _selectedUnitType,
        currentStock: double.tryParse(_currentStockController.text) ?? 0,
        alertThreshold: alertThreshold,
        criticalThreshold: criticalThreshold,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      final MaterialManagementService service = 
          ref.read(materialManagementServiceProvider);

      if (isEditMode) {
        await service.updateMaterial(material);
      } else {
        await service.createMaterial(material);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 成功フラグを返す
        _showSuccessSnackBar(
          isEditMode ? "材料を更新しました" : "材料を追加しました",
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          isEditMode 
              ? "材料の更新に失敗しました: $e" 
              : "材料の追加に失敗しました: $e",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}