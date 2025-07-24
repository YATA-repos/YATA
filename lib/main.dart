import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "./shared/themes/themes.dart";
import "core/constants/constants.dart";
import "core/utils/log_service.dart";
import "core/utils/logger_mixin.dart";

void main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  // await dotenv.load();

  // ログサービスの初期化
  await LogService.initialize();

  // Supabaseの初期化
  // await SupabaseClientService.initialize();

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
    home: Scaffold(
      appBar: AppBar(
        title: AppBarTitle(),
        centerTitle: false,
        actions: <Widget>[
          CustomNavigation(),
        ]
      ),
      body: Center(child: Text(AppStrings.titleApp)),
    ),
    debugShowCheckedModeBanner: false,
  );
}

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(LucideIcons.coffee),
        AppLayout.hSpacerSmall,
        Text(
          AppStrings.titleApp,
          style: Theme.of(context).textTheme.headlineSmall
        ),
      ],
    );
}

class CustomNavigation extends StatelessWidget {
  const CustomNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomNavItem(
          icon: LucideIcons.home, 
          label: AppStrings.navHome
        ),
        AppLayout.hSpacerSmall,
        CustomNavItem(
          icon: LucideIcons.history, 
          label: AppStrings.navOrderHistory
        ),
        AppLayout.hSpacerSmall,
        CustomNavItem(
          icon: LucideIcons.barChart4, 
          label: AppStrings.navAnalytics
        ),
      ],
    );
}

class CustomNavItem extends StatelessWidget {
  const CustomNavItem({
    required this.icon, required this.label, super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
      children: <Widget>[
        Container(
          margin: AppLayout.marginSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon),
              AppLayout.hSpacerSmall,
              Text(label),
            ],
          ),
        ),
      ]
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
