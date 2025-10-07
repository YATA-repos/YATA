import "../../core/contracts/logging/analytics_logger.dart";
import "../../core/contracts/logging/logger.dart" as log_contract;
import "../../core/logging/levels.dart";

/// 共通ロガー経由でアナリティクスイベントを出力するアダプタ。
class InfraAnalyticsLoggerAdapter implements AnalyticsLoggerContract {
  InfraAnalyticsLoggerAdapter(this._logger);

  final log_contract.LoggerContract _logger;

  static const String _defaultTag = "Analytics";

  @override
  void track(
    String eventName, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final Map<String, Object?> fields = <String, Object?>{"event": eventName};
    if (properties != null && properties.isNotEmpty) {
      fields["properties"] = Map<String, Object?>.from(properties);
    }

    _logger.log(
      Level.info,
      "Analytics event: $eventName",
      tag: _defaultTag,
      fields: fields,
      error: error,
      st: stackTrace,
    );
  }
}
