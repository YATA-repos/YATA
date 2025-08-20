import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:window_manager/window_manager.dart";

import "app/app.dart";
import "core/logging/logger_mixin.dart";
import "core/logging/yata_logger.dart";
import "core/validation/env_validator.dart";
import "data/remote/supabase_client.dart";

void main() async {
  // flutter初期化
  WidgetsFlutterBinding.ensureInitialized();

  await YataLogger.initialize();

  try {
    // 統合環境変数管理システムで初期化
    await EnvValidator.initialize();
    YataLogger.info(
      "main",
      "環境変数をロードしました: ${dotenv.env.keys.join(", ")}"
    );
    
    final EnvValidationResult validationResult = EnvValidator.validate();
    EnvValidator.printValidationResult(validationResult);
    
    if (!validationResult.isValid) {
      // 本番環境では起動を停止することも検討
      YataLogger.warning(
        "main",
        "環境変数の検証に失敗しました。"
      );
    } else {
      YataLogger.info(
        "main",
        "環境変数の検証に成功しました。"
      );
    }

    final bool shouldInit = _shouldInitializeSupabase();
    if (shouldInit) {
      try {
        await SupabaseClientService.initialize();
      } catch (e, stackTrace) {
        YataLogger.error(
          "main",
          "Supabaseの初期化に失敗しました: $e",
          e,
          stackTrace,
        );
        rethrow;
      }
    } else {
      YataLogger.warning(
        "main",
        "Supabaseの初期化はスキップされました。環境変数が設定されていないか、無効です。"
      );
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      YataLogger.error(
        "main",
        "初期化中にエラーが発生しました: $e",
        e,
        stackTrace,
      );
    }
  }

  _setupErrorHandling();

  runApp(const ProviderScope(child: YataApp()));
}

bool _shouldInitializeSupabase() {
  final String? url = dotenv.env["SUPABASE_URL"];
  final String? key = dotenv.env["SUPABASE_ANON_KEY"];
  
  return url != null && 
         key != null && 
         url.isNotEmpty && 
         key.isNotEmpty;
}

void _setupErrorHandling() {
  final _ErrorHandler errorHandler = _ErrorHandler();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      errorHandler.logError(
        "Flutter framework error: ${details.exception}",
        details.exception,
        details.stack,
      );
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      errorHandler.logError("Platform error: $error", error, stack);
    } else {
      errorHandler.logError("Platform error in release mode: $error", error, stack);
    }
    return true;
  };
}

class _ErrorHandler with LoggerMixin {}
