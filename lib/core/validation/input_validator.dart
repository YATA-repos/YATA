import "../constants/app_strings/app_strings.dart";
import "../logging/logger_binding.dart";

/// 検証結果クラス
class ValidationResult {
  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.success() => const ValidationResult._(true, null);
  factory ValidationResult.error(String message) => ValidationResult._(false, message);

  final bool isValid;
  final String? errorMessage;
}

/// 入力検証用ヘルパークラス
class InputValidator {
  static const String _tag = "InputValidator";

  static void _debug(String message) {
    LoggerBinding.instance.d(message, tag: _tag);
  }

  static void _warn(String message) {
    LoggerBinding.instance.w(message, tag: _tag);
  }

  static void _trace(String message) {
    LoggerBinding.instance.t(message, tag: _tag);
  }

  static void _error(String message) {
    LoggerBinding.instance.e(message, tag: _tag);
  }

  /// 基本的な文字列検証
  static ValidationResult validateString(
    String? value, {
    bool required = false,
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    String fieldName = "フィールド",
  }) {
    if (value == null || value.isEmpty) {
      return required ? ValidationResult.error("$fieldNameは必須です") : ValidationResult.success();
    }

    if (minLength != null && value.length < minLength) {
      return ValidationResult.error("$fieldNameは$minLength文字以上で入力してください");
    }

    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.error("$fieldNameは$maxLength文字以下で入力してください");
    }

    if (pattern != null && !pattern.hasMatch(value)) {
      return ValidationResult.error("$fieldNameの形式が正しくありません");
    }

    return ValidationResult.success();
  }

  /// 数値検証
  static ValidationResult validateNumber(
    dynamic value, {
    bool required = false,
    num? min,
    num? max,
    String fieldName = "フィールド",
  }) {
    if (value == null) {
      return required ? ValidationResult.error("$fieldNameは必須です") : ValidationResult.success();
    }

    late final num numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      final num? parsed = num.tryParse(value);
      if (parsed == null) {
        return ValidationResult.error("$fieldNameは数値で入力してください");
      }
      numValue = parsed;
    } else {
      return ValidationResult.error("$fieldNameは数値で入力してください");
    }

    if (min != null && numValue < min) {
      return ValidationResult.error("$fieldNameは$min以上で入力してください");
    }

    if (max != null && numValue > max) {
      return ValidationResult.error("$fieldNameは$max以下で入力してください");
    }

    return ValidationResult.success();
  }

  /// メールアドレス検証
  static ValidationResult validateEmail(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationEmailRequired)
          : ValidationResult.success();
    }

    const String emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    if (!RegExp(emailPattern).hasMatch(value)) {
      return ValidationResult.error(AppStrings.validationEmailInvalidFormat);
    }

    return ValidationResult.success();
  }

  /// パスワード検証
  static ValidationResult validatePassword(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationPasswordRequired)
          : ValidationResult.success();
    }

    if (value.length < 8) {
      return ValidationResult.error(AppStrings.validationPasswordMinLength);
    }

    if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)").hasMatch(value)) {
      return ValidationResult.error(AppStrings.validationPasswordComplexity);
    }

    return ValidationResult.success();
  }

  /// URL検証
  static ValidationResult validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationUrlRequired)
          : ValidationResult.success();
    }

    try {
      final Uri uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith("http"))) {
          _warn("URL検証エラー: 無効なスキームまたはHTTP/HTTPS以外: $value");
        return ValidationResult.error(AppStrings.validationUrlInvalidFormat);
      }
      return ValidationResult.success();
    } catch (e) {
        _warn("URL検証中にURIパースエラーが発生: ${e.toString()}");
      return ValidationResult.error(AppStrings.validationUrlInvalidFormat);
    }
  }

  /// 日付検証
  static ValidationResult validateDate(
    dynamic value, {
    bool required = false,
    DateTime? minDate,
    DateTime? maxDate,
    String fieldName = "日付",
  }) {
    if (value == null) {
      return required
          ? ValidationResult.error(AppStrings.validationDateRequired)
          : ValidationResult.success();
    }

    late final DateTime dateValue;
    if (value is DateTime) {
      dateValue = value;
    } else if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return ValidationResult.error(AppStrings.validationDateInvalidFormat);
      }
      dateValue = parsed;
    } else {
      return ValidationResult.error(AppStrings.validationDateInvalidFormat);
    }

    if (minDate != null && dateValue.isBefore(minDate)) {
      return ValidationResult.error("日付は${minDate.toString().substring(0, 10)}以降を入力してください");
    }

    if (maxDate != null && dateValue.isAfter(maxDate)) {
      return ValidationResult.error("日付は${maxDate.toString().substring(0, 10)}以前を入力してください");
    }

    return ValidationResult.success();
  }

  /// 複数の検証結果をまとめて確認
  static List<ValidationResult> validateAll(List<ValidationResult> results) {
    final List<ValidationResult> errors = results
        .where((ValidationResult result) => !result.isValid)
        .toList();
    if (errors.isNotEmpty) {
      _debug("バリデーションエラーが${errors.length}件発見されました");
    }
    return errors;
  }

  /// 検証エラーメッセージのリストを取得
  static List<String> getErrorMessages(List<ValidationResult> results) => results
      .where((ValidationResult result) => !result.isValid)
      .map((ValidationResult result) => result.errorMessage!)
      .toList();

  // ======================== 業務固有バリデーション ========================

  /// 価格検証（業務固有）
  static ValidationResult validatePrice(
    dynamic value, {
    bool required = false,
    num? minPrice = 0,
    num? maxPrice,
    String fieldName = "価格",
  }) {
    if (value == null || (value is String && value.isEmpty)) {
      return required
          ? ValidationResult.error(AppStrings.validationPriceRequired)
          : ValidationResult.success();
    }

    late final num numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      // カンマ区切りの価格文字列に対応
      final String cleanValue = value.replaceAll(RegExp(r"[,¥￥\s]"), "");
      final num? parsed = num.tryParse(cleanValue);
      if (parsed == null) {
        return ValidationResult.error(AppStrings.validationPriceInvalidNumber);
      }
      numValue = parsed;
    } else {
      return ValidationResult.error(AppStrings.validationPriceInvalidNumber);
    }

    if (numValue < 0) {
      return ValidationResult.error(AppStrings.validationPriceNonNegative);
    }

    if (minPrice != null && numValue < minPrice) {
      return ValidationResult.error("価格は$minPrice円以上で入力してください");
    }

    if (maxPrice != null && numValue > maxPrice) {
      return ValidationResult.error("価格は$maxPrice円以下で入力してください");
    }

    // 小数点以下の桁数チェック（通常、円は整数）
    if (numValue != numValue.truncate()) {
      return ValidationResult.error(AppStrings.validationPriceInteger);
    }

    return ValidationResult.success();
  }

  /// 在庫数・数量検証（業務固有）
  static ValidationResult validateQuantity(
    dynamic value, {
    bool required = false,
    int minQuantity = 0,
    int? maxQuantity,
    String fieldName = "数量",
    bool allowDecimal = false,
  }) {
    if (value == null || (value is String && value.isEmpty)) {
      return required
          ? ValidationResult.error(AppStrings.validationQuantityRequired)
          : ValidationResult.success();
    }

    late final num numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      final num? parsed = num.tryParse(value);
      if (parsed == null) {
        return ValidationResult.error(AppStrings.validationQuantityInvalidNumber);
      }
      numValue = parsed;
    } else {
      return ValidationResult.error(AppStrings.validationQuantityInvalidNumber);
    }

    if (numValue < 0) {
      return ValidationResult.error(AppStrings.validationQuantityNonNegative);
    }

    if (numValue < minQuantity) {
      return ValidationResult.error("数量は$minQuantity以上で入力してください");
    }

    if (maxQuantity != null && numValue > maxQuantity) {
      return ValidationResult.error("数量は$maxQuantity以下で入力してください");
    }

    // 小数点チェック
    if (!allowDecimal && numValue != numValue.truncate()) {
      return ValidationResult.error(AppStrings.validationQuantityInteger);
    }

    return ValidationResult.success();
  }

  /// 材料名検証（業務固有）
  static ValidationResult validateMaterialName(
    String? value, {
    bool required = true,
    int minLength = 1,
    int maxLength = 50,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationMaterialNameRequired)
          : ValidationResult.success();
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return ValidationResult.error("材料名は$minLength文字以上で入力してください");
    }

    if (trimmedValue.length > maxLength) {
      return ValidationResult.error("材料名は$maxLength文字以下で入力してください");
    }

    // 特殊文字チェック（業務に応じて調整）
    if (RegExp('[<>"&]').hasMatch(trimmedValue)) {
      return ValidationResult.error(AppStrings.validationMaterialNameInvalidChars);
    }

    // 先頭・末尾の空白チェック
    if (value != trimmedValue) {
      return ValidationResult.error(AppStrings.validationMaterialNameWhitespace);
    }

    return ValidationResult.success();
  }

  /// カテゴリ名検証（業務固有）
  static ValidationResult validateCategoryName(
    String? value, {
    bool required = true,
    int minLength = 1,
    int maxLength = 30,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationCategoryNameRequired)
          : ValidationResult.success();
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return ValidationResult.error("カテゴリ名は$minLength文字以上で入力してください");
    }

    if (trimmedValue.length > maxLength) {
      return ValidationResult.error("カテゴリ名は$maxLength文字以下で入力してください");
    }

    // 特殊文字チェック
    if (RegExp(r'[<>"&/\\]').hasMatch(trimmedValue)) {
      return ValidationResult.error(AppStrings.validationCategoryNameInvalidChars);
    }

    // 先頭・末尾の空白チェック
    if (value != trimmedValue) {
      return ValidationResult.error(AppStrings.validationCategoryNameWhitespace);
    }

    return ValidationResult.success();
  }

  /// メニュー項目名検証（業務固有）
  static ValidationResult validateMenuItemName(
    String? value, {
    bool required = true,
    int minLength = 1,
    int maxLength = 60,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationMenuNameRequired)
          : ValidationResult.success();
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return ValidationResult.error("メニュー名は$minLength文字以上で入力してください");
    }

    if (trimmedValue.length > maxLength) {
      return ValidationResult.error("メニュー名は$maxLength文字以下で入力してください");
    }

    // 特殊文字チェック
    if (RegExp('[<>"&]').hasMatch(trimmedValue)) {
      return ValidationResult.error(AppStrings.validationMenuNameInvalidChars);
    }

    // 先頭・末尾の空白チェック
    if (value != trimmedValue) {
      return ValidationResult.error(AppStrings.validationMenuNameWhitespace);
    }

    return ValidationResult.success();
  }

  /// 顧客名検証（業務固有）
  static ValidationResult validateCustomerName(
    String? value, {
    bool required = false,
    int minLength = 1,
    int maxLength = 50,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required
          ? ValidationResult.error(AppStrings.validationCustomerNameRequired)
          : ValidationResult.success();
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return ValidationResult.error("顧客名は$minLength文字以上で入力してください");
    }

    if (trimmedValue.length > maxLength) {
      return ValidationResult.error("顧客名は$maxLength文字以下で入力してください");
    }

    // 特殊文字チェック
    if (RegExp('[<>"&]').hasMatch(trimmedValue)) {
      return ValidationResult.error(AppStrings.validationCustomerNameInvalidChars);
    }

    return ValidationResult.success();
  }

  /// 複合バリデーション: 価格と数量の整合性チェック
  static ValidationResult validatePriceQuantityConsistency(
    dynamic price,
    dynamic quantity, {
    num? maxTotalAmount,
  }) {
    try {
      // 個別の値が有効かチェック
      final ValidationResult priceValidation = validatePrice(price, required: true);
      if (!priceValidation.isValid) {
          _debug("価格バリデーションエラー: ${priceValidation.errorMessage}");
        return priceValidation;
      }

      final ValidationResult quantityValidation = validateQuantity(quantity, required: true);
      if (!quantityValidation.isValid) {
          _debug("数量バリデーションエラー: ${quantityValidation.errorMessage}");
        return quantityValidation;
      }

      // どちらも有効な場合、合計金額をチェック
      if (maxTotalAmount != null) {
        final num priceValue = price is String
            ? num.parse(price.replaceAll(RegExp(r"[,¥￥\s]"), ""))
            : price as num;
        final num quantityValue = quantity is String ? num.parse(quantity) : quantity as num;
        final num totalAmount = priceValue * quantityValue;

        if (totalAmount > maxTotalAmount) {
            _warn("合計金額が上限を超過: 合計=$totalAmount円, 上限=$maxTotalAmount円");
          return ValidationResult.error("合計金額が上限（$maxTotalAmount円）を超えています");
        }

          _trace(
          "価格数量一貫性チェック成功: 価格=$priceValue, 数量=$quantityValue, 合計=$totalAmount",
        );
      }

      return ValidationResult.success();
    } catch (e) {
        _error("価格数量一貫性バリデーション中に予期しないエラーが発生: ${e.toString()}");
      return ValidationResult.error("バリデーション中にエラーが発生しました");
    }
  }
}
