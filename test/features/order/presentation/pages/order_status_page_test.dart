import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:yata/app/wiring/provider.dart";
import "package:yata/core/constants/enums.dart";
import "package:yata/features/auth/presentation/providers/auth_providers.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/presentation/pages/order_status_page.dart";
import "package:yata/features/order/services/order_service.dart";
import "package:yata/features/order/shared/order_status_presentation.dart";
import "package:yata/shared/mixins/route_aware_refresh_mixin.dart";

class _MockOrderService extends Mock implements OrderService {}

void main() {
  testWidgets("OrderStatusPage refreshes when returning to the route", (WidgetTester tester) async {
    final RouteObserver<PageRoute<dynamic>> observer = RouteObserver<PageRoute<dynamic>>();
    debugRouteObserverOverride = observer;
    addTearDown(() => debugRouteObserverOverride = null);

    final _MockOrderService mockOrderService = _MockOrderService();
    when(
      () => mockOrderService.getOrdersByStatuses(OrderStatusPresentation.displayOrder, "test-user"),
    ).thenAnswer((Invocation _) async => <OrderStatus, List<Order>>{});

    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          orderServiceProvider.overrideWithValue(mockOrderService),
          currentUserIdProvider.overrideWithValue("test-user"),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: <NavigatorObserver>[observer],
          routes: <String, WidgetBuilder>{
            "/": (BuildContext context) => const OrderStatusPage(),
            "/second": (BuildContext context) => const Scaffold(body: Text("second")),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    verify(
      () => mockOrderService.getOrdersByStatuses(OrderStatusPresentation.displayOrder, "test-user"),
    ).called(1);

    clearInteractions(mockOrderService);

    navigatorKey.currentState!.pushNamed("/second");
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    verify(
      () => mockOrderService.getOrdersByStatuses(OrderStatusPresentation.displayOrder, "test-user"),
    ).called(1);
  });
}
