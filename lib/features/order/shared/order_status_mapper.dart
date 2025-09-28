import "package:flutter/foundation.dart";

import "../../../core/constants/enums.dart";

/// 旧ステータス値を新しい3状態へ集約・変換するユーティリティ。
class OrderStatusMapper {
  OrderStatusMapper._();

  static final Set<String> _unsupportedBackendValues = <String>{};

  /// ステータス文字列を新しい [OrderStatus] に変換する。
  static OrderStatus fromJson(Object? raw) {
    if (raw == null) {
      return OrderStatus.inProgress;
    }

    final String key = raw.toString().trim().toLowerCase();
    final OrderStatus? mapped = _stringToStatus[key];
    return mapped ?? OrderStatus.inProgress;
  }

  /// [OrderStatus] をAPI保存用の文字列に変換する。
  static String toJson(OrderStatus status) => status.primaryStatus.value;

  /// バックエンドでサポートされていないステータス値を登録する。
  static void markBackendValueUnsupported(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      _unsupportedBackendValues.add(normalized);
    }
  }

  /// 現在の互換設定をリセット（主にテスト用）。
  @visibleForTesting
  static void resetBackendCompatibility() {
    _unsupportedBackendValues.clear();
  }

  /// レガシー状態を含む [OrderStatus] を新しい状態へ正規化する。
  static OrderStatus normalize(OrderStatus status) => status.primaryStatus;

  /// レガシー状態を含むリストを正規化し、重複を除いた一覧を返す。
  static List<OrderStatus> normalizeList(Iterable<OrderStatus> statuses) =>
      statuses.map<OrderStatus>(normalize).toSet().toList(growable: false);

  /// クエリ用の文字列一覧を取得する。
  static List<String> queryValues(OrderStatus status) {
    final List<String> values = _statusToQueryValues[normalize(status)] ?? <String>[toJson(status)];
    final List<String> filtered = values
        .where((String value) => !_unsupportedBackendValues.contains(value.trim().toLowerCase()))
        .toList(growable: false);

    if (filtered.isNotEmpty) {
      return List<String>.unmodifiable(filtered);
    }

    return List<String>.unmodifiable(values);
  }

  /// 複数ステータスをまとめてクエリ文字列一覧に変換する。
  static List<String> queryValuesFromList(Iterable<OrderStatus> statuses) => statuses
      .expand<String>((OrderStatus status) => queryValues(status))
      .toSet()
      .toList(growable: false);

  /// レガシー環境用に互換値リストを返す。
  static List<String> legacyQueryValues(OrderStatus status) => List<String>.unmodifiable(
    _legacyStatusToQueryValues[normalize(status)] ?? <String>[toJson(status)],
  );

  /// 新しい状態セット全体を返す。
  static const List<OrderStatus> primaryStatuses = OrderStatus.primaryStatuses;

  static const Map<String, OrderStatus> _stringToStatus = <String, OrderStatus>{
    "in_progress": OrderStatus.inProgress,
    "inprogress": OrderStatus.inProgress,
    "pending": OrderStatus.inProgress,
    "confirmed": OrderStatus.inProgress,
    "preparing": OrderStatus.inProgress,
    "ready": OrderStatus.inProgress,
    "cancelled": OrderStatus.cancelled,
    "canceled": OrderStatus.cancelled,
    "refunded": OrderStatus.cancelled,
    "completed": OrderStatus.completed,
    "delivered": OrderStatus.completed,
  };

  static const Map<OrderStatus, List<String>> _statusToQueryValues = <OrderStatus, List<String>>{
    OrderStatus.inProgress: <String>["in_progress", "pending", "confirmed", "preparing", "ready"],
    OrderStatus.completed: <String>["completed", "delivered"],
    OrderStatus.cancelled: <String>["cancelled", "canceled", "refunded"],
  };

  static const Map<OrderStatus, List<String>> _legacyStatusToQueryValues =
      <OrderStatus, List<String>>{
        OrderStatus.inProgress: <String>["pending", "confirmed", "preparing", "ready"],
        OrderStatus.completed: <String>["completed", "delivered"],
        OrderStatus.cancelled: <String>["cancelled", "canceled", "refunded"],
      };
}
