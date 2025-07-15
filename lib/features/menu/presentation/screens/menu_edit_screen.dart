import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/layouts/responsive_padding.dart";
import "../../models/menu_model.dart";
import "../../repositories/menu_category_repository.dart";
import "../../repositories/menu_item_repository.dart";

/// メニュー編集画面
///
/// メニューアイテムの編集機能を提供します。
class MenuEditScreen extends ConsumerStatefulWidget {
  const MenuEditScreen({required this.menuId, super.key});

  final String menuId;

  @override
  ConsumerState<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends ConsumerState<MenuEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MenuItemRepository _menuItemRepository = MenuItemRepository();
  final MenuCategoryRepository _menuCategoryRepository = MenuCategoryRepository();

  // フォームコントローラー
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _displayOrderController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  MenuItem? _menuItem;
  List<MenuCategory> _categories = <MenuCategory>[];
  String? _selectedCategoryId;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _displayOrderController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: 実際のユーザーIDを取得
      const String userId = "current-user-id";

      // メニューアイテムとカテゴリを並行取得
      final List<Object?> results = await Future.wait(<Future<Object?>>[
        _menuItemRepository.getById(widget.menuId),
        _menuCategoryRepository.findActiveOrdered(userId),
      ]);

      final MenuItem? menuItem = results[0] as MenuItem?;
      final List<MenuCategory> categories = results[1] as List<MenuCategory>;

      if (menuItem == null) {
        throw Exception("メニューアイテムが見つかりません");
      }

      // フォームにデータを設定
      _nameController.text = menuItem.name;
      _descriptionController.text = menuItem.description ?? "";
      _priceController.text = menuItem.price.toString();
      _prepTimeController.text = menuItem.estimatedPrepTimeMinutes.toString();
      _displayOrderController.text = menuItem.displayOrder.toString();
      _imageUrlController.text = menuItem.imageUrl ?? "";

      setState(() {
        _menuItem = menuItem;
        _categories = categories;
        _selectedCategoryId = menuItem.categoryId;
        _isAvailable = menuItem.isAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "メニューデータの取得に失敗しました: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final Map<String, dynamic> updateData = <String, dynamic>{
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        "category_id": _selectedCategoryId,
        "price": int.parse(_priceController.text),
        "is_available": _isAvailable,
        "estimated_prep_time_minutes": int.parse(_prepTimeController.text),
        "display_order": int.parse(_displayOrderController.text),
        "image_url": _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        "updated_at": DateTime.now().toIso8601String(),
      };

      final MenuItem? updatedItem = await _menuItemRepository.updateById(widget.menuId, updateData);

      if (updatedItem != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("メニューが正常に更新されました")));
        Navigator.of(context).pop(true); // 更新成功を返す
      } else {
        throw Exception("メニューの更新に失敗しました");
      }
    } catch (e) {
      setState(() {
        _error = "保存エラー: $e";
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("メニュー編集: ${widget.menuId}"),
      actions: <Widget>[
        if (!_isLoading && _menuItem != null)
          TextButton(
            onPressed: _isSaving ? null : _saveMenuItem,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("保存"),
          ),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("メニューデータを読み込み中..."),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(LucideIcons.alertTriangle, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadMenuData, child: const Text("再試行")),
          ],
        ),
      );
    }

    if (_menuItem == null) {
      return const Center(child: Text("メニューが見つかりません"));
    }

    return ResponsivePadding(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildPricingSection(),
              const SizedBox(height: 24),
              _buildOperationalSection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "基本情報",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "メニュー名 *",
              hintText: "例: ハンバーガー",
              prefixIcon: Icon(LucideIcons.utensils),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return "メニュー名は必須です";
              }
              if (value.trim().length > 100) {
                return "メニュー名は100文字以内で入力してください";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: "説明",
              hintText: "メニューの詳細説明",
              prefixIcon: Icon(LucideIcons.fileText),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (String? value) {
              if (value != null && value.length > 500) {
                return "説明は500文字以内で入力してください";
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildCategorySection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "カテゴリ",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: "カテゴリ *",
              prefixIcon: Icon(LucideIcons.tag),
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map(
                  (MenuCategory category) =>
                      DropdownMenuItem<String>(value: category.id, child: Text(category.name)),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return "カテゴリの選択は必須です";
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildPricingSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "価格設定",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: "価格 (円) *",
              hintText: "例: 800",
              prefixIcon: Icon(LucideIcons.dollarSign),
              border: OutlineInputBorder(),
              suffixText: "円",
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return "価格は必須です";
              }
              final int? price = int.tryParse(value);
              if (price == null || price < 0) {
                return "有効な価格を入力してください";
              }
              if (price > 100000) {
                return "価格は100,000円以下で入力してください";
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildOperationalSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "運営設定",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("販売可能"),
            subtitle: const Text("このメニューアイテムの販売を有効にする"),
            value: _isAvailable,
            onChanged: (bool value) {
              setState(() {
                _isAvailable = value;
              });
            },
            secondary: Icon(
              _isAvailable ? LucideIcons.checkCircle : LucideIcons.xCircle,
              color: _isAvailable ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _prepTimeController,
                  decoration: const InputDecoration(
                    labelText: "調理時間 (分) *",
                    hintText: "例: 15",
                    prefixIcon: Icon(LucideIcons.clock),
                    border: OutlineInputBorder(),
                    suffixText: "分",
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "調理時間は必須です";
                    }
                    final int? time = int.tryParse(value);
                    if (time == null || time < 1) {
                      return "1分以上を入力してください";
                    }
                    if (time > 300) {
                      return "300分以下で入力してください";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _displayOrderController,
                  decoration: const InputDecoration(
                    labelText: "表示順序 *",
                    hintText: "例: 1",
                    prefixIcon: Icon(LucideIcons.arrowUpDown),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return "表示順序は必須です";
                    }
                    final int? order = int.tryParse(value);
                    if (order == null || order < 0) {
                      return "0以上の数値を入力してください";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildImageSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "画像",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: "画像URL",
              hintText: "https://example.com/image.jpg",
              prefixIcon: Icon(LucideIcons.image),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value != null && value.trim().isNotEmpty) {
                final Uri? uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return "有効なURLを入力してください";
                }
              }
              return null;
            },
          ),
          if (_imageUrlController.text.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrlController.text,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                      Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              LucideIcons.imageOff,
                              size: 48,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "画像を読み込めません",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
