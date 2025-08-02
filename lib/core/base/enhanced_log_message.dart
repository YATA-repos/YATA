import "package:logger/logger.dart";

import "../constants/enums.dart";

/// logger パッケージ準拠の拡張LogMessage基底クラス
/// 
/// 既存のLogMessageを拡張して、logger パッケージとの連携を強化
/// logger.Levelとの相互変換機能を提供
abstract class EnhancedLogMessage {
  /// メッセージ本文
  String get message;
  
  /// 推奨されるログレベル（logger パッケージ準拠）
  Level get recommendedLevel;
  
  /// YATA LogLevelとの対応（後方互換性）
  LogLevel get yataLogLevel;
}

/// EnhancedLogMessage用の拡張機能
extension EnhancedLogMessageExtension on EnhancedLogMessage {
  /// メッセージパラメータを置換して返す
  String withParams(Map<String, String> params) {
    String result = message;

    for (final MapEntry<String, String> entry in params.entries) {
      final String placeholder = "{${entry.key}}";
      result = result.replaceAll(placeholder, entry.value);
    }

    return result;
  }
  
  /// logger パッケージのLevelを使用したログ出力用メッセージ生成
  String toLoggerMessage([Map<String, String>? params]) => params != null ? withParams(params) : message;
  
  /// 構造化ログ用のデータ生成
  Map<String, dynamic> toStructuredData([Map<String, String>? params]) => <String, dynamic>{
      "message": toLoggerMessage(params),
      "level": recommendedLevel.name,
      "yataLevel": yataLogLevel.value,
      "priority": yataLogLevel.priority,
      "timestamp": DateTime.now().toIso8601String(),
    };
  
  /// logger パッケージの特定レベルでの出力が適切かチェック
  bool isAppropriateForLevel(Level targetLevel) =>
      // logger パッケージのLevel値で比較
      recommendedLevel.value <= targetLevel.value;
}

/// 情報レベル用のEnhancedLogMessage基底クラス
abstract class InfoLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.info;
  
  @override
  LogLevel get yataLogLevel => LogLevel.info;
}

/// 警告レベル用のEnhancedLogMessage基底クラス  
abstract class WarningLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.warning;
  
  @override
  LogLevel get yataLogLevel => LogLevel.warning;
}

/// エラーレベル用のEnhancedLogMessage基底クラス
abstract class ErrorLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.error;
  
  @override
  LogLevel get yataLogLevel => LogLevel.error;
}

/// デバッグレベル用のEnhancedLogMessage基底クラス
abstract class DebugLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.debug;
  
  @override
  LogLevel get yataLogLevel => LogLevel.debug;
}

/// ファタルレベル用のEnhancedLogMessage基底クラス
abstract class FatalLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.fatal;
  
  @override
  LogLevel get yataLogLevel => LogLevel.error; // YATAではerrorにマッピング
}

/// トレースレベル用のEnhancedLogMessage基底クラス
abstract class TraceLogMessage implements EnhancedLogMessage {
  @override
  Level get recommendedLevel => Level.trace;
  
  @override
  LogLevel get yataLogLevel => LogLevel.debug; // YATAではdebugにマッピング
}