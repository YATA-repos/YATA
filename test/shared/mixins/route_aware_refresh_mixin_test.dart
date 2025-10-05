import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/shared/mixins/route_aware_refresh_mixin.dart";

void main() {
  group("RouteAwareRefreshMixin", () {
    late DateTime fakeNow;

    setUp(() {
      fakeNow = DateTime(2025, 1, 1, 12);
      debugRouteObserverOverride = RouteObserver<PageRoute<dynamic>>();
      debugNowProviderOverride = () => fakeNow;
      RouteAwareRefreshMixin.resetExitTimestampsForTest();
    });

    tearDown(() {
      debugRouteObserverOverride = null;
      debugNowProviderOverride = null;
    });

    testWidgets("calls onRouteReentered on didPush and didPopNext", (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestRefreshWidget(
            onRefresh: () async {
              callCount++;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final _TestRefreshWidgetState state = tester.state(find.byType(TestRefreshWidget));
      expect(callCount, 1);

      state.triggerDidPopNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(callCount, 2);
    });

    testWidgets("suppresses concurrent refresh triggers", (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestRefreshWidget(
            onRefresh: () async {
              callCount++;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final _TestRefreshWidgetState state = tester.state(find.byType(TestRefreshWidget));
      state.setOnRefreshOverride(() async {
        callCount++;
        await completer.future;
      });

      state.triggerDidPopNext();
      state.triggerDidPopNext();

      // allow microtasks
      await tester.pump();
      expect(callCount, 2);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      state.clearOnRefreshOverride();
      state.triggerDidPopNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(callCount, 3);
    });

    testWidgets("honours shouldRefreshOnPush flag", (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestRefreshWidget(
            onRefresh: () async {
              callCount++;
            },
            refreshOnPush: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, 0);

      final _TestRefreshWidgetState state = tester.state(find.byType(TestRefreshWidget));
      state.triggerDidPopNext();
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets("respects refresh cooldown before triggering", (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TestRefreshWidget(
            onRefresh: () async {
              callCount++;
            },
            refreshOnPush: false,
            refreshCooldown: const Duration(seconds: 5),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, 0);

      final _TestRefreshWidgetState state = tester.state(find.byType(TestRefreshWidget));

      state.triggerDidPushNext();
      await tester.pump();

      // re-enter immediately -> cooldown not elapsed
      state.triggerDidPopNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, 0);

      // leave again and wait for cooldown window
      state.triggerDidPushNext();
      await tester.pump();

      fakeNow = fakeNow.add(const Duration(seconds: 6));

      state.triggerDidPopNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(callCount, 1);
    });
  });
}

class TestRefreshWidget extends StatefulWidget {
  const TestRefreshWidget({
    required this.onRefresh,
    this.refreshOnPush = true,
    this.refreshCooldown,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final bool refreshOnPush;
  final Duration? refreshCooldown;

  @override
  State<TestRefreshWidget> createState() => _TestRefreshWidgetState();
}

class _TestRefreshWidgetState extends State<TestRefreshWidget>
    with RouteAwareRefreshMixin<TestRefreshWidget> {
  Future<void> Function()? _override;

  @override
  bool get shouldRefreshOnPush => widget.refreshOnPush;

  @override
  Duration? get refreshCooldown => widget.refreshCooldown;

  @override
  Future<void> onRouteReentered() {
    final Future<void> Function() callback = _override ?? widget.onRefresh;
    return callback();
  }

  void setOnRefreshOverride(Future<void> Function() callback) {
    _override = callback;
  }

  void clearOnRefreshOverride() {
    _override = null;
  }

  void triggerDidPopNext() {
    didPopNext();
  }

  void triggerDidPushNext() {
    didPushNext();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
