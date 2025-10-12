import "dart:collection";

final RegExp _whitespacePattern = RegExp(r"\s+");

/// 検索用正規化ユーティリティ。
class SearchNormalizer {
  const SearchNormalizer._();

  /// トークンを検索用に正規化する。空文字列になった場合は`null`を返す。
  static String? normalizeToken(String? value) {
    final String? collapsed = collapseWhitespace(value);
    if (collapsed == null) {
      return null;
    }
    return _normalizeWidthAndKana(collapsed).toLowerCase();
  }

  /// 余分な空白を取り除き、連続する空白を1つにまとめる。
  static String? collapseWhitespace(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.replaceAll(_whitespacePattern, " ");
  }

  /// ソート比較用の正規化を行う。
  static String normalizeForSort(String input) => normalizeToken(input) ?? "";

  static String _normalizeWidthAndKana(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x30A1 && rune <= 0x30F3) {
        buffer.writeCharCode(rune - 0x60);
        continue;
      }

      final int? halfWidth = _halfWidthKatakanaToHiragana[rune];
      if (halfWidth != null) {
        buffer.writeCharCode(halfWidth);
        continue;
      }

      if ((rune >= 0xFF10 && rune <= 0xFF19) ||
          (rune >= 0xFF21 && rune <= 0xFF3A) ||
          (rune >= 0xFF41 && rune <= 0xFF5A)) {
        buffer.writeCharCode(rune - 0xFEE0);
        continue;
      }

      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  static const Map<int, int> _halfWidthKatakanaToHiragana = <int, int>{
    0xFF66: 0x3092,
    0xFF67: 0x3041,
    0xFF68: 0x3043,
    0xFF69: 0x3045,
    0xFF6A: 0x3047,
    0xFF6B: 0x3049,
    0xFF6C: 0x3083,
    0xFF6D: 0x3085,
    0xFF6E: 0x3087,
    0xFF6F: 0x3063,
    0xFF70: 0x30FC,
    0xFF71: 0x3042,
    0xFF72: 0x3044,
    0xFF73: 0x3046,
    0xFF74: 0x3048,
    0xFF75: 0x304A,
    0xFF76: 0x304B,
    0xFF77: 0x304D,
    0xFF78: 0x304F,
    0xFF79: 0x3051,
    0xFF7A: 0x3053,
    0xFF7B: 0x3055,
    0xFF7C: 0x3057,
    0xFF7D: 0x3059,
    0xFF7E: 0x305B,
    0xFF7F: 0x305D,
    0xFF80: 0x305F,
    0xFF81: 0x3061,
    0xFF82: 0x3064,
    0xFF83: 0x3066,
    0xFF84: 0x3068,
    0xFF85: 0x306A,
    0xFF86: 0x306B,
    0xFF87: 0x306C,
    0xFF88: 0x306D,
    0xFF89: 0x306E,
    0xFF8A: 0x306F,
    0xFF8B: 0x3072,
    0xFF8C: 0x3075,
    0xFF8D: 0x3078,
    0xFF8E: 0x307B,
    0xFF8F: 0x307E,
    0xFF90: 0x307F,
    0xFF91: 0x3080,
    0xFF92: 0x3081,
    0xFF93: 0x3082,
    0xFF94: 0x3084,
    0xFF95: 0x3086,
    0xFF96: 0x3088,
    0xFF97: 0x3089,
    0xFF98: 0x308A,
    0xFF99: 0x308B,
    0xFF9A: 0x308C,
    0xFF9B: 0x308D,
    0xFF9C: 0x308F,
    0xFF9D: 0x3093,
  };
}

/// 検索用インデックスを構築するヘルパー。
class SearchIndexBuilder {
  SearchIndexBuilder();

  final LinkedHashSet<String> _parts = LinkedHashSet<String>();

  void add(String? value) {
    final String? normalized = SearchNormalizer.normalizeToken(value);
    if (normalized != null && normalized.isNotEmpty) {
      _parts.add(normalized);
    }
    final String? collapsed = SearchNormalizer.collapseWhitespace(value);
    if (collapsed != null && collapsed.isNotEmpty) {
      final String lower = collapsed.toLowerCase();
      if (normalized != lower) {
        _parts.add(lower);
      }
    }
  }

  void addAll(Iterable<String?> values) {
    for (final String? value in values) {
      add(value);
    }
  }

  String build() => _parts.join(" ");
}

/// 検索クエリを正規化しトークンに分割する。
List<String> tokenizeSearchQuery(String rawQuery) {
  final String? collapsed = SearchNormalizer.collapseWhitespace(rawQuery);
  if (collapsed == null) {
    return const <String>[];
  }
  final List<String> tokens = <String>[];
  for (final String part in collapsed.split(_whitespacePattern)) {
    final String? normalized = SearchNormalizer.normalizeToken(part);
    if (normalized != null && normalized.isNotEmpty) {
      tokens.add(normalized);
    }
  }
  return tokens;
}

/// 検索トークンが全てインデックスに含まれるかを確認する。
bool matchesSearchTokens(String searchIndex, List<String> tokens) {
  if (tokens.isEmpty) {
    return true;
  }
  for (final String token in tokens) {
    if (!searchIndex.contains(token)) {
      return false;
    }
  }
  return true;
}
