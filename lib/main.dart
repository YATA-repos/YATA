import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
// ignore: implementation_imports
import "package:go_router/src/router.dart";

import "core/utils/logger_mixin.dart";
import "routing/providers/router_provider.dart";
import "shared/themes/app_theme.dart";

/// アプリケーションのエントリーポイント
void main() async {
  // Flutter エンジンの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // エラーハンドリングの設定
  _setupErrorHandling();

  // アプリケーションを起動
  runApp(
    // Riverpod の ProviderScope でラップ
    ProviderScope(child: const YataApp()),
  );
}

/// アプリケーションのメインクラス
class YataApp extends ConsumerWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter の取得
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // アプリケーション基本設定
      title: "YATA - 小規模レストラン管理システム",
      debugShowCheckedModeBanner: false,

      // テーマ設定
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // ルーティング設定
      routerConfig: router,

      // ローカライゼーション設定（将来的な多言語対応）
      supportedLocales: const <Locale>[
        Locale("ja", "JP"), // 日本語
        Locale("en", "US"), // 英語
      ],
      locale: const Locale("ja", "JP"),

      // パフォーマンス設定
      builder: (BuildContext context, Widget? child) => _AppBuilder(child: child),
    );
  }
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
