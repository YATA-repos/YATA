import "package:supabase_flutter/supabase_flutter.dart";
import "../constants/query_types.dart";
import "log_service.dart";

/// クエリユーティリティクラス
class QueryUtils {
  QueryUtils._();

  /// フィルタ演算子をSupabaseメソッド名にマッピング
  static const Map<FilterOperator, String> _operatorMethodMap = <FilterOperator, String>{
    FilterOperator.eq: "eq",
    FilterOperator.neq: "neq",
    FilterOperator.gt: "gt",
    FilterOperator.gte: "gte",
    FilterOperator.lt: "lt",
    FilterOperator.lte: "lte",
    FilterOperator.like: "like",
    FilterOperator.ilike: "ilike",
    FilterOperator.isNull: "is",
    FilterOperator.isNotNull: "not.is",
    FilterOperator.inList: "in",
    FilterOperator.notInList: "not.in",
    FilterOperator.contains: "contains",
    FilterOperator.containedBy: "containedBy",
    FilterOperator.rangeGt: "rangeGt",
    FilterOperator.rangeGte: "rangeGte",
    FilterOperator.rangeLt: "rangeLt",
    FilterOperator.rangeLte: "rangeLte",
    FilterOperator.overlaps: "overlaps",
  };

  /// 単一フィルタ条件をクエリに適用
  static PostgrestFilterBuilder<dynamic> _applySingleFilter(
    PostgrestFilterBuilder<dynamic> query,
    FilterCondition condition,
  ) {
    // 演算子の確認
    if (!_operatorMethodMap.containsKey(condition.operator)) {
      LogService.error("QueryUtils", "Unsupported operator: ${condition.operator}");
      throw ArgumentError("サポートされていない演算子: ${condition.operator}");
    }

    LogService.debug(
      "QueryUtils",
      "Applying filter: ${condition.column} ${condition.operator} ${condition.value}",
    );

    // NULL判定の特別処理
    if (condition.operator == FilterOperator.isNull) {
      return query.isFilter(condition.column, null);
    }
    if (condition.operator == FilterOperator.isNotNull) {
      return query.not(condition.column, "is", null);
    }

    // リスト系演算子の処理
    if (condition.operator == FilterOperator.inList ||
        condition.operator == FilterOperator.notInList) {
      if (condition.value is! List) {
        LogService.error(
          "QueryUtils",
          "List type value required for ${condition.operator} operator",
        );
        throw ArgumentError("${condition.operator}演算子にはList型の値が必要です");
      }
      final List<dynamic> values = condition.value as List<dynamic>;

      if (condition.operator == FilterOperator.inList) {
        return query.inFilter(condition.column, values);
      } else {
        return query.not(condition.column, "in", values);
      }
    }

    // 通常の演算子処理
    switch (condition.operator) {
      case FilterOperator.eq:
        return query.eq(condition.column, condition.value as Object);
      case FilterOperator.neq:
        return query.neq(condition.column, condition.value as Object);
      case FilterOperator.gt:
        return query.gt(condition.column, condition.value as Object);
      case FilterOperator.gte:
        return query.gte(condition.column, condition.value as Object);
      case FilterOperator.lt:
        return query.lt(condition.column, condition.value as Object);
      case FilterOperator.lte:
        return query.lte(condition.column, condition.value as Object);
      case FilterOperator.like:
        return query.like(condition.column, condition.value as String);
      case FilterOperator.ilike:
        return query.ilike(condition.column, condition.value as String);
      case FilterOperator.contains:
        return query.contains(condition.column, condition.value as Object);
      case FilterOperator.containedBy:
        return query.containedBy(condition.column, condition.value as Object);
      case FilterOperator.rangeGt:
        return query.rangeGt(condition.column, condition.value as String);
      case FilterOperator.rangeGte:
        return query.rangeGte(condition.column, condition.value as String);
      case FilterOperator.rangeLt:
        return query.rangeLt(condition.column, condition.value as String);
      case FilterOperator.rangeLte:
        return query.rangeLte(condition.column, condition.value as String);
      case FilterOperator.overlaps:
        return query.overlaps(condition.column, condition.value as Object);
      case FilterOperator.isNull:
      case FilterOperator.isNotNull:
      case FilterOperator.inList:
      case FilterOperator.notInList:
        // これらは上記で処理済み
        LogService.error(
          "QueryUtils",
          "This operator should be handled in preprocessing: ${condition.operator}",
        );
        throw ArgumentError("この演算子は事前処理で処理される必要があります: ${condition.operator}");
    }
  }

  /// OR条件用のクエリ文字列を構築
  static String _buildOrConditionString(List<FilterCondition> conditions) {
    final List<String> orParts = <String>[];

    for (final FilterCondition condition in conditions) {
      if (!_operatorMethodMap.containsKey(condition.operator)) {
        LogService.error(
          "QueryUtils",
          "Unsupported operator in OR condition: ${condition.operator}",
          "OR条件でサポートされていない演算子: ${condition.operator}",
        );
        throw ArgumentError("サポートされていない演算子: ${condition.operator}");
      }
      final String methodName = _operatorMethodMap[condition.operator]!;

      if (condition.operator == FilterOperator.isNull) {
        orParts.add("${condition.column}.is.null");
      } else if (condition.operator == FilterOperator.isNotNull) {
        orParts.add("${condition.column}.not.is.null");
      } else if (condition.operator == FilterOperator.inList) {
        if (condition.value is! List) {
          LogService.error(
            "QueryUtils",
            "List type value required for inList operator",
            "inList演算子にはList型の値が必要です",
          );
          throw ArgumentError("inList演算子にはList型の値が必要です");
        }
        final List<dynamic> values = condition.value as List<dynamic>;
        final String valueStr = values.join(",");
        orParts.add("${condition.column}.in.($valueStr)");
      } else if (condition.operator == FilterOperator.notInList) {
        if (condition.value is! List) {
          LogService.error(
            "QueryUtils",
            "List type value required for notInList operator",
            "notInList演算子にはList型の値が必要です",
          );
          throw ArgumentError("notInList演算子にはList型の値が必要です");
        }
        final List<dynamic> values = condition.value as List<dynamic>;
        final String valueStr = values.join(",");
        orParts.add("${condition.column}.not.in.($valueStr)");
      } else {
        orParts.add("${condition.column}.$methodName.${condition.value}");
      }
    }

    return orParts.join(",");
  }

  /// 論理条件をクエリに適用（階層化対応）
  static PostgrestFilterBuilder<dynamic> _applyLogicalCondition(
    PostgrestFilterBuilder<dynamic> query,
    LogicalCondition condition,
  ) {
    if (condition is AndCondition) {
      return _applyAndCondition(query, condition);
    } else if (condition is OrCondition) {
      return _applyOrCondition(query, condition);
    } else if (condition is ComplexCondition) {
      return _applyComplexCondition(query, condition);
    } else {
      LogService.error(
        "QueryUtils",
        "Unknown logical condition type: ${condition.runtimeType}",
        "不明な論理条件タイプ: ${condition.runtimeType}",
      );
      throw ArgumentError("不明な論理条件タイプ: ${condition.runtimeType}");
    }
  }

  /// AND条件を適用
  static PostgrestFilterBuilder<dynamic> _applyAndCondition(
    PostgrestFilterBuilder<dynamic> query,
    AndCondition condition,
  ) {
    PostgrestFilterBuilder<dynamic> result = query;
    for (final QueryFilter cond in condition.conditions) {
      result = applyFilter(result, cond);
    }
    return result;
  }

  /// OR条件を適用
  static PostgrestFilterBuilder<dynamic> _applyOrCondition(
    PostgrestFilterBuilder<dynamic> query,
    OrCondition condition,
  ) {
    final List<FilterCondition> filterConditions = <FilterCondition>[];

    for (final QueryFilter cond in condition.conditions) {
      if (cond is FilterCondition) {
        filterConditions.add(cond);
      } else if (cond is AndCondition) {
        // ネストしたAND条件をフラット化
        for (final QueryFilter innerCond in cond.conditions) {
          if (innerCond is FilterCondition) {
            filterConditions.add(innerCond);
          }
        }
      } else {
        LogService.error(
          "QueryUtils",
          "Unsupported condition type in OR: ${cond.runtimeType}",
          "OR条件内でサポートされていない条件タイプ: ${cond.runtimeType}",
        );
        throw ArgumentError("OR条件内でサポートされていない条件タイプ: ${cond.runtimeType}");
      }
    }

    if (filterConditions.isEmpty) {
      return query;
    }

    final String orString = _buildOrConditionString(filterConditions);
    LogService.debug("QueryUtils", "Applying OR condition: $orString");
    return query.or(orString);
  }

  /// 複合条件を適用
  static PostgrestFilterBuilder<dynamic> _applyComplexCondition(
    PostgrestFilterBuilder<dynamic> query,
    ComplexCondition condition,
  ) {
    if (condition.operator == LogicalOperator.and) {
      return _applyAndCondition(query, AndCondition(condition.conditions));
    } else {
      return _applyOrCondition(query, OrCondition(condition.conditions));
    }
  }

  /// フィルタ条件をクエリに適用
  static PostgrestFilterBuilder<dynamic> applyFilter(
    PostgrestFilterBuilder<dynamic> query,
    QueryFilter filter,
  ) {
    if (filter is FilterCondition) {
      return _applySingleFilter(query, filter);
    } else if (filter is LogicalCondition) {
      return _applyLogicalCondition(query, filter);
    } else {
      LogService.error(
        "QueryUtils",
        "Unsupported filter type: ${filter.runtimeType}",
        "サポートされていないフィルタタイプ: ${filter.runtimeType}",
      );
      throw ArgumentError("サポートされていないフィルタタイプ: ${filter.runtimeType}");
    }
  }

  /// 複数のフィルタ条件をクエリに適用（AND結合）
  static PostgrestFilterBuilder<dynamic> applyFilters(
    PostgrestFilterBuilder<dynamic> query,
    List<QueryFilter> filters,
  ) {
    LogService.debug("QueryUtils", "Applying ${filters.length} filters with AND combination");
    PostgrestFilterBuilder<dynamic> result = query;
    for (final QueryFilter filter in filters) {
      result = applyFilter(result, filter);
    }
    return result;
  }

  /// ソート条件をクエリに適用
  static PostgrestTransformBuilder<List<Map<String, dynamic>>> applyOrderBy(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> query,
    OrderByCondition orderBy,
  ) {
    LogService.debug(
      "QueryUtils",
      "Applying order by: ${orderBy.column} ${orderBy.ascending ? 'ASC' : 'DESC'}",
    );
    return query.order(orderBy.column, ascending: orderBy.ascending);
  }

  /// 複数のソート条件をクエリに適用
  static PostgrestTransformBuilder<List<Map<String, dynamic>>> applyOrderBys(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> query,
    List<OrderByCondition> orderBys,
  ) {
    LogService.debug("QueryUtils", "Applying ${orderBys.length} order by conditions");
    PostgrestTransformBuilder<List<Map<String, dynamic>>> result = query;
    for (final OrderByCondition orderBy in orderBys) {
      result = applyOrderBy(result, orderBy);
    }
    return result;
  }

  /// 簡単なフィルタ条件作成ヘルパー（後方互換性維持）
  /// 新しいコードでは QueryConditionBuilder を推奨します
  static FilterCondition eq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.eq, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（不等号）
  static FilterCondition neq(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.neq, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（より大きい）
  static FilterCondition gt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gt, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（以上）
  static FilterCondition gte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.gte, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（より小さい）
  static FilterCondition lt(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lt, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（以下）
  static FilterCondition lte(String column, dynamic value) =>
      FilterCondition(column: column, operator: FilterOperator.lte, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（部分一致）
  static FilterCondition like(String column, String value) =>
      FilterCondition(column: column, operator: FilterOperator.like, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（部分一致・大文字小文字区別なし）
  static FilterCondition ilike(String column, String value) =>
      FilterCondition(column: column, operator: FilterOperator.ilike, value: value);

  /// 簡単なフィルタ条件作成ヘルパー（配列に含まれる）
  static FilterCondition inList(String column, List<dynamic> values) =>
      FilterCondition(column: column, operator: FilterOperator.inList, value: values);

  /// 簡単なフィルタ条件作成ヘルパー（NULL判定）
  static FilterCondition isNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNull, value: null);

  /// 簡単なフィルタ条件作成ヘルパー（NULL以外判定）
  static FilterCondition isNotNull(String column) =>
      FilterCondition(column: column, operator: FilterOperator.isNotNull, value: null);

  /// 簡単なAND条件作成ヘルパー
  static AndCondition and(List<QueryFilter> conditions) => AndCondition(conditions);

  /// 簡単なOR条件作成ヘルパー
  static OrCondition or(List<QueryFilter> conditions) => OrCondition(conditions);

  /// 簡単なソート条件作成ヘルパー（昇順）
  static OrderByCondition asc(String column) => OrderByCondition(column: column);

  /// 簡単なソート条件作成ヘルパー（降順）
  static OrderByCondition desc(String column) => OrderByCondition(column: column, ascending: false);
}
