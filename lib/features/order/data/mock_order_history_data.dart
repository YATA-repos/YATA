import "../../../core/constants/enums.dart";
import "../../menu/models/menu_model.dart";
import "../models/order_model.dart";

/// 注文履歴画面用のモックデータ
abstract class MockOrderHistoryData {
  /// メニューのモックデータ
  static final List<MenuItem> mockMenuItems = [
    MenuItem(
      id: "menu_1",
      name: "唐揚げ定食",
      price: 850,
      categoryId: "main",
      isAvailable: true,
      estimatedPrepTimeMinutes: 15,
      displayOrder: 1,
      description: "人気No.1の定食",
      userId: "user_1",
    ),
    MenuItem(
      id: "menu_2",
      name: "焼き魚定食",
      price: 900,
      categoryId: "main",
      isAvailable: true,
      estimatedPrepTimeMinutes: 20,
      displayOrder: 2,
      description: "新鮮な魚を使用",
      userId: "user_1",
    ),
    MenuItem(
      id: "menu_3",
      name: "生ビール",
      price: 450,
      categoryId: "drink",
      isAvailable: true,
      estimatedPrepTimeMinutes: 2,
      displayOrder: 1,
      description: "キンキンに冷えたビール",
      userId: "user_1",
    ),
    MenuItem(
      id: "menu_4",
      name: "餃子",
      price: 380,
      categoryId: "side",
      isAvailable: true,
      estimatedPrepTimeMinutes: 10,
      displayOrder: 1,
      description: "手作り餃子",
      userId: "user_1",
    ),
    MenuItem(
      id: "menu_5",
      name: "ラーメン",
      price: 680,
      categoryId: "main",
      isAvailable: true,
      estimatedPrepTimeMinutes: 12,
      displayOrder: 3,
      description: "醤油ベースのラーメン",
      userId: "user_1",
    ),
  ];

  /// 注文履歴のモックデータ
  static final List<Order> mockOrderHistory = [
    Order(
      id: "order_1",
      orderNumber: "2024-001",
      totalAmount: 1330,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 0,
      customerName: "田中様",
      notes: "テイクアウト",
      orderedAt: DateTime.now().subtract(const Duration(hours: 2)),
      startedPreparingAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      readyAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 35)),
      completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      userId: "user_1",
    ),
    Order(
      id: "order_2",
      orderNumber: "2024-002",
      totalAmount: 900,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.card,
      discountAmount: 0,
      customerName: "佐藤様",
      notes: "店内飲食",
      orderedAt: DateTime.now().subtract(const Duration(hours: 3)),
      startedPreparingAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      readyAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      completedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 25)),
      userId: "user_1",
    ),
    Order(
      id: "order_3",
      orderNumber: "2024-003",
      totalAmount: 1680,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 100,
      customerName: "山田様",
      notes: "辛さ控えめ",
      orderedAt: DateTime.now().subtract(const Duration(hours: 4)),
      startedPreparingAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 50)),
      readyAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 35)),
      completedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
      userId: "user_1",
    ),
    Order(
      id: "order_4",
      orderNumber: "2024-004",
      totalAmount: 450,
      status: OrderStatus.cancelled,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 0,
      customerName: "鈴木様",
      notes: "キャンセル済み",
      orderedAt: DateTime.now().subtract(const Duration(hours: 5)),
      userId: "user_1",
    ),
    Order(
      id: "order_5",
      orderNumber: "2024-005",
      totalAmount: 2180,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.other,
      discountAmount: 0,
      customerName: "高橋様",
      notes: "大人数用",
      orderedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      startedPreparingAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
      readyAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
      completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 25)),
      userId: "user_1",
    ),
    Order(
      id: "order_6",
      orderNumber: "2024-006",
      totalAmount: 1130,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.card,
      discountAmount: 50,
      customerName: "伊藤様",
      notes: "お急ぎ",
      orderedAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      startedPreparingAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 50)),
      readyAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 40)),
      completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 35)),
      userId: "user_1",
    ),
    Order(
      id: "order_7",
      orderNumber: "2024-007",
      totalAmount: 680,
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      discountAmount: 0,
      customerName: "渡辺様",
      notes: "持ち帰り",
      orderedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      startedPreparingAt: DateTime.now().subtract(const Duration(days: 2, hours: 0, minutes: 50)),
      readyAt: DateTime.now().subtract(const Duration(days: 2, hours: 0, minutes: 40)),
      completedAt: DateTime.now().subtract(const Duration(days: 2, hours: 0, minutes: 35)),
      userId: "user_1",
    ),
  ];

  /// 注文明細のモックデータ
  static final Map<String, List<OrderItem>> mockOrderItems = {
    "order_1": [
      OrderItem(
        id: "item_1_1",
        orderId: "order_1",
        menuItemId: "menu_1",
        quantity: 1,
        unitPrice: 850,
        subtotal: 850,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_1_2",
        orderId: "order_1",
        menuItemId: "menu_4",
        quantity: 1,
        unitPrice: 380,
        subtotal: 380,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_1_3",
        orderId: "order_1",
        menuItemId: "menu_3",
        quantity: 1,
        unitPrice: 450,
        subtotal: 450,
        userId: "user_1",
      ),
    ],
    "order_2": [
      OrderItem(
        id: "item_2_1",
        orderId: "order_2",
        menuItemId: "menu_2",
        quantity: 1,
        unitPrice: 900,
        subtotal: 900,
        userId: "user_1",
      ),
    ],
    "order_3": [
      OrderItem(
        id: "item_3_1",
        orderId: "order_3",
        menuItemId: "menu_5",
        quantity: 2,
        unitPrice: 680,
        subtotal: 1360,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_3_2",
        orderId: "order_3",
        menuItemId: "menu_4",
        quantity: 1,
        unitPrice: 380,
        subtotal: 380,
        userId: "user_1",
      ),
    ],
    "order_4": [
      OrderItem(
        id: "item_4_1",
        orderId: "order_4",
        menuItemId: "menu_3",
        quantity: 1,
        unitPrice: 450,
        subtotal: 450,
        userId: "user_1",
      ),
    ],
    "order_5": [
      OrderItem(
        id: "item_5_1",
        orderId: "order_5",
        menuItemId: "menu_1",
        quantity: 2,
        unitPrice: 850,
        subtotal: 1700,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_5_2",
        orderId: "order_5",
        menuItemId: "menu_4",
        quantity: 1,
        unitPrice: 380,
        subtotal: 380,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_5_3",
        orderId: "order_5",
        menuItemId: "menu_3",
        quantity: 1,
        unitPrice: 450,
        subtotal: 450,
        userId: "user_1",
      ),
    ],
    "order_6": [
      OrderItem(
        id: "item_6_1",
        orderId: "order_6",
        menuItemId: "menu_1",
        quantity: 1,
        unitPrice: 850,
        subtotal: 850,
        userId: "user_1",
      ),
      OrderItem(
        id: "item_6_2",
        orderId: "order_6",
        menuItemId: "menu_4",
        quantity: 1,
        unitPrice: 380,
        subtotal: 380,
        userId: "user_1",
      ),
    ],
    "order_7": [
      OrderItem(
        id: "item_7_1",
        orderId: "order_7",
        menuItemId: "menu_5",
        quantity: 1,
        unitPrice: 680,
        subtotal: 680,
        userId: "user_1",
      ),
    ],
  };

  /// メニューIDから名前を取得
  static String getMenuItemName(String menuItemId) {
    final MenuItem? item = mockMenuItems.cast<MenuItem?>().firstWhere(
      (MenuItem? item) => item?.id == menuItemId,
      orElse: () => null,
    );
    return item?.name ?? "不明な商品";
  }

  /// 注文IDから注文明細を取得
  static List<OrderItem> getOrderItems(String orderId) {
    return mockOrderItems[orderId] ?? <OrderItem>[];
  }

  /// 統計情報
  static Map<String, dynamic> get statistics {
    final int totalOrders = mockOrderHistory.length;
    final int completedOrders = mockOrderHistory.where((Order order) => order.status == OrderStatus.completed).length;
    final int cancelledOrders = mockOrderHistory.where((Order order) => order.status == OrderStatus.cancelled).length;
    final int totalRevenue = mockOrderHistory
        .where((Order order) => order.status == OrderStatus.completed)
        .fold(0, (int sum, Order order) => sum + order.totalAmount);

    return <String, dynamic>{
      "totalOrders": totalOrders,
      "completedOrders": completedOrders,
      "cancelledOrders": cancelledOrders,
      "totalRevenue": totalRevenue,
      "averageOrderValue": completedOrders > 0 ? (totalRevenue / completedOrders).floor() : 0,
    };
  }
}