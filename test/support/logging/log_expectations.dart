import "dart:async";

import "package:test/test.dart";
import "package:yata/core/logging/levels.dart";

import "fake_logger.dart";

/// ログ検証を簡潔に書けるアサーションヘルパー。
Future<CapturedLog> expectLog(
  LogProbe probe, {
  Duration? timeout,
  Level? level,
  String? tag,
  Pattern? tagPattern,
  String? messageEquals,
  Pattern? messageContains,
  RegExp? messageMatches,
  bool Function(Map<String, dynamic>? fields)? fieldsWhere,
  bool Function(Object? error)? errorWhere,
  bool Function(CapturedLog log)? where,
}) async {
  bool predicate(CapturedLog log) {
    if (where != null && !where(log)) {
      return false;
    }
    if (level != null && log.level != level) {
      return false;
    }
    if (tag != null && log.tag != tag) {
      return false;
    }
    if (tagPattern != null && !_matchesPattern(log.tag, tagPattern)) {
      return false;
    }
    if (messageEquals != null && log.message != messageEquals) {
      return false;
    }
    if (messageContains != null && !_matchesPattern(log.message, messageContains)) {
      return false;
    }
    if (messageMatches != null && !messageMatches.hasMatch(log.message)) {
      return false;
    }
    if (fieldsWhere != null && !fieldsWhere(log.fields)) {
      return false;
    }
    if (errorWhere != null && !errorWhere(log.error)) {
      return false;
    }
    return true;
  }

  final CapturedLog captured = await probe.waitFor(timeout: timeout, where: predicate);

  if (level != null) {
    expect(captured.level, level);
  }
  if (tag != null) {
    expect(captured.tag, tag);
  }
  if (tagPattern != null) {
    expect(_matchesPattern(captured.tag, tagPattern), isTrue);
  }
  if (messageEquals != null) {
    expect(captured.message, messageEquals);
  }
  if (messageContains != null) {
    expect(_matchesPattern(captured.message, messageContains), isTrue);
  }
  if (messageMatches != null) {
    expect(messageMatches.hasMatch(captured.message), isTrue);
  }
  if (fieldsWhere != null) {
    expect(fieldsWhere(captured.fields), isTrue);
  }
  if (errorWhere != null) {
    expect(errorWhere(captured.error), isTrue);
  }

  return captured;
}

/// 指定の条件に一致するログが一定時間現れないことを検証する。
Future<void> expectNoLog(
  LogProbe probe, {
  Duration timeout = const Duration(milliseconds: 200),
  bool Function(CapturedLog log)? where,
}) async {
  try {
    final CapturedLog unexpected = await probe.waitFor(timeout: timeout, where: where);
    fail("Unexpected log detected: ${unexpected.summary()}");
  } on TimeoutException {
    // OK: no matching log arrived.
  }
}

bool _matchesPattern(String? actual, Pattern pattern) {
  if (actual == null) {
    return false;
  }
  if (pattern is RegExp) {
    return pattern.hasMatch(actual);
  }
  // Text pattern: treat as substring containment
  return actual.contains(pattern);
}
