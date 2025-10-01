import "package:flutter_test/flutter_test.dart";
import "package:yata/features/order/presentation/controllers/order_history_controller.dart";
import "package:yata/features/order/presentation/pages/order_history_page.dart";

void main() {
  group("orderHistoryItemsSummary", () {
    test("商品がない場合は「商品なし」を返す", () {
      expect(orderHistoryItemsSummary(const <OrderItemViewData>[]), "商品なし");
    });

    test("1件の場合は商品名をそのまま返す", () {
      const OrderItemViewData item = OrderItemViewData(
        menuItemId: "1",
        menuItemName: "たこ焼き",
        quantity: 1,
        unitPrice: 500,
        subtotal: 500,
      );

      expect(orderHistoryItemsSummary(const <OrderItemViewData>[item]), "たこ焼き");
    });

    test("3件以下の場合はカンマ区切りで返す", () {
      const List<OrderItemViewData> items = <OrderItemViewData>[
        OrderItemViewData(
          menuItemId: "1",
          menuItemName: "焼きそば",
          quantity: 1,
          unitPrice: 600,
          subtotal: 600,
        ),
        OrderItemViewData(
          menuItemId: "2",
          menuItemName: "お好み焼き",
          quantity: 2,
          unitPrice: 700,
          subtotal: 1400,
        ),
        OrderItemViewData(
          menuItemId: "3",
          menuItemName: "もんじゃ",
          quantity: 1,
          unitPrice: 650,
          subtotal: 650,
        ),
      ];

      expect(orderHistoryItemsSummary(items), "焼きそば, お好み焼き, もんじゃ");
    });

    test("3件を超える場合は「他○件」を追加する", () {
      const List<OrderItemViewData> items = <OrderItemViewData>[
        OrderItemViewData(
          menuItemId: "1",
          menuItemName: "焼き鳥",
          quantity: 3,
          unitPrice: 120,
          subtotal: 360,
        ),
        OrderItemViewData(
          menuItemId: "2",
          menuItemName: "ビール",
          quantity: 2,
          unitPrice: 550,
          subtotal: 1100,
        ),
        OrderItemViewData(
          menuItemId: "3",
          menuItemName: "枝豆",
          quantity: 1,
          unitPrice: 300,
          subtotal: 300,
        ),
        OrderItemViewData(
          menuItemId: "4",
          menuItemName: "唐揚げ",
          quantity: 1,
          unitPrice: 450,
          subtotal: 450,
        ),
        OrderItemViewData(
          menuItemId: "5",
          menuItemName: "焼きおにぎり",
          quantity: 1,
          unitPrice: 250,
          subtotal: 250,
        ),
      ];

      expect(orderHistoryItemsSummary(items), "焼き鳥, ビール, 枝豆, 他2件");
    });
  });
}
