import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app/app.dart";
import "core/infrastructure/supabase/supabase_client.dart";
import "core/validation/env_validator.dart";
import "core/logging/log_service.dart";
import "core/logging/logger_mixin.dart";

void main() async {
  // 起動開始の明確な表示
  debugPrint("DEBUG: ========================================");
  debugPrint("DEBUG: YATA Application Starting...");
  debugPrint("DEBUG: Time: ${DateTime.now().toIso8601String()}");
  debugPrint("DEBUG: Flutter Version: unknown");
  debugPrint("DEBUG: Debug Mode: $kDebugMode");
  debugPrint("DEBUG: ========================================");

  // Flutterの初期化を確実に行う
  debugPrint("DEBUG: [1/6] Initializing Flutter bindings...");
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("DEBUG: [1/6] ✅ Flutter bindings initialized");

  try {
    // 環境変数の読み込み
    debugPrint("DEBUG: [2/6] Loading environment variables...");
    await dotenv.load();
    debugPrint("DEBUG: [2/6] ✅ Environment variables loaded");
    
    // 環境変数の詳細検証
    debugPrint("DEBUG: [2/6] Validating environment variables...");
    final EnvValidationResult validationResult = EnvValidator.validate();
    EnvValidator.printValidationResult(validationResult);
    
    if (!validationResult.isValid) {
      debugPrint("DEBUG: [2/6] ❌ Environment validation failed, but continuing startup...");
      // 本番環境では起動を停止することも検討
      // throw Exception("Environment validation failed");
    } else {
      debugPrint("DEBUG: [2/6] ✅ Environment validation successful");
    }

    // ログサービスの初期化
    debugPrint("DEBUG: [3/6] Initializing log service...");
    await LogService.initialize();
    debugPrint("DEBUG: [3/6] ✅ Log service initialized");
    
    // ログサービス初期化後の最初のログ
    debugPrint("DEBUG: [3/6] Testing LogService functionality...");
    LogService.info("main", "DEBUG: === YATA Application Startup ===");
    LogService.info("main", "DEBUG: Log service is now active and operational");
    LogService.info("main", "DEBUG: Application starting with debug logging enabled");
    debugPrint("DEBUG: [3/6] ✅ LogService test calls completed");

    // Supabaseの初期化（環境変数が設定されている場合のみ）
    debugPrint("DEBUG: [4/6] Checking Supabase configuration...");
    LogService.info("main", "DEBUG: [4/6] Checking Supabase configuration...");
    
    final bool shouldInit = _shouldInitializeSupabase();
    debugPrint("DEBUG: [4/6] Should initialize Supabase: $shouldInit");
    
    if (shouldInit) {
      debugPrint("DEBUG: [4/6] Supabase configuration found, initializing...");
      LogService.info("main", "DEBUG: [4/6] Supabase configuration found, initializing...");
      
      try {
        debugPrint("DEBUG: [4/6] Calling SupabaseClientService.initialize()...");
        await SupabaseClientService.initialize();
        debugPrint("DEBUG: [4/6] ✅ SupabaseClientService.initialize() completed");
        LogService.info("main", "DEBUG: [4/6] ✅ Supabase initialized successfully");
        
      } catch (e, stackTrace) {
        debugPrint("DEBUG: [4/6] ❌ Supabase initialization failed: $e");
        debugPrint("DEBUG: [4/6] Stack trace: $stackTrace");
        LogService.error("main", "DEBUG: [4/6] ❌ Supabase initialization failed: $e", e, stackTrace);
        rethrow;
      }
    } else {
      debugPrint("DEBUG: [4/6] ⚠️  Supabase initialization skipped: Environment variables not configured");
      LogService.warning("main", "DEBUG: [4/6] ⚠️  Supabase initialization skipped: Environment variables not configured");
    }
    
    debugPrint("DEBUG: [5/6] Setting up error handling...");
    LogService.info("main", "DEBUG: [5/6] Setting up error handling...");
  } catch (e, stackTrace) {
    // 初期化エラーの場合、開発モードでは詳細を表示
    debugPrint("DEBUG: ❌ CRITICAL ERROR during initialization:");
    debugPrint("DEBUG: Error Type: ${e.runtimeType}");
    debugPrint("DEBUG: Error Message: $e");
    debugPrint("DEBUG: Stack Trace: $stackTrace");
    
    if (kDebugMode) {
      debugPrint("Initialization error: $e");
    }
    
    // ログサービスが利用可能かチェック
    try {
      LogService.error("main", "DEBUG: Application initialization failed: ${e.toString()}", e);
    } catch (logError) {
      debugPrint("DEBUG: Log service also failed: $logError");
    }
  }

  // エラーハンドリングの設定
  debugPrint("DEBUG: [5/6] Setting up error handlers...");
  _setupErrorHandling();
  debugPrint("DEBUG: [5/6] ✅ Error handlers configured");
  
  LogService.info("main", "DEBUG: [6/6] Starting Flutter application...");
  debugPrint("DEBUG: [6/6] Starting Flutter application...");

  // 起動
  runApp(const ProviderScope(child: YataApp()));
  
  LogService.info("main", "DEBUG: [6/6] ✅ Flutter application started successfully");
  debugPrint("DEBUG: [6/6] ✅ Flutter application started successfully");
  debugPrint("DEBUG: ========================================");
}

/// Supabaseを初期化すべきかどうかをチェック
bool _shouldInitializeSupabase() {
  final String? url = dotenv.env["SUPABASE_URL"];
  final String? key = dotenv.env["SUPABASE_ANON_KEY"];
  
  return url != null && 
         key != null && 
         url.isNotEmpty && 
         key.isNotEmpty;
}

/// エラーハンドリングの設定
void _setupErrorHandling() {
  final _ErrorHandler errorHandler = _ErrorHandler();

  // Flutterのハンドリング
  FlutterError.onError = (FlutterErrorDetails details) {
    // debugとreleaseでハンドリングを分岐
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

  // dartのハンドリング
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      errorHandler.logError("Platform error: $error", error, stack);
    } else {
      errorHandler.logError("Platform error in release mode: $error", error, stack);
    }
    return true;
  };
}

/// エラーハンドリング用クラス
class _ErrorHandler with LoggerMixin {
  // LoggerMixin のメソッドが利用可能
}
