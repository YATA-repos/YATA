import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_card.dart";
import "../../../../shared/widgets/common/app_icon_button.dart";
import "../../../../shared/widgets/common/app_input.dart";

class OrderItemEditor extends StatefulWidget {
  const OrderItemEditor({
    required this.item,
    super.key,
    this.onQuantityChanged,
    this.onOptionsChanged,
    this.onNotesChanged,
    this.onRemove,
    this.isCompact = false,
    this.showPrice = true,
    this.showNotes = true,
    this.showOptions = true,
    this.readOnly = false,
    this.validator,
  });

  final OrderItemData item;
  final ValueChanged<int>? onQuantityChanged;
  final ValueChanged<List<String>>? onOptionsChanged;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback? onRemove;
  final bool isCompact;
  final bool showPrice;
  final bool showNotes;
  final bool showOptions;
  final bool readOnly;
  final String? Function(OrderItemData)? validator;

  @override
  State<OrderItemEditor> createState() => _OrderItemEditorState();
}

class _OrderItemEditorState extends State<OrderItemEditor> {
  late TextEditingController _notesController;
  late TextEditingController _quantityController;
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _selectedOptions = List<String>.from(widget.item.selectedOptions);

    _notesController.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _notesController
      ..removeListener(_onNotesChanged)
      ..dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrderItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.notes != oldWidget.item.notes) {
      _notesController.text = widget.item.notes;
    }

    if (widget.item.quantity != oldWidget.item.quantity) {
      _quantityController.text = widget.item.quantity.toString();
    }

    if (widget.item.selectedOptions != oldWidget.item.selectedOptions) {
      _selectedOptions = List<String>.from(widget.item.selectedOptions);
    }
  }

  void _onNotesChanged() {
    if (!widget.readOnly) {
      widget.onNotesChanged?.call(_notesController.text);
    }
  }

  void _incrementQuantity() {
    if (widget.readOnly) {
      return;
    }

    final int newQuantity = widget.item.quantity + 1;
    if (newQuantity <= 99) {
      _updateQuantity(newQuantity);
    }
  }

  void _decrementQuantity() {
    if (widget.readOnly) {
      return;
    }

    final int newQuantity = widget.item.quantity - 1;
    if (newQuantity >= 0) {
      _updateQuantity(newQuantity);
    }
  }

  void _updateQuantity(int quantity) {
    _quantityController.text = quantity.toString();
    widget.onQuantityChanged?.call(quantity);
  }

  void _onQuantityInputChanged(String value) {
    if (widget.readOnly) {
      return;
    }

    final int? quantity = int.tryParse(value);
    if (quantity != null && quantity >= 0 && quantity <= 99) {
      widget.onQuantityChanged?.call(quantity);
    }
  }

  void _toggleOption(String option) {
    if (widget.readOnly) {
      return;
    }

    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
    });

    widget.onOptionsChanged?.call(_selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactLayout();
    } else {
      return _buildFullLayout();
    }
  }

  Widget _buildFullLayout() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        const SizedBox(height: AppLayout.spacing4),
        _buildQuantitySection(),
        if (widget.showOptions && widget.item.availableOptions.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildOptionsSection(),
        ],
        if (widget.showNotes) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildNotesSection(),
        ],
        if (widget.showPrice) ...<Widget>[
          const SizedBox(height: AppLayout.spacing4),
          _buildPriceSection(),
        ],
      ],
    ),
  );

  Widget _buildCompactLayout() => Container(
    padding: AppLayout.padding3,
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: AppLayout.radiusMd,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.item.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (widget.showPrice)
                Text(
                  "¥${_getTotalPrice().toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        _buildQuantityControls(),
        if (!widget.readOnly && widget.onRemove != null) ...<Widget>[
          const SizedBox(width: AppLayout.spacing2),
          AppIconButton(
            icon: Icons.delete_outline,
            onPressed: widget.onRemove,
            size: ButtonSize.small,
          ),
        ],
      ],
    ),
  );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (widget.item.description.isNotEmpty)
              Text(
                widget.item.description,
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
              ),
          ],
        ),
      ),
      if (!widget.readOnly && widget.onRemove != null)
        AppIconButton(icon: Icons.delete_outline, onPressed: widget.onRemove),
    ],
  );

  Widget _buildQuantitySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text("数量", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      const SizedBox(height: AppLayout.spacing2),
      _buildQuantityControls(),
    ],
  );

  Widget _buildQuantityControls() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      AppIconButton(
        icon: Icons.remove,
        onPressed: widget.readOnly ? null : _decrementQuantity,
        size: ButtonSize.small,
      ),
      const SizedBox(width: AppLayout.spacing2),
      SizedBox(
        width: 60,
        child: AppInput(
          controller: _quantityController,
          variant: InputVariant.number,
          enabled: !widget.readOnly,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: _onQuantityInputChanged,
        ),
      ),
      const SizedBox(width: AppLayout.spacing2),
      AppIconButton(
        icon: Icons.add,
        onPressed: widget.readOnly ? null : _incrementQuantity,
        size: ButtonSize.small,
      ),
    ],
  );

  Widget _buildOptionsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text("オプション", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      const SizedBox(height: AppLayout.spacing2),
      ...widget.item.availableOptions.map(_buildOptionItem),
    ],
  );

  Widget _buildOptionItem(MenuOption option) {
    final bool isSelected = _selectedOptions.contains(option.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppLayout.spacing1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.readOnly ? null : () => _toggleOption(option.id),
          borderRadius: AppLayout.radiusSm,
          child: Padding(
            padding: AppLayout.padding2,
            child: Row(
              children: <Widget>[
                Checkbox(
                  value: isSelected,
                  onChanged: widget.readOnly ? null : (bool? value) => _toggleOption(option.id),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: AppLayout.spacing2),
                Expanded(child: Text(option.name, style: const TextStyle(fontSize: 14))),
                if (option.additionalPrice > 0)
                  Text(
                    "+¥${option.additionalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text("特記事項", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      const SizedBox(height: AppLayout.spacing2),
      AppInput(
        controller: _notesController,
        hintText: "特記事項があれば入力してください",
        maxLines: 3,
        enabled: !widget.readOnly,
      ),
    ],
  );

  Widget _buildPriceSection() {
    final double unitPrice = widget.item.unitPrice + _getOptionsPrice();
    final double totalPrice = _getTotalPrice();

    return Container(
      padding: AppLayout.padding3,
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: AppLayout.radiusMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text("単価", style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              Text(
                "¥${unitPrice.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text("小計", style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              Text(
                "¥${totalPrice.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getOptionsPrice() => widget.item.availableOptions
      .where((MenuOption option) => _selectedOptions.contains(option.id))
      .fold(0.0, (double sum, MenuOption option) => sum + option.additionalPrice);

  double _getTotalPrice() {
    final double unitPrice = widget.item.unitPrice + _getOptionsPrice();
    return unitPrice * widget.item.quantity;
  }
}

class OrderItemData {
  const OrderItemData({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.description = "",
    this.notes = "",
    this.selectedOptions = const <String>[],
    this.availableOptions = const <MenuOption>[],
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double unitPrice;
  final int quantity;
  final String notes;
  final List<String> selectedOptions;
  final List<MenuOption> availableOptions;
  final String? imageUrl;

  OrderItemData copyWith({
    String? id,
    String? name,
    String? description,
    double? unitPrice,
    int? quantity,
    String? notes,
    List<String>? selectedOptions,
    List<MenuOption>? availableOptions,
    String? imageUrl,
  }) => OrderItemData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
    selectedOptions: selectedOptions ?? this.selectedOptions,
    availableOptions: availableOptions ?? this.availableOptions,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

class MenuOption {
  const MenuOption({
    required this.id,
    required this.name,
    this.additionalPrice = 0.0,
    this.description = "",
  });

  final String id;
  final String name;
  final double additionalPrice;
  final String description;
}
