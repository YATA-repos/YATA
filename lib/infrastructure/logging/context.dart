import "dart:async";

typedef LogContext = Map<String, Object?>;

final Object _zoneLogContextKey = Object();

LogContext? currentLogContext() {
  final Object? v = Zone.current[_zoneLogContextKey];
  if (v is LogContext) return v;
  return null;
}

T runWithContext<T>(LogContext ctx, T Function() body, {bool merge = true}) {
  final LogContext? parent = currentLogContext();
  final LogContext next = switch ((merge, parent)) {
    (true, null) => Map<String, Object?>.from(ctx),
    (true, final LogContext p) => {...p, ...ctx},
    (false, _) => Map<String, Object?>.from(ctx),
  };
  return runZoned<T>(body, zoneValues: {_zoneLogContextKey: next});
}

