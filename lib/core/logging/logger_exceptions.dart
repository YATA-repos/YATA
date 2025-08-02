/// YATAログシステム専用例外クラス
/// 
/// ログ関連の問題を明確に識別し、適切なエラーハンドリングを支援
library;

/// ログシステム全般の例外基底クラス
abstract class LoggerException implements Exception {
  
  const LoggerException(
    this.message, {
    this.component,
    this.originalError,
    this.originalStackTrace,
  });
  final String message;
  final String? component;
  final Object? originalError;
  final StackTrace? originalStackTrace;
  
  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write("$runtimeType");
    
    if (component != null) {
      buffer.write(" in [$component]");
    }
    
    buffer.write(": $message");
    
    if (originalError != null) {
      buffer.write(" (caused by: $originalError)");
    }
    
    return buffer.toString();
  }
}

/// Logger初期化関連の例外
class LoggerInitializationException extends LoggerException {
  const LoggerInitializationException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// Logger初期化失敗
  factory LoggerInitializationException.initializationFailed(
    String reason, {
    String? component,
    Object? originalError,
    StackTrace? originalStackTrace,
  }) => LoggerInitializationException(
      "Logger initialization failed: $reason",
      component: component,
      originalError: originalError,
      originalStackTrace: originalStackTrace,
    );
  
  /// Logger設定エラー
  factory LoggerInitializationException.configurationError(
    String configName,
    String reason, {
    String? component,
  }) => LoggerInitializationException(
      "Logger configuration error for '$configName': $reason",
      component: component,
    );
}

/// ログ出力関連の例外
class LoggerOutputException extends LoggerException {
  const LoggerOutputException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// ファイル出力エラー
  factory LoggerOutputException.fileOutputError(
    String filePath,
    String reason, {
    String? component,
    Object? originalError,
    StackTrace? originalStackTrace,
  }) => LoggerOutputException(
      "File output error for '$filePath': $reason",
      component: component,
      originalError: originalError,
      originalStackTrace: originalStackTrace,
    );
  
  /// バッファ操作エラー
  factory LoggerOutputException.bufferError(
    String operation,
    String reason, {
    String? component,
    Object? originalError,
  }) => LoggerOutputException(
      "Buffer $operation error: $reason",
      component: component,
      originalError: originalError,
    );
  
  /// ディレクトリ作成エラー
  factory LoggerOutputException.directoryCreationError(
    String directoryPath,
    String reason, {
    String? component,
    Object? originalError,
  }) => LoggerOutputException(
      "Directory creation error for '$directoryPath': $reason",
      component: component,
      originalError: originalError,
    );
}

/// ログ設定関連の例外
class LoggerConfigurationException extends LoggerException {
  const LoggerConfigurationException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// 無効な設定値
  factory LoggerConfigurationException.invalidValue(
    String configName,
    dynamic value,
    String reason, {
    String? component,
  }) => LoggerConfigurationException(
      "Invalid value for '$configName' ($value): $reason",
      component: component,
    );
  
  /// 環境変数読み込みエラー
  factory LoggerConfigurationException.environmentVariableError(
    String variableName,
    String reason, {
    String? component,
  }) => LoggerConfigurationException(
      "Environment variable '$variableName' error: $reason",
      component: component,
    );
  
  /// 設定の競合
  factory LoggerConfigurationException.configurationConflict(
    String config1,
    String config2,
    String reason, {
    String? component,
  }) => LoggerConfigurationException(
      "Configuration conflict between '$config1' and '$config2': $reason",
      component: component,
    );
}

/// ログフォーマット関連の例外
class LoggerFormatException extends LoggerException {
  const LoggerFormatException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// メッセージフォーマットエラー
  factory LoggerFormatException.messageFormatError(
    String originalMessage,
    String reason, {
    String? component,
    Object? originalError,
  }) => LoggerFormatException(
      "Message format error for '$originalMessage': $reason",
      component: component,
      originalError: originalError,
    );
  
  /// パラメータ置換エラー
  factory LoggerFormatException.parameterSubstitutionError(
    String template,
    Map<String, String> parameters,
    String reason, {
    String? component,
  }) => LoggerFormatException(
      "Parameter substitution error for template '$template' with parameters $parameters: $reason",
      component: component,
    );
}

/// ログレベル関連の例外
class LoggerLevelException extends LoggerException {
  const LoggerLevelException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// 無効なログレベル
  factory LoggerLevelException.invalidLevel(
    dynamic level,
    String reason, {
    String? component,
  }) => LoggerLevelException(
      "Invalid log level '$level': $reason",
      component: component,
    );
  
  /// ログレベル変更エラー
  factory LoggerLevelException.levelChangeError(
    dynamic fromLevel,
    dynamic toLevel,
    String reason, {
    String? component,
  }) => LoggerLevelException(
      "Log level change error from '$fromLevel' to '$toLevel': $reason",
      component: component,
    );
}

/// ログリソース関連の例外
class LoggerResourceException extends LoggerException {
  const LoggerResourceException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// リソース不足
  factory LoggerResourceException.resourceExhausted(
    String resourceType,
    String reason, {
    String? component,
  }) => LoggerResourceException(
      "$resourceType resource exhausted: $reason",
      component: component,
    );
  
  /// リソースアクセスエラー
  factory LoggerResourceException.resourceAccessError(
    String resourceType,
    String resourceId,
    String reason, {
    String? component,
    Object? originalError,
  }) => LoggerResourceException(
      "$resourceType access error for '$resourceId': $reason",
      component: component,
      originalError: originalError,
    );
  
  /// リソースクリーンアップエラー
  factory LoggerResourceException.resourceCleanupError(
    String resourceType,
    String reason, {
    String? component,
    Object? originalError,
  }) => LoggerResourceException(
      "$resourceType cleanup error: $reason",
      component: component,
      originalError: originalError,
    );
}

/// ログ状態関連の例外
class LoggerStateException extends LoggerException {
  const LoggerStateException(
    super.message, {
    super.component,
    super.originalError,
    super.originalStackTrace,
  });
  
  /// 無効な状態でのアクセス
  factory LoggerStateException.invalidState(
    String currentState,
    String operation,
    String requiredState, {
    String? component,
  }) => LoggerStateException(
      "Invalid state '$currentState' for operation '$operation': requires '$requiredState'",
      component: component,
    );
  
  /// 状態遷移エラー
  factory LoggerStateException.stateTransitionError(
    String fromState,
    String toState,
    String reason, {
    String? component,
  }) => LoggerStateException(
      "State transition error from '$fromState' to '$toState': $reason",
      component: component,
    );
}