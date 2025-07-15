import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

/// エラー表示用の汎用ウィジェット
///
/// 一貫したデザインでエラー状態を表示します。
class ErrorView extends StatelessWidget {
  const ErrorView({
    this.icon = LucideIcons.alertCircle,
    this.title = "エラーが発生しました",
    this.message = "予期しないエラーが発生しました。もう一度お試しください。",
    this.onRetry,
    this.retryLabel = "再試行",
    this.additionalActions = const <Widget>[],
    this.compact = false,
    super.key,
  });

  /// 表示するアイコン
  final IconData icon;

  /// エラータイトル
  final String title;

  /// エラーメッセージ
  final String message;

  /// 再試行ボタンが押された時のコールバック
  final VoidCallback? onRetry;

  /// 再試行ボタンのラベル
  final String retryLabel;

  /// 追加のアクションボタン
  final List<Widget> additionalActions;

  /// コンパクト表示かどうか
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }

    return _buildFullView(context);
  }

  /// フル表示のエラービュー
  Widget _buildFullView(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // エラーアイコン
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Theme.of(context).colorScheme.onErrorContainer),
          ),

          const SizedBox(height: 24),

          // エラータイトル
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // エラーメッセージ
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // アクションボタン
          Column(
            children: <Widget>[
              // 再試行ボタン
              if (onRetry != null) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: Text(retryLabel),
                  ),
                ),
                if (additionalActions.isNotEmpty) const SizedBox(height: 12),
              ],

              // 追加アクション
              ...additionalActions.map(
                (Widget action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(width: double.infinity, child: action),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// コンパクト表示のエラービュー
  Widget _buildCompactView(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (message.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(width: 12),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw),
                tooltip: retryLabel,
              ),
            ],
          ],
        ),
        if (additionalActions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: additionalActions),
        ],
      ],
    ),
  );
}

/// ネットワークエラー専用のエラービュー
class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({this.onRetry, this.compact = false, super.key});

  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => ErrorView(
    icon: LucideIcons.wifiOff,
    title: "ネットワークエラー",
    message: "インターネット接続を確認して\nもう一度お試しください。",
    onRetry: onRetry,
    compact: compact,
  );
}

/// データ読み込みエラー専用のエラービュー
class DataLoadErrorView extends StatelessWidget {
  const DataLoadErrorView({this.onRetry, this.compact = false, super.key});

  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => ErrorView(
    icon: LucideIcons.database,
    title: "データ読み込みエラー",
    message: "データの読み込みに失敗しました。\nもう一度お試しください。",
    onRetry: onRetry,
    compact: compact,
  );
}

/// 権限エラー専用のエラービュー
class PermissionErrorView extends StatelessWidget {
  const PermissionErrorView({this.onRetry, this.compact = false, super.key});

  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => ErrorView(
    icon: LucideIcons.shield,
    title: "アクセス権限がありません",
    message: "この機能を使用する権限がありません。\n管理者にお問い合わせください。",
    onRetry: onRetry,
    retryLabel: "再確認",
    compact: compact,
  );
}

/// 空データ状態専用のビュー（厳密にはエラーではない）
class EmptyDataView extends StatelessWidget {
  const EmptyDataView({
    this.icon = LucideIcons.inbox,
    this.title = "データがありません",
    this.message = "まだデータが登録されていません。",
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<Widget> additionalActions = <Widget>[];
    if (onAction != null && actionLabel != null) {
      additionalActions.add(
        ElevatedButton.icon(
          onPressed: onAction,
          icon: const Icon(LucideIcons.plus),
          label: Text(actionLabel!),
        ),
      );
    }

    return ErrorView(
      icon: icon,
      title: title,
      message: message,
      additionalActions: additionalActions,
      compact: compact,
    );
  }
}
