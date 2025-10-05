import "package:test/test.dart";

import "package:yata/infra/logging/context.dart";
import "package:yata/infra/logging/context_utils.dart";

void main() {
  group("context id generation", () {
    test("newFlowId generates prefixed unique value", () {
      final String a = newFlowId();
      final String b = newFlowId();

      expect(a, startsWith("flow_"));
      expect(b, startsWith("flow_"));
      expect(a, isNot(equals(b)));
    });

    test("newSpanId generates prefixed unique value", () {
      final String span = newSpanId();
      expect(span, startsWith("span_"));
    });
  });

  group("trace scopes", () {
    test("traceAsync inherits flow and parent span", () async {
      await traceAsync<void>("root", (LogTrace root) async {
        final LogContext? ctx = currentLogContext();
        expect(ctx, isNotNull);
        expect(ctx![LogContextKeys.spanName], equals("root"));
        expect(ctx[LogContextKeys.spanId], equals(root.spanId));
        expect(root.parentSpanId, isNull);

        await traceAsync<void>("child", (LogTrace child) async {
          final LogContext? childCtx = currentLogContext();
          expect(childCtx, isNotNull);
          expect(childCtx![LogContextKeys.flowId], equals(root.flowId));
          expect(childCtx[LogContextKeys.parentSpanId], equals(root.spanId));
          expect(child.parentSpanId, equals(root.spanId));
        });
      });
    });

    test("traceAsync can start a new flow", () async {
      String? parentFlow;
      String? childFlow;

      await traceAsync<void>("parent", (LogTrace parent) async {
        parentFlow = parent.flowId;
        await traceAsync<void>(
          "detached",
          (LogTrace child) async {
            childFlow = child.flowId;
          },
          startNewFlow: true,
        );
      });

      expect(parentFlow, isNotNull);
      expect(childFlow, isNotNull);
      expect(childFlow, isNot(equals(parentFlow)));
    });

    test("traceSync exposes context synchronously", () {
      final LogTrace result = traceSync<LogTrace>("sync", (LogTrace trace) {
        final LogContext? inside = currentLogContext();
        expect(inside, isNotNull);
        expect(inside![LogContextKeys.spanName], equals("sync"));
        return trace;
      });

      expect(result.spanName, equals("sync"));
      expect(result.context[LogContextKeys.spanName], equals("sync"));
    });
  });
}
