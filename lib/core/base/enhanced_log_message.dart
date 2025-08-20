import "package:logger/logger.dart" as logger;

import "../logging/levels.dart";

/// logger パッケージ準拠の拡張LogMessage基底クラス
/// 
/// 既存のLogMessageを拡張して、logger パッケージとの連携を強化
/// logger.Levelとの相互変換機能を提供
abstract class EnhancedLogMessage {
  /// メッセージ本文
  String get message;
  
  /// 推奨されるログレベル（logger パッケージ準拠）
  logger.Level get recommendedLevel;
  
  /// YATA Levelとの対応（統合レベル）
  Level get yataLevel;
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
      "yataLevel": yataLevel.value,
      "priority": yataLevel.priority,
      "timestamp": DateTime.now().toIso8601String(),
    };
  
  /// logger パッケージの特定レベルでの出力が適切かチェック
  bool isAppropriateForLevel(logger.Level targetLevel) =>
      // logger パッケージのLevel値で比較
      recommendedLevel.value <= targetLevel.value;
}

/// 情報レベル用のEnhancedLogMessage基底クラス
abstract class InfoLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.info;
  
  @override
  Level get yataLevel => Level.info;
}

/// 警告レベル用のEnhancedLogMessage基底クラス  
abstract class WarningLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.warning;
  
  @override
  Level get yataLevel => Level.warn;
}

/// エラーレベル用のEnhancedLogMessage基底クラス
abstract class ErrorLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.error;
  
  @override
  Level get yataLevel => Level.error;
}

/// デバッグレベル用のEnhancedLogMessage基底クラス
abstract class DebugLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.debug;
  
  @override
  Level get yataLevel => Level.debug;
}

/// ファタルレベル用のEnhancedLogMessage基底クラス
abstract class FatalLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.fatal;
  
  @override
  Level get yataLevel => Level.fatal; // 統合enumでfatalを直接サポート
}

/// トレースレベル用のEnhancedLogMessage基底クラス
abstract class TraceLogMessage implements EnhancedLogMessage {
  @override
  logger.Level get recommendedLevel => logger.Level.trace;
  
  @override
  Level get yataLevel => Level.trace; // 統合enumでtraceを直接サポート
}