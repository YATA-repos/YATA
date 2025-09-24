import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app/app.dart";
import "core/validation/env_validator.dart";
import "infra/logging/logger.dart";
import "infra/supabase/supabase_client.dart";

void main() async {
  // flutter初期化
  WidgetsFlutterBinding.ensureInitialized();

  // ロガー初期化（クラッシュキャプチャ等）
  installCrashCapture();

  try {
    // 統合環境変数管理システムで初期化
    await EnvValidator.initialize();
    i("環境変数をロードしました: ${dotenv.env.keys.join(", ")}", tag: "main");

    final EnvValidationResult validationResult = EnvValidator.validate();
    EnvValidator.printValidationResult(validationResult);

    if (!validationResult.isValid) {
      // 本番環境では起動を停止することも検討
      w("環境変数の検証に失敗しました。", tag: "main");
    } else {
      i("環境変数の検証に成功しました。", tag: "main");
    }

    final bool shouldInit = _shouldInitializeSupabase();
    if (shouldInit) {
      try {
        await SupabaseClientService.initialize();
      } catch (error, stackTrace) {
        e("Supabaseの初期化に失敗しました: $error", error: error, st: stackTrace, tag: "main");
        rethrow;
      }
    } else {
      w("Supabaseの初期化はスキップされました。環境変数が設定されていないか、無効です。", tag: "main");
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      e("初期化中にエラーが発生しました: $error", error: error, st: stackTrace, tag: "main");
    }
  }

  _setupErrorHandling();

  runApp(const ProviderScope(child: YataApp()));
}

bool _shouldInitializeSupabase() {
  final String? url = dotenv.env["SUPABASE_URL"];
  final String? key = dotenv.env["SUPABASE_ANON_KEY"];

  return url != null && key != null && url.isNotEmpty && key.isNotEmpty;
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
