import "package:supabase_flutter/supabase_flutter.dart";

/// フィルタ演算子
enum FilterOperator {
  /// 等しい
  eq,

  /// 等しくない
  neq,

  /// より大きい
  gt,

  /// 以上
  gte,

  /// より小さい
  lt,

  /// 以下
  lte,

  /// 部分一致（大文字小文字区別）
  like,

  /// 部分一致（大文字小文字区別なし）
  ilike,

  /// NULL判定
  isNull,

  /// NULL以外判定
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


/// 論理演算子
enum LogicalOperator {
  /// AND
  and,

  /// OR
  or,
}

/// ベース論理条件抽象クラス
abstract class LogicalCondition extends QueryFilter {
  /// コンストラクタ
  const LogicalCondition() : super();

  /// 条件リストを取得
  List<QueryFilter> get conditions;

  /// 論理演算子を取得
  LogicalOperator get operator;
}

/// AND条件
class AndCondition extends LogicalCondition {
  /// コンストラクタ
  const AndCondition(this.conditions);

  @override
  final List<QueryFilter> conditions;

  @override
  LogicalOperator get operator => LogicalOperator.and;
}

/// OR条件
class OrCondition extends LogicalCondition {
  /// コンストラクタ
  const OrCondition(this.conditions);

  @override
  final List<QueryFilter> conditions;

  @override
  LogicalOperator get operator => LogicalOperator.or;
}

/// 複合論理条件（AND/ORの組み合わせ）
class ComplexCondition extends LogicalCondition {
  /// コンストラクタ
  const ComplexCondition({
    required this.operator,
    required this.conditions,
  });

  @override
  final LogicalOperator operator;

  @override
  final List<QueryFilter> conditions;
}

/// ソート条件
class OrderByCondition {
  /// コンストラクタ
  const OrderByCondition({required this.column, this.ascending = true});

  /// カラム名
  final String column;

  /// 昇順かどうか（デフォルト: true）
  final bool ascending;
}

/// クエリ条件の統合型（型安全性向上）
abstract class QueryFilter {
  const QueryFilter();
}

/// FilterConditionをQueryFilterとして拡張
class FilterCondition extends QueryFilter {
  /// コンストラクタ
  const FilterCondition({
    required this.column,
    required this.operator,
    required this.value,
  }) : super();

  /// カラム名
  final String column;

  /// 演算子
  final FilterOperator operator;

  /// 値
  final dynamic value;

  /// 値が有効かどうかをチェック
  bool get isValidValue {
    switch (operator) {
      case FilterOperator.isNull:
      case FilterOperator.isNotNull:
        return true;
      case FilterOperator.inList:
      case FilterOperator.notInList:
        return value is List && (value as List).isNotEmpty;
      case FilterOperator.like:
      case FilterOperator.ilike:
        return value is String && (value as String).isNotEmpty;
      default:
        return value != null;
    }
  }

  /// 条件の文字列表現
  String get description {
    return "$column ${operator.name} $value";
  }
}

/// 高度なクエリ構築ヘルパー
class QueryConditionBuilder {
  QueryConditionBuilder._();

  /// 等価条件を作成
  static FilterCondition eq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.eq, value: value);

  /// 不等価条件を作成
  static FilterCondition neq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.neq, value: value);

  /// より大きい条件を作成
  static FilterCondition gt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gt, value: value);

  /// 以上条件を作成
  static FilterCondition gte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gte, value: value);

  /// より小さい条件を作成
  static FilterCondition lt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lt, value: value);

  /// 以下条件を作成
  static FilterCondition lte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lte, value: value);

  /// LIKE条件を作成
  static FilterCondition like(String column, String pattern) =>
      FilterCondition(column: column, operator: FilterOperator.like, value: pattern);

  /// ILIKE条件を作成
  static FilterCondition ilike(String column, String pattern) =>
      FilterCondition(column: column, operator: FilterOperator.ilike, value: pattern);

  /// IN条件を作成
  static FilterCondition inList(String column, List<dynamic> values) =>
      FilterCondition(column: column, operator: FilterOperator.inList, value: values);

  /// NOT IN条件を作成
  static FilterCondition notInList(String column, List<dynamic> values) =>
      FilterCondition(column: column, operator: FilterOperator.notInList, value: values);

  /// NULL判定条件を作成
  static FilterCondition isNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNull, value: null);

  /// NOT NULL判定条件を作成
  static FilterCondition isNotNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNotNull, value: null);

  /// CONTAINS条件を作成
  static FilterCondition contains(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.contains, value: value);

  /// CONTAINED BY条件を作成
  static FilterCondition containedBy(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.containedBy, value: value);

  /// 範囲条件を作成（より大きい）
  static FilterCondition rangeGt(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeGt, value: range);

  /// 範囲条件を作成（以上）
  static FilterCondition rangeGte(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeGte, value: range);

  /// 範囲条件を作成（より小さい）
  static FilterCondition rangeLt(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeLt, value: range);

  /// 範囲条件を作成（以下）
  static FilterCondition rangeLte(String column, String range) =>
      FilterCondition(column: column, operator: FilterOperator.rangeLte, value: range);

  /// OVERLAPS条件を作成
  static FilterCondition overlaps(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.overlaps, value: value);

  /// AND条件を作成
  static AndCondition and(List<QueryFilter> conditions) =>
      AndCondition(conditions);

  /// OR条件を作成
  static OrCondition or(List<QueryFilter> conditions) =>
      OrCondition(conditions);

  /// 複合条件を作成
  static ComplexCondition complex(LogicalOperator operator, List<QueryFilter> conditions) =>
      ComplexCondition(operator: operator, conditions: conditions);

  /// 日付範囲条件を作成（便利メソッド）
  static AndCondition dateRange(String column, DateTime from, DateTime to) =>
      and(<QueryFilter>[
        gte(column, from.toIso8601String()),
        lte(column, to.toIso8601String()),
      ]);

  /// 文字列部分一致条件を作成（便利メソッド）
  static FilterCondition search(String column, String term, {bool caseSensitive = false}) =>
      caseSensitive
          ? like(column, "%$term%")
          : ilike(column, "%$term%");

  /// 数値範囲条件を作成（便利メソッド）
  static AndCondition numberRange(String column, num min, num max) =>
      and(<QueryFilter>[
        gte(column, min),
        lte(column, max),
      ]);

  /// 複数条件のOR組み合わせ（便利メソッド）
  static OrCondition anyOf(List<QueryFilter> conditions) =>
      or(conditions);

  /// 複数条件のAND組み合わせ（便利メソッド）
  static AndCondition allOf(List<QueryFilter> conditions) =>
      and(conditions);
}

/// クエリビルダー拡張のためのタイプエイリアス
typedef QueryBuilder = PostgrestTransformBuilder<List<Map<String, dynamic>>>;

/// フィルタビルダー拡張のためのタイプエイリアス
typedef FilterBuilder = PostgrestFilterBuilder<dynamic>;
