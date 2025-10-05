import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../core/constants/constants.dart";
import "../shared/themes/app_theme.dart";
import "router/app_router.dart";

/// YATAアプリケーションのメインクラス
class YataApp extends ConsumerWidget {
  const YataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: AppStrings.titleApp,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light,
    routerConfig: AppRouter.getRouter(ref),
    debugShowCheckedModeBanner: false,
  );
}
