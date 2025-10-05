import "dart:async";
import "dart:io";

import "../../core/contracts/logging/logger.dart" as contract;

/// Fatal ログを外部通知へルーティングするためのインターフェース。
abstract class FatalNotifier {
  const FatalNotifier();

  FutureOr<void> notify(contract.FatalLogContext context);
}

/// クロージャベースで簡単に [FatalNotifier] を生成するユーティリティ。
class ClosureFatalNotifier extends FatalNotifier {
  const ClosureFatalNotifier(this._handler);

  final FutureOr<void> Function(contract.FatalLogContext context) _handler;

  @override
  FutureOr<void> notify(contract.FatalLogContext context) => _handler(context);
}

/// 複数のノーティファーをまとめて呼び出す合成ノーティファー。
class CompositeFatalNotifier extends FatalNotifier {
  const CompositeFatalNotifier(this._notifiers);

  final List<FatalNotifier> _notifiers;

  @override
  Future<void> notify(contract.FatalLogContext context) async {
    for (final FatalNotifier notifier in _notifiers) {
      await notifier.notify(context);
    }
  }
}

/// シンプルに `stderr` へ致命ログの概要を出力するノーティファー。
class StdoutFatalNotifier extends FatalNotifier {
  const StdoutFatalNotifier({this.includeError = true});

  final bool includeError;

  @override
  Future<void> notify(contract.FatalLogContext context) async {
    final contract.LogRecord record = context.record;
    final StringBuffer buffer = StringBuffer()
      ..write("[FATAL] ${record.timestamp.toIso8601String()} tag=${record.tag ?? '-'} msg=${record.message}");
    if (includeError && context.error != null) {
      buffer.write(" error=${context.error}");
    }
    if (includeError && context.stackTrace != null) {
      buffer.write("\n${context.stackTrace}");
    }
    stderr.writeln(buffer.toString());
  }
}
