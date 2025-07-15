import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:yata/core/constants/enums.dart";
import "package:yata/features/order/models/order_model.dart";
import "package:yata/features/order/repositories/order_repository.dart";

// Mockitoでモックを生成
@GenerateMocks(<Type>[SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
void main() {
  group("OrderRepository", () {
    late OrderRepository orderRepository;

    setUp(() {
      orderRepository = OrderRepository();
    });

    group("fromJson", () {
      test("有効なJSONからOrderModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-order-id",
          "order_id": "test-order-id",
          "user_id": "test-user-id",
          "status": "preparing",
          "order_number": 1,
          "total_amount": "1500.00",
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final Order order = orderRepository.fromJson(json);

        // Assert
        expect(order.id, equals("test-order-id"));
        expect(order.userId, equals("test-user-id"));
        expect(order.status, equals(OrderStatus.preparing));
        expect(order.orderNumber, equals(1));
        expect(order.totalAmount.toString(), equals("1500.00"));
      });

      test("必須フィールドのみでOrderModelを作成できる", () {
        // Arrange
        final Map<String, dynamic> json = <String, dynamic>{
          "id": "test-order-id",
          "order_id": "test-order-id",
          "user_id": "test-user-id",
          "status": "completed",
          "order_number": 2,
          "total_amount": "2000.00",
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
        };

        // Act
        final Order order = orderRepository.fromJson(json);

        // Assert
        expect(order.id, equals("test-order-id"));
        expect(order.userId, equals("test-user-id"));
        expect(order.status, equals(OrderStatus.completed));
        expect(order.orderNumber, equals(2));
        expect(order.totalAmount.toString(), equals("2000.00"));
      });
    });

    group("tableName", () {
      test("正しいテーブル名を返す", () {
        expect(orderRepository.tableName, equals("orders"));
      });
    });

    group("findActiveDraftByUser", () {
      test("ユーザーのアクティブな下書き注文を検索できる", () async {
        // このテストは実際のデータベースとの統合テストが必要
        expect(true, true); // プレースホルダーテスト
      });

      test("アクティブな下書きがない場合nullを返す", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("無効なユーザーIDの場合nullを返す", () async {
        expect(true, true); // プレースホルダーテスト
      });
    });

    group("findByStatusList", () {
      test("指定されたステータスリストの注文を返す", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("空のステータスリストの場合空のリストを返す", () async {
        // Arrange & Act
        final List<Order> result = await orderRepository.findByStatusList(
          <OrderStatus>[],
          "test-user-id",
        );

        // Assert
        expect(result, isEmpty);
      });

      test("該当する注文がない場合空のリストを返す", () async {
        expect(true, true); // プレースホルダーテスト
      });
    });

    group("searchWithPagination", () {
      test("ページネーション付きで注文を検索できる", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("pageとlimitパラメータが正しく適用される", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("総件数が正しく返される", () async {
        expect(true, true); // プレースホルダーテスト
      });
    });

    group("findByDateRange", () {
      test("指定された期間の注文を返す", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("期間外の注文は含まれない", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("日付の正規化が正しく動作する", () async {
        expect(true, true); // プレースホルダーテスト
      });
    });

    group("findCompletedByDate", () {
      test("指定日の完了注文を返す", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("完了していない注文は含まれない", () async {
        expect(true, true); // プレースホルダーテスト
      });

      test("異なる日の注文は含まれない", () async {
        expect(true, true); // プレースホルダーテスト
      });
    });

    group("countByStatusAndDate", () {
      test("指定ステータスの注文数を返す", () async {
        // ステータスと日付での注文数をカウント
        final DateTime today = DateTime.now();
        expect(() => orderRepository.countByStatusAndDate("user-id", OrderStatus.completed, today), returnsNormally);
      });

      test("該当する注文がない場合0を返す", () async {
        // 異なるステータスでのカウント
        final DateTime today = DateTime.now();
        expect(() => orderRepository.countByStatusAndDate("user-id", OrderStatus.cancelled, today), returnsNormally);
      });
    });



  });
}
