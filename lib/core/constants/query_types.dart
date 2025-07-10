import "package:supabase_flutter/supabase_flutter.dart";

/// フィルタ演算子
enum FilterOperator {
  /// 等しい
  eq,

  /// 不等
  neq,

  /// 超過
  gt,

  /// 以上
  gte,

  /// 未満
  lt,

  /// 以下
  lte,

  /// 部分一致（大文字小文字区別）
  like,

  /// 部分一致（大文字小文字区別なし）
  ilike,

  /// NULLか？
  isNull,

  /// NULLでないか？
  isNotNull,

  /// 配列の要素に含まれる
  inList,

  /// 配列の要素に含まれない
  notInList,

  /// 配列・JSON内の値を含む
  contains,

  /// 配列・JSON内の値に含まれる
  containedBy,

  /// 範囲内（より大きい）
  rangeGt,

  /// 範囲内（以上）
  rangeGte,

  /// 範囲内（より小さい）
  rangeLt,

  /// 範囲内（以下）
  rangeLte,

  /// 重複する
  overlaps,
}

enum LogicalOperator {
  /// AND
  and,

  /// OR
  or,
}

abstract class LogicalCondition extends QueryFilter {
  const LogicalCondition() : super();

  List<QueryFilter> get conditions;

  LogicalOperator get operator;
}

class AndCondition extends LogicalCondition {
  const AndCondition(this.conditions);

  @override
  final List<QueryFilter> conditions;

  @override
  LogicalOperator get operator => LogicalOperator.and;
}

class OrCondition extends LogicalCondition {
  const OrCondition(this.conditions);

  @override
  final List<QueryFilter> conditions;

  @override
  LogicalOperator get operator => LogicalOperator.or;
}

// 複合条件
class ComplexCondition extends LogicalCondition {
  const ComplexCondition({required this.operator, required this.conditions});

  @override
  final LogicalOperator operator;

  @override
  final List<QueryFilter> conditions;
}

class OrderByCondition {
  const OrderByCondition({required this.column, this.ascending = true});

  final String column;

  // 昇順か? デフォルト:true
  final bool ascending;
}

// クエリ条件の統合型
abstract class QueryFilter {
  const QueryFilter();
}

// FilterConditionをQueryFilterとして拡張
class FilterCondition extends QueryFilter {
  const FilterCondition({required this.column, required this.operator, required this.value})
    : super();

  final String column;

  final FilterOperator operator;

  final dynamic value;

  // 値が有効かどうかをチェック
  bool get isValidValue {
    switch (operator) {
      case FilterOperator.isNull:
      case FilterOperator.isNotNull:
        return true;
      case FilterOperator.inList:
      case FilterOperator.notInList:
        return value is List<dynamic> && (value as List<dynamic>).isNotEmpty;
      case FilterOperator.like:
      case FilterOperator.ilike:
        return value is String && (value as String).isNotEmpty;
      case FilterOperator.eq:
      case FilterOperator.neq:
      case FilterOperator.gt:
      case FilterOperator.gte:
      case FilterOperator.lt:
      case FilterOperator.lte:
      case FilterOperator.contains:
      case FilterOperator.containedBy:
      case FilterOperator.rangeGt:
      case FilterOperator.rangeGte:
      case FilterOperator.rangeLt:
      case FilterOperator.rangeLte:
      case FilterOperator.overlaps:
        return value != null;
    }
  }

  // 文字列表現
  String get description => "$column ${operator.name} $value";
}

/// 高度なクエリ構築ヘルパー
class QueryConditionBuilder {
  QueryConditionBuilder._();

  static FilterCondition eq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.eq, value: value);

  static FilterCondition neq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.neq, value: value);

  static FilterCondition gt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gt, value: value);

  static FilterCondition gte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gte, value: value);

  static FilterCondition lt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lt, value: value);

  static FilterCondition lte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lte, value: value);

  static FilterCondition like(String column, String pattern) =>
      FilterCondition(column: column, operator: FilterOperator.like, value: pattern);

  static FilterCondition ilike(String column, String pattern) =>
      FilterCondition(column: column, operator: FilterOperator.ilike, value: pattern);

  static FilterCondition inList(String column, List<dynamic> values) =>
      FilterCondition(column: column, operator: FilterOperator.inList, value: values);

  static FilterCondition notInList(String column, List<dynamic> values) =>
      FilterCondition(column: column, operator: FilterOperator.notInList, value: values);

  static FilterCondition isNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNull, value: null);

  static FilterCondition isNotNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNotNull, value: null);

  static FilterCondition contains(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.contains, value: value);

  static FilterCondition containedBy(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.containedBy, value: value);

  static FilterCondition rangeGt(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeGt, value: range);

  static FilterCondition rangeGte(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeGte, value: range);

  static FilterCondition rangeLt(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeLt, value: range);

  static FilterCondition rangeLte(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeLte, value: range);

  static FilterCondition overlaps(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.overlaps, value: value);

  static AndCondition and(List<QueryFilter> conditions) => AndCondition(conditions);

  static OrCondition or(List<QueryFilter> conditions) => OrCondition(conditions);

  // 複合条件を作成
  static ComplexCondition complex(LogicalOperator operator, List<QueryFilter> conditions) =>
      ComplexCondition(operator: operator, conditions: conditions);

  // 日付範囲条件を作成
  static AndCondition dateRange(String column, DateTime from, DateTime to) =>
      and(<QueryFilter>[gte(column, from.toIso8601String()), lte(column, to.toIso8601String())]);

  // 検索条件を作成
  static FilterCondition search(String column, String term, {bool caseSensitive = false}) =>
      caseSensitive ? like(column, "%$term%") : ilike(column, "%$term%");

  // 数値範囲条件を作成
  static AndCondition numberRange(String column, num min, num max) =>
      and(<QueryFilter>[gte(column, min), lte(column, max)]);

  // 複数の条件をORで結合
  static OrCondition anyOf(List<QueryFilter> conditions) => or(conditions);

  // 複数の条件をANDで結合
  static AndCondition allOf(List<QueryFilter> conditions) => and(conditions);
}

// クエリビルダ用のエイリアス
typedef QueryBuilder = PostgrestTransformBuilder<List<Map<String, dynamic>>>;

// フィルタビルダ用のタイプエイリアス
typedef FilterBuilder = PostgrestFilterBuilder<dynamic>;
