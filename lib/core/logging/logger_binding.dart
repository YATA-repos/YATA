import "../contracts/logging/logger.dart" as contract;
import "levels.dart";

/// LoggerContract をグローバルに公開するための簡易バインディング。
///
/// DI 環境から登録されたロガーを、静的ユーティリティや mixin など
/// 直接 DI を受け取れない箇所でも利用できるようにする。
class LoggerBinding {
  LoggerBinding._();

  static contract.LoggerContract _logger = const _NoopLogger();

  /// 現在登録されているロガーを返す。
  static contract.LoggerContract get instance => _logger;

  /// DI 層からロガーを登録する。
  static void register(contract.LoggerContract logger) {
    _logger = logger;
  }

  /// 状態を初期化するためのリセットヘルパー。
  static void clear() {
    _logger = const _NoopLogger();
  }
}

class _NoopLogger implements contract.LoggerContract {
  const _NoopLogger();

  @override
  void log(
    Level level,
    Object msgOrThunk, {
    String? tag,
    Object? fields,
    Object? error,
    StackTrace? st,
  }) {
    // no-op
  }

  @override
  void t(Object msgOrThunk, {String? tag, Object? fields}) {
    // no-op
  }

  @override
  void d(Object msgOrThunk, {String? tag, Object? fields}) {
    // no-op
  }

  @override
  void i(Object msgOrThunk, {String? tag, Object? fields}) {
    // no-op
  }

  @override
  void w(Object msgOrThunk, {String? tag, Object? fields}) {
    // no-op
  }

  @override
  void e(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) {
    // no-op
  }

  @override
  void f(Object msgOrThunk, {Object? error, StackTrace? st, String? tag, Object? fields}) {
    // no-op
  }

  @override
  Future<void> flushAndClose({Duration timeout = const Duration(seconds: 2)}) async {
    // no-op
  }
}
