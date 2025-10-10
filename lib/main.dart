import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app/app.dart";
import "app/wiring/provider.dart" show settingsServiceProvider;
import "core/validation/env_validator.dart";
import "features/order/presentation/performance/order_management_tracing.dart";
import "infra/logging/fatal_notifier.dart";
import "infra/logging/log_runtime_config.dart";
import "infra/logging/logger.dart";
import "infra/supabase/supabase_client.dart";

void main() async {
  // flutter初期化
  WidgetsFlutterBinding.ensureInitialized();

  // ロガー初期化（クラッシュキャプチャ等）
  installCrashCapture();
  registerFatalNotifier(const StdoutFatalNotifier());

  try {
    // 統合環境変数管理システムで初期化
    await EnvValidator.initialize();
    applyLogRuntimeConfig();
    OrderManagementTracer.configureFromEnvironment();

    i("環境変数をロードしました: ${EnvValidator.env.keys.join(", ")}", tag: "main");

    final EnvValidationResult validationResult = EnvValidator.validate();
    EnvValidator.printValidationResult(validationResult);

    if (!validationResult.isValid) {
      // ! 本番環境では起動を停止することも検討
      w("環境変数の検証に失敗しました。", tag: "main");
    } else {
      i("環境変数の検証に成功しました。", tag: "main");
    }

    final bool shouldInit = _shouldInitializeSupabase();
    if (shouldInit) {
      try {
        await SupabaseClientService.initialize();
      } catch (error, stackTrace) {
        w(
          "Supabase初期化に失敗したため安全モードで継続します: $error",
          tag: "main",
          fields: <String, dynamic>{
            "safe_mode": SupabaseClientService.isInSafeMode,
            "reason": SupabaseClientService.safeModeReason,
            "stack": stackTrace.toString(),
          },
        );
        // すでに SupabaseClientService.initialize 内で fatal ログおよび safe mode 切替を実施済み。
      }
    } else {
      w("Supabaseの初期化はスキップされました。環境変数が設定されていないか、無効です。", tag: "main");
    }

    if (SupabaseClientService.isInSafeMode) {
      w(
        "Supabase safe mode active: ${SupabaseClientService.safeModeReason ?? 'unknown'}",
        tag: "main",
        fields: <String, dynamic>{"safe_mode": true},
      );
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      e("初期化中にエラーが発生しました: $error", error: error, st: stackTrace, tag: "main");
    }
  }

  _setupErrorHandling();
  final ProviderContainer container = ProviderContainer();
  try {
    await container.read(settingsServiceProvider).loadAndApply();
  } catch (error, stackTrace) {
    e(
      "Failed to load settings during bootstrap: $error",
      error: error,
      st: stackTrace,
      tag: "main",
    );
  }

  runApp(UncontrolledProviderScope(container: container, child: const YataApp()));
}

bool _shouldInitializeSupabase() {
  final String url = EnvValidator.supabaseUrl;
  final String key = EnvValidator.supabaseAnonKey;

  return url.isNotEmpty && key.isNotEmpty;
}

void _setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      e(
        "Flutter framework error: ${details.exception}",
        error: details.exception,
        st: details.stack,
        tag: "main",
      );
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      e("Platform error: $error", error: error, st: stack, tag: "main");
    } else {
      e("Platform error in release mode: $error", error: error, st: stack, tag: "main");
    }
    return true;
  };
}
