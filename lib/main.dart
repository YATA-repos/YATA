import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
// ignore: implementation_imports
import "package:go_router/src/router.dart";

import "core/auth/auth_service.dart";
import "core/utils/log_service.dart";
import "core/utils/logger_mixin.dart";
import "shared/themes/app_theme.dart";

/// アプリケーションのエントリーポイント
void main() async {
  // Flutter エンジンの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await dotenv.load();

  // ログサービスの初期化
  await LogService.initialize();

  final _ErrorHandler tempLogger = _ErrorHandler()
    ..logInfo("Starting YATA application...")
    ..logInfo("Flutter binding initialized.")
    ..logInfo("Environment variables loaded.")
    ..logInfo("Log service initialized.");

  // Supabaseの初期化
  await SupabaseClientService.initialize();
  tempLogger.logInfo("Supabase client initialized.");

  // エラーハンドリングの設定
  _setupErrorHandling();
  tempLogger.logInfo("Error handling setup completed.");

  // アプリケーションを起動
  runApp(
    // Riverpod の ProviderScope でラップ
    // ProviderScope(child: const YataApp()),
    YataApp(),
  );
}

class YataApp extends StatelessWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Hello YATA")));
}

/// アプリケーションビルダー
///
/// 全画面共通の設定やラッパーを提供します。
class _AppBuilder extends StatelessWidget {
  const _AppBuilder({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    // テキストスケーリングの制限（アクセシビリティ対応）
    minScaleFactor: 0.8,
    maxScaleFactor: 1.5,
    child: child ?? const SizedBox.shrink(),
  );
}

/// エラーハンドリングの設定
void _setupErrorHandling() {
  final _ErrorHandler errorHandler = _ErrorHandler();

  // Flutter フレームワークのエラーハンドリング
  FlutterError.onError = (FlutterErrorDetails details) {
    // デバッグモードでは詳細を出力
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // リリースモードではログに記録
      errorHandler.logError(
        "Flutter framework error: ${details.exception}",
        details.exception,
        details.stack,
      );
    }
  };

  // プラットフォーム（Dart）のエラーハンドリング
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
