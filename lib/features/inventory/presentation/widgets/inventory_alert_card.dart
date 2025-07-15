import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/common/app_button.dart";
import "../../../../shared/widgets/common/app_card.dart";
import "../../../../shared/widgets/common/app_icon_button.dart";

/// 在庫警告レベル列挙型
enum InventoryAlertLevel {
  info, // 情報
  warning, // 注意
  danger, // 警告
  critical, // 緊急
}

/// 在庫警告表示カード
///
/// 在庫に関する警告やアラートを表示します。
class InventoryAlertCard extends StatelessWidget {
  const InventoryAlertCard({
    required this.title,
    required this.message,
    required this.level,
    super.key,
    this.affectedItems,
    this.itemCount,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onDismiss,
    this.primaryActionText,
    this.secondaryActionText,
    this.showDismissButton = true,
    this.isCompact = false,
  });

  /// 警告タイトル
  final String title;

  /// 警告メッセージ
  final String message;

  /// 警告レベル
  final InventoryAlertLevel level;

  /// 影響を受けるアイテムリスト
  final List<String>? affectedItems;

  /// 影響を受けるアイテム数
  final int? itemCount;

  /// 主要アクション時のコールバック
  final VoidCallback? onPrimaryAction;

  /// 副次アクション時のコールバック
  final VoidCallback? onSecondaryAction;

  /// 警告を閉じる時のコールバック
  final VoidCallback? onDismiss;

  /// 主要アクションボタンのテキスト
  final String? primaryActionText;

  /// 副次アクションボタンのテキスト
  final String? secondaryActionText;

  /// 閉じるボタンの表示
  final bool showDismissButton;

  /// コンパクト表示
  final bool isCompact;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: CardVariant.outlined,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _getLevelColor(), width: 4)),
      ),
      child: Padding(
        padding: AppLayout.padding4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(context),
            const SizedBox(height: AppLayout.spacing3),
            _buildMessage(context),
            if (!isCompact && (affectedItems != null || itemCount != null)) ...<Widget>[
              const SizedBox(height: AppLayout.spacing3),
              _buildAffectedItems(context),
            ],
            if (onPrimaryAction != null || onSecondaryAction != null) ...<Widget>[
              const SizedBox(height: AppLayout.spacing4),
              _buildActions(context),
            ],
          ],
        ),
      ),
    ),
  );

  /// ヘッダーセクション（アイコン、タイトル、閉じるボタン）
  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getLevelColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getLevelIcon(), color: _getLevelColor(), size: 20),
      ),
      const SizedBox(width: AppLayout.spacing3),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      ),
      if (showDismissButton && onDismiss != null) ...<Widget>[
        const SizedBox(width: AppLayout.spacing2),
        AppIconButton(icon: LucideIcons.x, onPressed: onDismiss, tooltip: "閉じる"),
      ],
    ],
  );

  /// メッセージセクション
  Widget _buildMessage(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
  );

  /// 影響を受けるアイテムセクション
  Widget _buildAffectedItems(BuildContext context) {
    if (itemCount != null && itemCount! > 0) {
      return Container(
        padding: AppLayout.padding3,
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppLayout.spacing2),
        ),
        child: Row(
          children: <Widget>[
            Icon(LucideIcons.package, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: AppLayout.spacing2),
            Text(
              "$itemCount個のアイテムが影響を受けています",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (affectedItems != null && affectedItems!.isNotEmpty) {
      final List<String> displayItems = affectedItems!.take(3).toList();
      final bool hasMore = affectedItems!.length > 3;

      return Container(
        padding: AppLayout.padding3,
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppLayout.spacing2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(LucideIcons.package, size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: AppLayout.spacing2),
                Text(
                  "影響を受けるアイテム:",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spacing2),
            ...displayItems.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 24),
                child: Text(
                  "• $item",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
                ),
              ),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 24),
                child: Text(
                  "...他${affectedItems!.length - 3}個",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// アクションボタンセクション
  Widget _buildActions(BuildContext context) => Row(
    children: <Widget>[
      if (onSecondaryAction != null) ...<Widget>[
        AppButton(
          onPressed: onSecondaryAction,
          variant: ButtonVariant.ghost,
          size: ButtonSize.small,
          child: Text(secondaryActionText ?? "後で"),
        ),
        const SizedBox(width: AppLayout.spacing2),
      ],
      if (onPrimaryAction != null)
        AppButton(
          onPressed: onPrimaryAction,
          variant: _getPrimaryButtonVariant(),
          size: ButtonSize.small,
          child: Text(primaryActionText ?? _getDefaultPrimaryText()),
        ),
    ],
  );

  /// 警告レベルに基づく色を取得
  Color _getLevelColor() {
    switch (level) {
      case InventoryAlertLevel.info:
        return AppColors.primary;
      case InventoryAlertLevel.warning:
        return AppColors.warning;
      case InventoryAlertLevel.danger:
        return AppColors.danger;
      case InventoryAlertLevel.critical:
        return AppColors.danger;
    }
  }

  /// 警告レベルに基づくアイコンを取得
  IconData _getLevelIcon() {
    switch (level) {
      case InventoryAlertLevel.info:
        return LucideIcons.info;
      case InventoryAlertLevel.warning:
        return LucideIcons.alertTriangle;
      case InventoryAlertLevel.danger:
        return LucideIcons.alertCircle;
      case InventoryAlertLevel.critical:
        return LucideIcons.alertOctagon;
    }
  }

  /// 主要ボタンのバリアントを取得
  ButtonVariant _getPrimaryButtonVariant() {
    switch (level) {
      case InventoryAlertLevel.info:
        return ButtonVariant.primary;
      case InventoryAlertLevel.warning:
        return ButtonVariant.warning;
      case InventoryAlertLevel.danger:
      case InventoryAlertLevel.critical:
        return ButtonVariant.danger;
    }
  }

  /// デフォルトの主要アクションテキストを取得
  String _getDefaultPrimaryText() {
    switch (level) {
      case InventoryAlertLevel.info:
        return "確認";
      case InventoryAlertLevel.warning:
        return "対処";
      case InventoryAlertLevel.danger:
      case InventoryAlertLevel.critical:
        return "今すぐ対処";
    }
  }
}

/// 在庫警告情報用データクラス
class InventoryAlertInfo {
  const InventoryAlertInfo({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.createdAt,
    this.affectedItemIds,
    this.affectedItems,
    this.itemCount,
    this.threshold,
    this.currentValue,
    this.category,
    this.isRead = false,
    this.isDismissed = false,
    this.expiresAt,
  });

  /// 警告ID
  final String id;

  /// 警告タイトル
  final String title;

  /// 警告メッセージ
  final String message;

  /// 警告レベル
  final InventoryAlertLevel level;

  /// 作成日時
  final DateTime createdAt;

  /// 影響を受けるアイテムIDリスト
  final List<String>? affectedItemIds;

  /// 影響を受けるアイテム名リスト
  final List<String>? affectedItems;

  /// 影響を受けるアイテム数
  final int? itemCount;

  /// 閾値（在庫少警告など）
  final double? threshold;

  /// 現在の値
  final double? currentValue;

  /// カテゴリー
  final String? category;

  /// 既読状態
  final bool isRead;

  /// 無視状態
  final bool isDismissed;

  /// 有効期限
  final DateTime? expiresAt;

  /// 警告の緊急度を数値で取得（0-3）
  int get urgencyLevel {
    switch (level) {
      case InventoryAlertLevel.info:
        return 0;
      case InventoryAlertLevel.warning:
        return 1;
      case InventoryAlertLevel.danger:
        return 2;
      case InventoryAlertLevel.critical:
        return 3;
    }
  }

  /// 期限切れかどうかを確認
  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 警告の年数を計算
  int get ageDays => DateTime.now().difference(createdAt).inDays;

  /// コピーメソッド
  InventoryAlertInfo copyWith({
    String? id,
    String? title,
    String? message,
    InventoryAlertLevel? level,
    DateTime? createdAt,
    List<String>? affectedItemIds,
    List<String>? affectedItems,
    int? itemCount,
    double? threshold,
    double? currentValue,
    String? category,
    bool? isRead,
    bool? isDismissed,
    DateTime? expiresAt,
  }) => InventoryAlertInfo(
    id: id ?? this.id,
    title: title ?? this.title,
    message: message ?? this.message,
    level: level ?? this.level,
    createdAt: createdAt ?? this.createdAt,
    affectedItemIds: affectedItemIds ?? this.affectedItemIds,
    affectedItems: affectedItems ?? this.affectedItems,
    itemCount: itemCount ?? this.itemCount,
    threshold: threshold ?? this.threshold,
    currentValue: currentValue ?? this.currentValue,
    category: category ?? this.category,
    isRead: isRead ?? this.isRead,
    isDismissed: isDismissed ?? this.isDismissed,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}

/// 在庫警告リスト表示用ウィジェット
class InventoryAlertList extends StatelessWidget {
  const InventoryAlertList({
    required this.alerts,
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onDismiss,
    this.showDismissed = false,
    this.compactMode = false,
  });

  /// 警告リスト
  final List<InventoryAlertInfo> alerts;

  /// 主要アクション時のコールバック
  final void Function(InventoryAlertInfo alert)? onPrimaryAction;

  /// 副次アクション時のコールバック
  final void Function(InventoryAlertInfo alert)? onSecondaryAction;

  /// 警告を閉じる時のコールバック
  final void Function(InventoryAlertInfo alert)? onDismiss;

  /// 無視された警告も表示
  final bool showDismissed;

  /// コンパクトモード
  final bool compactMode;

  @override
  Widget build(BuildContext context) {
    final List<InventoryAlertInfo> filteredAlerts =
        alerts
            .where((InventoryAlertInfo alert) => showDismissed || !alert.isDismissed)
            .where((InventoryAlertInfo alert) => !alert.isExpired)
            .toList()
          ..sort((InventoryAlertInfo a, InventoryAlertInfo b) {
            // 緊急度優先、次に作成日時（新しい順）
            final int urgencyCompare = b.urgencyLevel.compareTo(a.urgencyLevel);
            if (urgencyCompare != 0) {
              return urgencyCompare;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

    if (filteredAlerts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAlerts.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppLayout.spacing3),
      itemBuilder: (BuildContext context, int index) {
        final InventoryAlertInfo alert = filteredAlerts[index];

        return InventoryAlertCard(
          title: alert.title,
          message: alert.message,
          level: alert.level,
          affectedItems: alert.affectedItems,
          itemCount: alert.itemCount,
          isCompact: compactMode,
          onPrimaryAction: onPrimaryAction != null ? () => onPrimaryAction!(alert) : null,
          onSecondaryAction: onSecondaryAction != null ? () => onSecondaryAction!(alert) : null,
          onDismiss: onDismiss != null ? () => onDismiss!(alert) : null,
        );
      },
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(LucideIcons.checkCircle, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          "現在、警告はありません",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 8),
        Text(
          "在庫状態は正常です",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );
}
