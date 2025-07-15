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
    const String emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    return validateString(
      value,
      required: required,
      pattern: RegExp(emailPattern),
      fieldName: "メールアドレス",
    );
  }

  /// パスワード検証
  static ValidationResult validatePassword(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? ValidationResult.error("パスワードは必須です") : ValidationResult.success();
    }

    if (value.length < 8) {
      return ValidationResult.error("パスワードは8文字以上で入力してください");
    }

    if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)").hasMatch(value)) {
      return ValidationResult.error("パスワードは大文字、小文字、数字を含む必要があります");
    }

    return ValidationResult.success();
  }

  /// URL検証
  static ValidationResult validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? ValidationResult.error("URLは必須です") : ValidationResult.success();
    }

    try {
      final Uri uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith("http"))) {
        return ValidationResult.error("有効なURLを入力してください");
      }
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error("有効なURLを入力してください");
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
      return required ? ValidationResult.error("$fieldNameは必須です") : ValidationResult.success();
    }

    late final DateTime dateValue;
    if (value is DateTime) {
      dateValue = value;
    } else if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return ValidationResult.error("$fieldNameの形式が正しくありません");
      }
      dateValue = parsed;
    } else {
      return ValidationResult.error("$fieldNameの形式が正しくありません");
    }

    if (minDate != null && dateValue.isBefore(minDate)) {
      return ValidationResult.error(
        "$fieldNameは${minDate.toString().substring(0, 10)}以降を入力してください",
      );
    }

    if (maxDate != null && dateValue.isAfter(maxDate)) {
      return ValidationResult.error(
        "$fieldNameは${maxDate.toString().substring(0, 10)}以前を入力してください",
      );
    }

    return ValidationResult.success();
  }

  /// 複数の検証結果をまとめて確認
  static List<ValidationResult> validateAll(List<ValidationResult> results) =>
      results.where((ValidationResult result) => !result.isValid).toList();

  /// 検証エラーメッセージのリストを取得
  static List<String> getErrorMessages(List<ValidationResult> results) => results
      .where((ValidationResult result) => !result.isValid)
      .map((ValidationResult result) => result.errorMessage!)
      .toList();
}
