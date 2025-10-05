class LogFieldsBuilder {
  LogFieldsBuilder._(this._fields);

  /// Create a builder with no pre-populated fields.
  factory LogFieldsBuilder.empty() => LogFieldsBuilder._(<String, dynamic>{});

  /// Create a builder for a specific business operation.
  factory LogFieldsBuilder.operation(String operation) => LogFieldsBuilder.empty().._setString("operation", operation);

  final Map<String, dynamic> _fields;
  final Map<String, dynamic> _actor = <String, dynamic>{};
  final Map<String, dynamic> _resource = <String, dynamic>{};
  final Map<String, dynamic> _result = <String, dynamic>{};
  final Map<String, String> _correlationIds = <String, String>{};
  Map<String, dynamic>? _metadata;

  /// Set or clear the operation stage (started / succeeded / failed / cancelled).
  LogFieldsBuilder withStage(String? stage) {
    _setString("stage", stage);
    return this;
  }

  /// Convenience for marking an operation as started.
  LogFieldsBuilder started() => withStage("started");

  /// Convenience for marking an operation as succeeded.
  LogFieldsBuilder succeeded({int? durationMs}) {
    withStage("succeeded");
    return withResult(status: "success", durationMs: durationMs);
  }

  /// Convenience for marking an operation as partially successful.
  LogFieldsBuilder partiallySucceeded({int? durationMs, String? reason}) {
    withStage("succeeded");
    return withResult(status: "partial", durationMs: durationMs, reason: reason);
  }

  /// Convenience for marking an operation as failed.
  LogFieldsBuilder failed({String? reason, String? errorCode, int? durationMs}) {
    withStage("failed");
    return withResult(status: "failure", reason: reason, errorCode: errorCode, durationMs: durationMs);
  }

  /// Convenience for marking an operation as cancelled.
  LogFieldsBuilder cancelled({String? reason}) {
    withStage("cancelled");
    return withResult(status: "noop", reason: reason);
  }

  /// Set flow and/or request identifiers.
  LogFieldsBuilder withFlow({String? flowId, String? requestId}) {
    _setString("flow_id", flowId);
    _setString("request_id", requestId);
    return this;
  }

  /// Register information about the actor (initiating user/session).
  LogFieldsBuilder withActor({String? userId, String? role, String? sessionId}) {
    _setNestedString(_actor, "user_id", userId);
    _setNestedString(_actor, "role", role);
    _setNestedString(_actor, "session_id", sessionId);
    return this;
  }

  /// Register store/location identifier.
  LogFieldsBuilder withStore(String? storeId) {
    _setString("store_id", storeId);
    return this;
  }

  /// Register tenant/organization identifier.
  LogFieldsBuilder withTenant(String? tenantId) {
    _setString("tenant_id", tenantId);
    return this;
  }

  /// Register the domain resource that this log touches.
  LogFieldsBuilder withResource({
    String? type,
    String? id,
    String? name,
    Map<String, dynamic>? extras,
  }) {
    _setNestedString(_resource, "type", type);
    _setNestedString(_resource, "id", id);
    _setNestedString(_resource, "name", name);
    if (extras != null) {
      for (final MapEntry<String, dynamic> entry in extras.entries) {
        _setNestedDynamic(_resource, entry.key, entry.value);
      }
    }
    return this;
  }

  /// Register result metadata.
  LogFieldsBuilder withResult({
    String? status,
    String? reason,
    int? durationMs,
    String? errorCode,
  }) {
    _setNestedString(_result, "status", status);
    _setNestedString(_result, "reason", reason);
    _setNestedString(_result, "error_code", errorCode);
    _setNestedDynamic(_result, "duration_ms", durationMs);
    return this;
  }

  /// Attach correlation identifiers.
  LogFieldsBuilder withCorrelationIds(Map<String, String>? ids) {
    if (ids == null) {
      return this;
    }
    for (final MapEntry<String, String> entry in ids.entries) {
      addCorrelationId(entry.key, entry.value);
    }
    return this;
  }

  /// Attach a single correlation identifier.
  LogFieldsBuilder addCorrelationId(String key, String? value) {
    if (_isEmptyString(key) || _isEmptyString(value)) {
      return this;
    }
    _correlationIds[key] = value!;
    return this;
  }

  /// Append domain-specific metadata (auto-merges existing values).
  LogFieldsBuilder addMetadata(Map<String, dynamic> values) {
    if (values.isEmpty) {
      return this;
    }
    _metadata ??= <String, dynamic>{};
    values.forEach((String key, dynamic value) {
      _setNestedDynamic(_metadata!, key, value);
    });
    return this;
  }

  /// Append a single metadata entry.
  LogFieldsBuilder addMetadataEntry(String key, dynamic value) {
    _metadata ??= <String, dynamic>{};
    _setNestedDynamic(_metadata!, key, value);
    if (_metadata!.isEmpty) {
      _metadata = null;
    }
    return this;
  }

  /// Merge in pre-existing structured fields.
  LogFieldsBuilder mergeRaw(Map<String, dynamic>? fields) {
    if (fields == null || fields.isEmpty) {
      return this;
    }
    for (final MapEntry<String, dynamic> entry in fields.entries) {
      _setDynamic(entry.key, entry.value);
    }
    return this;
  }

  /// Directly set a top-level field.
  LogFieldsBuilder setField(String key, dynamic value) {
    _setDynamic(key, value);
    return this;
  }

  /// Build an immutable map of the accumulated fields.
  Map<String, dynamic> build() {
    final Map<String, dynamic> result = <String, dynamic>{..._fields};
    if (_actor.isNotEmpty) {
      result["actor"] = Map<String, dynamic>.from(_actor);
    }
    if (_resource.isNotEmpty) {
      result["resource"] = Map<String, dynamic>.from(_resource);
    }
    if (_result.isNotEmpty) {
      result["result"] = Map<String, dynamic>.from(_result);
    }
    if (_correlationIds.isNotEmpty) {
      result["correlation_ids"] = Map<String, String>.from(_correlationIds);
    }
    if (_metadata != null && _metadata!.isNotEmpty) {
      result["metadata"] = Map<String, dynamic>.from(_metadata!);
    }
    return result;
  }

  void _setString(String key, String? value) {
    if (_isEmptyString(value)) {
      _fields.remove(key);
    } else {
      _fields[key] = value;
    }
  }

  void _setDynamic(String key, dynamic value) {
    if (value == null) {
      _fields.remove(key);
      return;
    }
    if (value is String && _isEmptyString(value)) {
      _fields.remove(key);
      return;
    }
    _fields[key] = value;
  }

  void _setNestedString(Map<String, dynamic> target, String key, String? value) {
    if (_isEmptyString(value)) {
      target.remove(key);
    } else {
      target[key] = value;
    }
  }

  void _setNestedDynamic(Map<String, dynamic> target, String key, dynamic value) {
    if (value == null) {
      target.remove(key);
      return;
    }
    if (value is String && _isEmptyString(value)) {
      target.remove(key);
      return;
    }
    target[key] = value;
  }

  bool _isEmptyString(String? value) => value == null || value.trim().isEmpty;
}
