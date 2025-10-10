import "package:flutter_test/flutter_test.dart";

import "package:yata/features/order/presentation/performance/order_management_tracing.dart";
import "package:yata/infra/config/runtime_overrides.dart";

void main() {
  setUp(OrderManagementTracer.debugReset);
  tearDown(OrderManagementTracer.debugReset);

  test("環境変数でトレーシングを無効化できる", () {
    OrderManagementTracer.configureFromEnvironment(
      env: <String, String>{"ORDER_MANAGEMENT_PERF_TRACING": "false"},
    );

    expect(OrderManagementTracer.isEnabled, isFalse);
  });

  test("実行時オーバーライドが環境設定より優先される", () {
    OrderManagementTracer.configureFromEnvironment(
      env: <String, String>{"ORDER_MANAGEMENT_PERF_TRACING": "false"},
    );
    expect(OrderManagementTracer.isEnabled, isFalse);

    OrderManagementTracer.applyRuntimeOverride(enabled: true);

    expect(OrderManagementTracer.isEnabled, isTrue);
    expect(RuntimeOverrides.getBool("ORDER_MANAGEMENT_PERF_TRACING"), isTrue);
  });

  test("サンプリング設定は環境変数と実行時で上書き可能", () {
    OrderManagementTracer.configureFromEnvironment(
      env: <String, String>{
        "ORDER_MANAGEMENT_PERF_TRACING": "true",
        "ORDER_MANAGEMENT_PERF_SAMPLE_MODULO": "5",
      },
    );

    expect(OrderManagementTracer.shouldSample(10), isTrue);
    expect(OrderManagementTracer.shouldSample(12), isFalse);

    OrderManagementTracer.applyRuntimeOverride(sampleModulo: 3);

    expect(OrderManagementTracer.shouldSample(6), isTrue);
    expect(OrderManagementTracer.shouldSample(4), isFalse);
    expect(RuntimeOverrides.getInt("ORDER_MANAGEMENT_PERF_SAMPLE_MODULO"), equals(3));
  });
}
