import "dart:async";

import "package:flutter_test/flutter_test.dart";

import "package:yata/core/contracts/logging/logger.dart" as contract;
import "package:yata/core/logging/levels.dart";
import "package:yata/infra/logging/fatal_notifier.dart";
import "package:yata/infra/logging/log_config.dart";
import "package:yata/infra/logging/logger.dart";

void main() {
  group("Logger fatal handling", () {
    late LogConfig original;

    setUp(() {
      original = config.copyWith();
      clearFatalHandlers();
    });

    tearDown(() {
      clearFatalHandlers();
      updateLoggerConfig((_) => original);
    });

    test("invokes registered fatal handler with context", () async {
      final Completer<contract.FatalLogContext> completer = Completer<contract.FatalLogContext>();
      registerFatalHandler((contract.FatalLogContext context) {
        if (!completer.isCompleted) {
          completer.complete(context);
        }
      });

      f("fatal handler test", tag: "test");

    final contract.FatalLogContext context =
      await completer.future.timeout(const Duration(seconds: 2));
    expect(context.record.level, Level.fatal);
      expect(context.record.message, "fatal handler test");
      await context.flush();
    });

    test("registerFatalNotifier wraps notifier", () async {
      final Completer<void> notifierCalled = Completer<void>();
      registerFatalNotifier(ClosureFatalNotifier((contract.FatalLogContext _) {
        if (!notifierCalled.isCompleted) {
          notifierCalled.complete();
        }
      }));

      f("fatal notifier test");

      await notifierCalled.future.timeout(const Duration(seconds: 2));
    });

    test("removing fatal handler prevents invocation", () async {
      int counter = 0;
      FutureOr<void> handler(contract.FatalLogContext _) {
        counter++;
      }
      registerFatalHandler(handler);
      removeFatalHandler(handler);

      f("fatal removal test");
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(counter, 0);
    });
  });
}
