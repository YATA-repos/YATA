import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";
// Dialog-free inline editing does not need app theme import

/// 数量の増減を行うステッパー。
class YataQuantityStepper extends StatefulWidget {
  /// [YataQuantityStepper]を生成する。
  const YataQuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max,
    this.compact = false,
  });

  /// 現在の数量。
  final int value;

  /// 数量変更時に呼ばれる。
  final ValueChanged<int> onChanged;

  /// 最小値。
  final int min;

  /// 最大値。未指定の場合は制限なし。
  final int? max;

  /// コンパクト表示にするかどうか。
  final bool compact;

  @override
  State<YataQuantityStepper> createState() => _YataQuantityStepperState();
}

class _YataQuantityStepperState extends State<YataQuantityStepper> {
  bool _editing = false;
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toString(),
  );
  final FocusNode _focusNode = FocusNode();

  bool get _canDecrement => widget.value > widget.min;
  bool get _canIncrement => widget.max == null || widget.value < widget.max!;

  int _clampQuantity(int q) {
    if (q < widget.min) return widget.min;
    if (widget.max != null && q > widget.max!) return widget.max!;
    return q;
  }

  void _beginEdit() {
    setState(() {
      _editing = true;
      _controller.text = widget.value.toString();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  void _commitEdit() {
    if (!_editing) return;
    final int? parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = widget.value.toString();
    } else {
      final int clamped = _clampQuantity(parsed);
      if (clamped != widget.value) widget.onChanged(clamped);
    }
    if (mounted) setState(() => _editing = false);
  }

  void _cancelEdit() {
    if (!_editing) return;
    _controller.text = widget.value.toString();
    _focusNode.unfocus();
    if (mounted) setState(() => _editing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant YataQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle =
        (Theme.of(context).textTheme.titleMedium ?? YataTypographyTokens.titleMedium).copyWith(
          color: YataColorTokens.textPrimary,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: YataColorTokens.border),
        borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
        color: YataColorTokens.neutral0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove,
            enabled: _canDecrement,
            onPressed: () {
              if (_editing) _commitEdit();
              if (_canDecrement) {
                widget.onChanged(widget.value - 1);
              }
            },
            compact: widget.compact,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.compact ? 22 : 28),
            child: _editing
                ? SizedBox(
                    width: (widget.compact ? 36 : 48),
                    child: Shortcuts(
                      shortcuts: <ShortcutActivator, Intent>{
                        SingleActivator(LogicalKeyboardKey.escape): const _CancelEditIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          _CancelEditIntent: CallbackAction<_CancelEditIntent>(
                            onInvoke: (_CancelEditIntent intent) {
                              _cancelEdit();
                              return null;
                            },
                          ),
                        },
                        child: Focus(
                          onFocusChange: (bool hasFocus) {
                            if (!hasFocus) _commitEdit();
                          },
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: valueStyle,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onSubmitted: (_) => _commitEdit(),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: _beginEdit,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(YataRadiusTokens.medium),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.compact ? YataSpacingTokens.sm : YataSpacingTokens.md,
                        ),
                        alignment: Alignment.center,
                        child: Text("${widget.value}", style: valueStyle),
                      ),
                    ),
                  ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: _canIncrement,
            onPressed: () {
              if (_editing) _commitEdit();
              if (_canIncrement) {
                widget.onChanged(widget.value + 1);
              }
            },
            compact: widget.compact,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
      child: Padding(
        padding: EdgeInsets.all(compact ? YataSpacingTokens.xs : YataSpacingTokens.sm),
        child: Icon(
          icon,
          size: compact ? 18 : 20,
          color: enabled ? YataColorTokens.textPrimary : YataColorTokens.textSecondary,
        ),
      ),
    ),
  );
}

class _CancelEditIntent extends Intent {
  const _CancelEditIntent();
}
