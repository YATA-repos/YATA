import "package:mocktail/mocktail.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:test/test.dart";

import "package:yata/core/constants/query_types.dart";
import "package:yata/core/utils/query_utils.dart";

class _MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  setUpAll(() {
    registerFallbackValue("");
    registerFallbackValue(<String, dynamic>{});
  });

  group("QueryUtils.applyFilters", () {
    test("skips duplicate filter conditions", () {
      final _MockPostgrestFilterBuilder builder = _MockPostgrestFilterBuilder();
      when(() => builder.eq(any(), any())).thenAnswer((Invocation _) => builder);

      QueryUtils.applyFilters(builder, <QueryFilter>[
        QueryConditionBuilder.eq("status", "active"),
        QueryConditionBuilder.eq("status", "active"),
      ]);

      verify(() => builder.eq("status", "active")).called(1);
    });

    test("deduplicates filters inside OR condition", () {
      final _MockPostgrestFilterBuilder builder = _MockPostgrestFilterBuilder();
      when(() => builder.or(any())).thenAnswer((Invocation _) => builder);

      QueryUtils.applyFilters(builder, <QueryFilter>[
        OrCondition(<QueryFilter>[
          QueryConditionBuilder.eq("status", "active"),
          QueryConditionBuilder.eq("status", "active"),
        ]),
      ]);

      verify(() => builder.or("status.eq.active")).called(1);
    });

    test("does not reapply filter already present in OR", () {
      final _MockPostgrestFilterBuilder builder = _MockPostgrestFilterBuilder();
      when(() => builder.or(any())).thenAnswer((Invocation _) => builder);
      when(() => builder.eq(any(), any())).thenAnswer((Invocation _) => builder);

      QueryUtils.applyFilters(builder, <QueryFilter>[
        OrCondition(<QueryFilter>[
          QueryConditionBuilder.eq("status", "active"),
          QueryConditionBuilder.eq("priority", "high"),
        ]),
        QueryConditionBuilder.eq("status", "active"),
      ]);

      verify(() => builder.or("status.eq.active,priority.eq.high")).called(1);
      verifyNever(() => builder.eq("status", "active"));
      verifyNever(() => builder.eq("priority", "high"));
    });
  });
}
