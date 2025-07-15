import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../core/utils/log_service.dart";
import "../shared/widgets/error_view.dart";
import "route_constants.dart";

/// ルーティングエラー画面
///
/// GoRouterでナビゲーションエラーが発生した際に表示されます。
class RouteErrorScreen extends ConsumerWidget {
  const RouteErrorScreen({this.error, super.key});

  /// エラー情報
  final Exception? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // エラーをログに記録
    if (error != null) {
      LogService.error("RouteErrorScreen", "Navigation error occurred: ${error.toString()}", error);
    }

    return Scaffold(
      body: SafeArea(
        child: ErrorView(
          icon: LucideIcons.navigation,
          title: "ナビゲーションエラー",
          message: _getErrorMessage(),
          onRetry: () => _handleRetry(context),
          additionalActions: <Widget>[
            _buildGoHomeButton(context),
            if (kDebugMode) _buildDebugInfo(context),
          ],
        ),
      ),
    );
  }

  /// エラーメッセージを取得
  String _getErrorMessage() {
    if (error != null) {
      final String errorMessage = error.toString();

      // 一般的なルーティングエラーのカスタムメッセージ
      if (errorMessage.contains("not found") || errorMessage.contains("404")) {
        return "ページが見つかりませんでした。\nURLを確認してください。";
      }

      if (errorMessage.contains("permission") || errorMessage.contains("auth")) {
        return "このページにアクセスする権限がありません。\nログインしてください。";
      }

      return "ページの読み込み中にエラーが発生しました。\nもう一度お試しください。";
    }

    return "不明なナビゲーションエラーが発生しました。";
  }

  /// リトライ処理
  void _handleRetry(BuildContext context) {
    // 現在のルートに再度アクセスを試行
    final String currentLocation = GoRouterState.of(context).uri.toString();

    if (currentLocation == "/") {
      // ルートの場合はリロード
      context.go(AppRoutes.home);
    } else {
      // その他の場合は同じルートに再度移動
      context.go(currentLocation);
    }
  }

  /// ホームに戻るボタン
  Widget _buildGoHomeButton(BuildContext context) => ElevatedButton.icon(
    onPressed: () => context.go(AppRoutes.home),
    icon: const Icon(LucideIcons.home),
    label: const Text("ホームに戻る"),
  );

  /// デバッグ情報表示（デバッグモードのみ）
  Widget _buildDebugInfo(BuildContext context) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        title: const Text("デバッグ情報", style: TextStyle(fontSize: 14)),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "エラータイプ: ${error.runtimeType}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "エラー詳細:\n${error.toString()}",
                  style: const TextStyle(fontFamily: "monospace"),
                ),
                const SizedBox(height: 8),
                Text(
                  "ルート: ${GoRouterState.of(context).uri.toString()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 特定のエラータイプに対応したエラー画面
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({this.path, super.key});

  final String? path;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ErrorView(
        icon: LucideIcons.fileQuestion,
        title: "ページが見つかりません",
        message: path != null ? "「$path」は存在しないページです。\nURLを確認してください。" : "このページは存在しません。",
        onRetry: () => context.go(AppRoutes.home),
        additionalActions: <Widget>[
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(LucideIcons.home),
            label: const Text("ホームに戻る"),
          ),
        ],
      ),
    ),
  );
}

/// 認証が必要なページへの未認証アクセス時のエラー画面
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ErrorView(
        icon: LucideIcons.lock,
        title: "ログインが必要です",
        message: "このページにアクセスするには\nログインしてください。",
        onRetry: () => context.go(AppRoutes.login),
        additionalActions: <Widget>[
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(LucideIcons.logIn),
            label: const Text("ログイン"),
          ),
        ],
      ),
    ),
  );
}
