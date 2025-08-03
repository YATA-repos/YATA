import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../../core/constants/constants.dart";
import "../../../core/logging/logger_mixin.dart";
import "../../../core/validation/input_validator.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// バリデーション実行のタイミング
enum ValidationMode {
  /// リアルタイム（入力と同時）
  realtime,
  
  /// デバウンス付きリアルタイム（入力停止後300ms）
  debounced,
  
  /// フォーカス喪失時のみ
  onFocusLost,
  
  /// 手動実行のみ
  manual,
}

/// AppTextField - 統一されたテキスト入力コンポーネント
///
/// 既存のAppTextTheme入力スタイルを完全活用し、
/// バリデーション・業務特化入力タイプに対応した統一された入力フィールドを提供します。
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.inputType = TextInputType.text,
    this.variant = TextFieldVariant.outlined,
    this.validation,
    this.validationMode = ValidationMode.debounced,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    super.key,
  });

  /// メールアドレス入力用ファクトリー
  factory AppTextField.forEmail({
    TextEditingController? controller,
    String? labelText = "メールアドレス",
    String? hintText = "example@email.com",
    bool required = false,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    inputType: TextInputType.emailAddress,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateEmail(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  /// パスワード入力用ファクトリー
  factory AppTextField.forPassword({
    TextEditingController? controller,
    String? labelText = "パスワード",
    String? hintText,
    bool required = false,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    obscureText: true,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validatePassword(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  /// 材料名入力用ファクトリー
  factory AppTextField.forMaterialName({
    TextEditingController? controller,
    String? labelText = "材料名",
    String? hintText,
    bool required = true,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateMaterialName(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  /// カテゴリ名入力用ファクトリー
  factory AppTextField.forCategoryName({
    TextEditingController? controller,
    String? labelText = "カテゴリ名",
    String? hintText,
    bool required = true,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateCategoryName(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  /// メニュー名入力用ファクトリー
  factory AppTextField.forMenuName({
    TextEditingController? controller,
    String? labelText = "メニュー名",
    String? hintText,
    bool required = true,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateMenuItemName(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  /// 顧客名入力用ファクトリー
  factory AppTextField.forCustomerName({
    TextEditingController? controller,
    String? labelText = "顧客名",
    String? hintText,
    bool required = false,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    Key? key,
  }) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    onChanged: onChanged,
    focusNode: focusNode,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateCustomerName(value, required: required);
      return result.isValid ? null : result.errorMessage;
    },
    key: key,
  );

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType inputType;
  final TextFieldVariant variant;
  final String? Function(String?)? validation;
  final ValidationMode validationMode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> with LoggerMixin {
  @override
  String get loggerComponent => "AppTextField";
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _validationError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    // バリデーションモードに応じてリスナーを設定
    _setupValidationListeners();
    logTrace("AppTextField初期化: validationMode=${widget.validationMode}, inputType=${widget.inputType}");
  }

  @override
  void dispose() {
    try {
      _debounceTimer?.cancel();
      if (widget.controller == null) {
        _controller.dispose();
      }
      if (widget.focusNode == null) {
        _focusNode.dispose();
      }
      logTrace("AppTextFieldリソースを破棄");
      super.dispose();
    } catch (e, stackTrace) {
      logError("AppTextField破棄中にエラーが発生", e, stackTrace);
      super.dispose();
    }
  }

  void _setupValidationListeners() {
    try {
      switch (widget.validationMode) {
        case ValidationMode.realtime:
          _controller.addListener(_validateInputRealtime);
          logTrace("リアルタイムバリデーションリスナーを設定");
          break;
        case ValidationMode.debounced:
          _controller.addListener(_validateInputDebounced);
          logTrace("デバウンス付きバリデーションリスナーを設定");
          break;
        case ValidationMode.onFocusLost:
          _focusNode.addListener(_onFocusChanged);
          logTrace("フォーカス喪失時バリデーションリスナーを設定");
          break;
        case ValidationMode.manual:
          logTrace("手動バリデーションモード - リスナーなし");
          break;
      }
    } catch (e, stackTrace) {
      logError("バリデーションリスナー設定中にエラーが発生: mode=${widget.validationMode}", e, stackTrace);
    }
  }

  void _validateInputRealtime() {
    try {
      if (widget.validation != null) {
        final String? error = widget.validation!(_controller.text);
        if (mounted && error != _validationError) {
          setState(() {
            _validationError = error;
          });
          if (error != null) {
            logTrace("バリデーションエラーを検出: $error");
          }
        }
      }
    } catch (e, stackTrace) {
      logError("リアルタイムバリデーション中にエラーが発生: text=${_controller.text}", e, stackTrace);
    }
  }

  void _validateInputDebounced() {
    try {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(AppConfig.debounceTimeout, () {
        try {
          if (mounted) {
            _validateInputRealtime();
          }
        } catch (e, stackTrace) {
          logError("デバウンスバリデーション実行中にエラーが発生", e, stackTrace);
        }
      });
    } catch (e, stackTrace) {
      logError("デバウンスタイマー設定中にエラーが発生", e, stackTrace);
    }
  }

  void _onFocusChanged() {
    try {
      if (!_focusNode.hasFocus) {
        logTrace("フォーカス喪失によりバリデーションを実行");
        _validateInputRealtime();
      }
    } catch (e, stackTrace) {
      logError("フォーカス変更処理中にエラーが発生", e, stackTrace);
    }
  }

  /// 手動バリデーション実行（外部から呼び出し可能）
  void validateManually() {
    try {
      logDebug("手動バリデーションを実行");
      _validateInputRealtime();
    } catch (e, stackTrace) {
      logError("手動バリデーション実行中にエラーが発生", e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? effectiveErrorText = widget.errorText ?? _validationError;
    final bool hasError = effectiveErrorText != null;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.inputType,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      style: AppTextTheme.inputText,
      decoration: _buildInputDecoration(hasError, effectiveErrorText),
    );
  }

  InputDecoration _buildInputDecoration(bool hasError, String? errorText) {
    final InputDecoration baseDecoration = _getBaseDecoration();

    return baseDecoration.copyWith(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: errorText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefix: widget.prefix,
      suffix: widget.suffix,
      labelStyle: AppTextTheme.inputLabel.copyWith(color: hasError ? AppColors.danger : null),
      hintStyle: AppTextTheme.inputHint,
      helperStyle: AppTextTheme.cardDescription,
      errorStyle: AppTextTheme.dangerText,

      // エラー状態の境界線
      border: _getBorder(hasError),
      enabledBorder: _getBorder(hasError),
      focusedBorder: _getFocusedBorder(hasError),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getErrorBorder(focused: true),
    );
  }

  InputDecoration _getBaseDecoration() => switch (widget.variant) {
    TextFieldVariant.outlined => const InputDecoration(
      filled: true,
      fillColor: AppColors.background,
    ),
    TextFieldVariant.underlined => const InputDecoration(filled: false),
    TextFieldVariant.filled => const InputDecoration(filled: true, fillColor: AppColors.muted),
  };

  InputBorder _getBorder(bool hasError) {
    if (hasError) {
      return _getErrorBorder();
    }

    return switch (widget.variant) {
      TextFieldVariant.outlined => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      TextFieldVariant.underlined => UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.border),
      ),
      TextFieldVariant.filled => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    };
  }

  InputBorder _getFocusedBorder(bool hasError) {
    if (hasError) {
      return _getErrorBorder(focused: true);
    }

    return switch (widget.variant) {
      TextFieldVariant.outlined => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      TextFieldVariant.underlined => UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      TextFieldVariant.filled => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    };
  }

  InputBorder _getErrorBorder({bool focused = false}) {
    final double width = focused ? 2.0 : 1.0;

    return switch (widget.variant) {
      TextFieldVariant.outlined => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.danger, width: width),
      ),
      TextFieldVariant.underlined => UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: width),
      ),
      TextFieldVariant.filled => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.danger, width: width),
      ),
    };
  }
}

/// 価格入力専用テキストフィールド
class PriceTextField extends StatelessWidget {
  const PriceTextField({
    this.controller,
    this.labelText = "価格",
    this.hintText = "0",
    this.onChanged,
    this.validation,
    super.key,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final void Function(String)? onChanged;
  final String? Function(String?)? validation;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    inputType: TextInputType.number,
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      _PriceInputFormatter(),
    ],
    prefixIcon: const Icon(Icons.currency_yen),
    onChanged: onChanged,
    validation: validation ?? _defaultPriceValidation,
  );

  String? _defaultPriceValidation(String? value) {
    final ValidationResult result = InputValidator.validatePrice(value, required: true);
    return result.isValid ? null : result.errorMessage;
  }
}

/// 数量入力専用テキストフィールド
class QuantityTextField extends StatelessWidget {
  const QuantityTextField({
    this.controller,
    this.labelText = "数量",
    this.hintText = "1",
    this.min = 0,
    this.max,
    this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int min;
  final int? max;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    inputType: TextInputType.number,
    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
    onChanged: onChanged,
    validation: (String? value) {
      final ValidationResult result = InputValidator.validateQuantity(
        value,
        required: true,
        minQuantity: min,
        maxQuantity: max,
        fieldName: labelText ?? "数量",
      );
      return result.isValid ? null : result.errorMessage;
    },
  );
}

/// 検索用テキストフィールド
class SearchTextField extends StatelessWidget {
  const SearchTextField({
    this.controller,
    this.hintText = "検索...",
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    super.key,
  });

  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    hintText: hintText,
    prefixIcon: const Icon(Icons.search),
    suffixIcon: controller?.text.isNotEmpty ?? false
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller?.clear();
              onClear?.call();
            },
          )
        : null,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

/// 価格フォーマッター（カンマ区切り）
class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String digits = newValue.text.replaceAll(RegExp(r"[^\d]"), "");
    final String formatted = _addCommas(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addCommas(String value) {
    if (value.isEmpty) {
      return value;
    }

    final RegExp regex = RegExp(r"(\d)(?=(\d{3})+(?!\d))");
    return value.replaceAllMapped(regex, (Match match) => "${match[1]},");
  }
}
