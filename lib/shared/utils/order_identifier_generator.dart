import "dart:math";

/// 注文番号生成に関するユーティリティ
class OrderIdentifierGenerator {
  OrderIdentifierGenerator({DateTime Function()? nowProvider, Random? random})
    : _nowProvider = nowProvider ?? DateTime.now,
      _random = random ?? Random.secure();

  static const String _base62Alphabet =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  static const String _base36Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static const int defaultSlugLength = 11;
  static const int defaultDisplayCodeLength = 4;
  static const Duration _jstOffset = Duration(hours: 9);
  static const String _jstSuffix = "+0900";

  final DateTime Function() _nowProvider;
  final Random _random;

  /// JST(UTC+9) のタイムスタンプ文字列を生成する。
  ///
  /// 形式: `YYYYMMDDThhmmss+0900`
  String generateJstTimestampString() {
    final DateTime nowUtc = _nowProvider().toUtc();
    final DateTime jstUtc = nowUtc.add(_jstOffset);
    final DateTime truncated = DateTime.utc(
      jstUtc.year,
      jstUtc.month,
      jstUtc.day,
      jstUtc.hour,
      jstUtc.minute,
      jstUtc.second,
    );

    final String year = truncated.year.toString().padLeft(4, "0");
    final String month = truncated.month.toString().padLeft(2, "0");
    final String day = truncated.day.toString().padLeft(2, "0");
    final String hour = truncated.hour.toString().padLeft(2, "0");
    final String minute = truncated.minute.toString().padLeft(2, "0");
    final String second = truncated.second.toString().padLeft(2, "0");

    return "$year$month${day}T$hour$minute$second$_jstSuffix";
  }

  /// CSPRNG を利用して Base62 乱数文字列を生成する。
  ///
  /// [length] で文字数を指定し、デフォルトは 11 文字。
  String generateBase62Slug({int length = defaultSlugLength}) {
    if (length <= 0) {
      throw ArgumentError.value(length, "length", "length must be greater than 0");
    }

    final StringBuffer buffer = StringBuffer();
    while (buffer.length < length) {
      final int index = _random.nextInt(_base62Alphabet.length);
      buffer.write(_base62Alphabet[index]);
    }

    return buffer.toString();
  }

  /// CSPRNG を利用して Base36 乱数文字列を生成する。
  ///
  /// [length] で文字数を指定し、デフォルトは 4 文字。
  String generateDisplayCode({int length = defaultDisplayCodeLength}) {
    if (length <= 0) {
      throw ArgumentError.value(length, "length", "length must be greater than 0");
    }

    final StringBuffer buffer = StringBuffer();
    while (buffer.length < length) {
      final int index = _random.nextInt(_base36Alphabet.length);
      buffer.write(_base36Alphabet[index]);
    }

    return buffer.toString();
  }

  /// 新フォーマットの注文番号（表示コード）を生成する。
  ///
  /// 形式: `^[A-Z0-9]{length}$`（デフォルトは4文字）
  String generateOrderNumber({int length = defaultDisplayCodeLength}) =>
      generateDisplayCode(length: length);
}
