import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "core/auth/auth_service.dart";
import "core/utils/log_service.dart";
import "core/utils/logger_mixin.dart";
import "shared/themes/app_theme.dart";
import "shared/widgets/custom_app_bar.dart";
import "core/constants/constants.dart";

void main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await dotenv.load();

  // ログサービスの初期化
  await LogService.initialize();

  // Supabaseの初期化
  await SupabaseClientService.initialize();

  // エラーハンドリングの設定
  _setupErrorHandling();

  // 起動
  runApp(const ProviderScope(child: YataApp()));
}

class YataApp extends ConsumerWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: AppStrings.titleApp,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    home: const Scaffold(
      appBar: CustomAppBar(title: AppStrings.titleApp),
      body: Center(child: Text(AppStrings.titleApp)),
    ),
    builder: (BuildContext context, Widget? child) => _AppBuilder(child: child),
    debugShowCheckedModeBanner: false,
  );
}

/// 全画面共通の設定やラッパー
class _AppBuilder extends StatelessWidget {
  const _AppBuilder({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    // テキストスケーリングの制限
    minScaleFactor: 0.8,
    maxScaleFactor: 1.5,
    child: child ?? const SizedBox.shrink(),
  );
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
