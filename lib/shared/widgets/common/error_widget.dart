import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// エラー表示ウィジェット
///
/// 統一されたエラー表示を提供します。
/// 再試行ボタンやカスタムアクションにも対応しています。
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    this.title = "エラーが発生しました",
    this.message,
    this.icon = LucideIcons.alertCircle,
    this.onRetry,
    this.retryText = "再試行",
    this.actions,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryText;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(title, style: AppTextTheme.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(message!, style: AppTextTheme.cardDescription, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),

          // アクションボタン
          if (onRetry != null || actions != null) ...<Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (onRetry != null) ...<Widget>[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text(retryText),
                  ),
                  if (actions != null) const SizedBox(width: 12),
                ],
                if (actions != null) ...actions!,
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

/// 空の状態表示ウィジェット
///
/// データが存在しない場合の表示に使用します。
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    this.title = "データがありません",
    this.message,
    this.icon = LucideIcons.inbox,
    this.action,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(title, style: AppTextTheme.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(message!, style: AppTextTheme.cardDescription, textAlign: TextAlign.center),
          ],
          if (action != null) ...<Widget>[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}

/// ネットワークエラー専用ウィジェット
///
/// ネットワーク接続エラーに特化した表示を提供します。
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({this.onRetry, super.key});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppErrorWidget(
    title: "接続エラー",
    message: "インターネット接続を確認してください",
    icon: LucideIcons.wifiOff,
    onRetry: onRetry,
    retryText: "再接続",
  );
}

/// 404エラー専用ウィジェット
///
/// ページが見つからない場合の表示に使用します。
class NotFoundWidget extends StatelessWidget {
  const NotFoundWidget({this.message = "ページが見つかりません", this.onGoHome, super.key});

  final String message;
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) => AppErrorWidget(
    title: "404",
    message: message,
    icon: LucideIcons.fileX,
    actions: onGoHome != null
        ? <Widget>[
            ElevatedButton.icon(
              onPressed: onGoHome,
              icon: const Icon(LucideIcons.home, size: 16),
              label: const Text("ホームに戻る"),
            ),
          ]
        : null,
  );
}

/// エラー状態表示のためのヘルパークラス
///
/// 異なるタイプのエラーに対して適切なウィジェットを返します。
class ErrorStateHelper {
  ErrorStateHelper._();

  /// エラーの種類に応じて適切なウィジェットを返す
  static Widget buildErrorWidget({required Object error, VoidCallback? onRetry}) {
    if (error.toString().contains("SocketException") ||
        error.toString().contains("NetworkException")) {
      return NetworkErrorWidget(onRetry: onRetry);
    }

    if (error.toString().contains("404") || error.toString().contains("Not Found")) {
      return const NotFoundWidget();
    }

    return AppErrorWidget(message: error.toString(), onRetry: onRetry);
  }
}
