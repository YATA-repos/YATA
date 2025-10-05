import "../../../core/contracts/logging/logger.dart" as contract;
import "../../../infra/logging/context_utils.dart" as log_ctx;
import "../../../infra/logging/log_fields_builder.dart";

/// UI 層のユーザー操作に関するログを集約的に扱うためのヘルパー。
///
/// 操作開始・成功・失敗といった段階ごとに整形済みの構造化フィールドを生成し、
/// Flow ID / userAction などの共通属性を自動付与する。
class UiActionLogSession {
  UiActionLogSession._({
    required contract.LoggerContract logger,
    required this.flow,
    required this.action,
    required this.flowId,
    required this.tag,
  required Map<String, dynamic> baseMetadata,
    this.userId,
    this.requestId,
  })  : _logger = logger,
    _metadata = Map<String, dynamic>.from(baseMetadata),
        _startedAt = DateTime.now();

  /// 操作を開始し、`started` ログを即時送出する。
  factory UiActionLogSession.begin({
    required contract.LoggerContract logger,
    required String flow,
    required String action,
    String? userId,
    String? flowId,
    String? requestId,
    Map<String, dynamic>? metadata,
    String? tag,
    String? message,
  }) {
    final String resolvedFlowId =
        flowId != null && flowId.isNotEmpty ? flowId : log_ctx.newFlowId();

    final UiActionLogSession session = UiActionLogSession._(
      logger: logger,
      flow: flow,
      action: action,
      flowId: resolvedFlowId,
      tag: tag ?? "ui.$flow",
      userId: userId,
      requestId: requestId,
      baseMetadata: metadata ?? <String, dynamic>{},
    );
    session._started(message: message);
    return session;
  }

  final contract.LoggerContract _logger;
  final String flow;
  final String action;
  final String flowId;
  final String tag;
  final String? userId;
  final String? requestId;
  final DateTime _startedAt;
  final Map<String, dynamic> _metadata;
  bool _completed = false;

  /// 追加で保持したいメタデータを登録する。`null` 値は削除扱い。
  void addPersistentMetadata(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) {
      return;
    }
    metadata.forEach((String key, dynamic value) {
      if (value == null) {
        _metadata.remove(key);
      } else {
        _metadata[key] = value;
      }
    });
  }

  /// 操作が成功裏に完了したことを記録する。
  void succeeded({String? message, Map<String, dynamic>? metadata}) {
    if (_completed) {
      return;
    }
    _completed = true;
    final Map<String, dynamic> fields = _composeFields(
      _UiActionStage.succeeded,
      metadata: metadata,
      durationMs: _elapsedMs(),
    );
    _logger.i(
      message ?? _defaultMessage(_UiActionStage.succeeded),
      tag: tag,
      fields: fields,
    );
  }

  /// 操作がキャンセルされた場合の記録。
  void cancelled({String? message, String? reason, Map<String, dynamic>? metadata}) {
    if (_completed) {
      return;
    }
    _completed = true;
    final Map<String, dynamic> fields = _composeFields(
      _UiActionStage.cancelled,
      metadata: metadata,
      reason: reason,
      durationMs: _elapsedMs(),
    );
    _logger.w(
      message ?? _defaultMessage(_UiActionStage.cancelled),
      tag: tag,
      fields: fields,
    );
  }

  /// 操作が失敗した場合の記録。
  void failed({
    String? message,
    String? reason,
    String? errorCode,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_completed) {
      return;
    }
    _completed = true;
    final Map<String, dynamic> fields = _composeFields(
      _UiActionStage.failed,
      metadata: metadata,
      reason: reason,
      errorCode: errorCode,
      durationMs: _elapsedMs(),
    );
    _logger.e(
      message ?? _defaultMessage(_UiActionStage.failed),
      error: error,
      st: stackTrace,
      tag: tag,
      fields: fields,
    );
  }

  void _started({String? message}) {
    final Map<String, dynamic> fields =
        _composeFields(_UiActionStage.started, durationMs: 0);
    _logger.i(
      message ?? _defaultMessage(_UiActionStage.started),
      tag: tag,
      fields: fields,
    );
  }

  Map<String, dynamic> _composeFields(
    _UiActionStage stage, {
    Map<String, dynamic>? metadata,
    String? reason,
    String? errorCode,
    int? durationMs,
  }) {
    final LogFieldsBuilder builder = LogFieldsBuilder.operation("ui.$flow.$action")
      ..withFlow(flowId: flowId, requestId: requestId)
      ..withActor(userId: userId)
      ..setField("ui_flow", flow)
      ..setField("user_action", action)
      ..addMetadata(_metadata);

    if (metadata != null && metadata.isNotEmpty) {
      builder.addMetadata(metadata);
    }

    switch (stage) {
      case _UiActionStage.started:
        builder.started();
        break;
      case _UiActionStage.succeeded:
        builder.succeeded(durationMs: durationMs);
        break;
      case _UiActionStage.failed:
        builder.failed(reason: reason, errorCode: errorCode, durationMs: durationMs);
        break;
      case _UiActionStage.cancelled:
        builder.cancelled(reason: reason);
        break;
    }

    return builder.build();
  }

  int _elapsedMs() => DateTime.now().difference(_startedAt).inMilliseconds;

  String _defaultMessage(_UiActionStage stage) {
    switch (stage) {
      case _UiActionStage.started:
        return "[$flow] $action を開始";
      case _UiActionStage.succeeded:
        return "[$flow] $action が完了";
      case _UiActionStage.failed:
        return "[$flow] $action が失敗";
      case _UiActionStage.cancelled:
        return "[$flow] $action をキャンセル";
    }
  }
}

enum _UiActionStage { started, succeeded, failed, cancelled }
