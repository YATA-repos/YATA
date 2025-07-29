import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/enums.dart" as core_enums;
import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_text_theme.dart";
import "../../models/order_model.dart";
import "../../models/order_ui_extensions.dart";

/// 注文進行状況表示ウィジェット
///
/// 注文のステータス遷移を視覚的なプログレスバーで表示
class OrderProgress extends StatelessWidget {
  const OrderProgress({
    required this.order,
    this.showSteps = true,
    this.showElapsedTime = true,
    this.isCompact = false,
    super.key,
  });

  final Order order;
  final bool showSteps;
  final bool showElapsedTime;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactProgress();
    } else {
      return _buildFullProgress();
    }
  }

  /// フルサイズのプログレス表示
  Widget _buildFullProgress() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      // プログレスバー
      _buildProgressBar(),

      if (showSteps) ...<Widget>[
        const SizedBox(height: 12),
        // ステップ詳細
        _buildProgressSteps(),
      ],

      if (showElapsedTime) ...<Widget>[
        const SizedBox(height: 8),
        // 経過時間
        _buildElapsedTime(),
      ],
    ],
  );

  /// コンパクトなプログレス表示
  Widget _buildCompactProgress() => Row(
    children: <Widget>[
      // プログレスバー
      Expanded(child: _buildProgressBar()),

      if (showElapsedTime) ...<Widget>[
        const SizedBox(width: 8),
        // 経過時間
        Text(
          order.formatElapsedTime(order.elapsedTime),
          style: AppTextTheme.cardDescription.copyWith(
            color: order.getElapsedTimeColor(order.elapsedTime),
            fontSize: 12,
          ),
        ),
      ],
    ],
  );

  /// プログレスバー
  Widget _buildProgressBar() {
    final double progress = _getProgressValue();
    final Color progressColor = _getProgressColor();

    return Container(
      height: isCompact ? 4 : 6,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(isCompact ? 2 : 3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(isCompact ? 2 : 3),
          ),
        ),
      ),
    );
  }

  /// ステップ詳細表示
  Widget _buildProgressSteps() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      _buildProgressStep(
        "注文受付",
        LucideIcons.fileText,
        _isStepCompleted(core_enums.OrderStatus.confirmed),
        _isStepActive(core_enums.OrderStatus.confirmed),
      ),
      _buildProgressStep(
        "調理開始",
        LucideIcons.chefHat,
        _isStepCompleted(core_enums.OrderStatus.preparing),
        _isStepActive(core_enums.OrderStatus.preparing),
      ),
      _buildProgressStep(
        "調理完了",
        LucideIcons.checkCircle,
        _isStepCompleted(core_enums.OrderStatus.ready),
        _isStepActive(core_enums.OrderStatus.ready),
      ),
      _buildProgressStep(
        "提供完了",
        LucideIcons.checkCircle,
        _isStepCompleted(core_enums.OrderStatus.delivered),
        _isStepActive(core_enums.OrderStatus.delivered),
      ),
    ],
  );

  /// プログレスステップ
  Widget _buildProgressStep(String label, IconData icon, bool isCompleted, bool isActive) => Column(
    children: <Widget>[
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success
              : isActive
              ? AppColors.primary
              : AppColors.muted,
          shape: BoxShape.circle,
          border: isActive && !isCompleted ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Icon(
          isCompleted ? LucideIcons.check : icon,
          color: isCompleted || isActive ? AppColors.primaryForeground : AppColors.mutedForeground,
          size: 16,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTextTheme.cardDescription.copyWith(
          fontSize: 10,
          color: isCompleted || isActive ? AppColors.foreground : AppColors.mutedForeground,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// 経過時間表示
  Widget _buildElapsedTime() => Row(
    children: <Widget>[
      Icon(LucideIcons.clock, size: 14, color: order.getElapsedTimeColor(order.elapsedTime)),
      const SizedBox(width: 4),
      Text(
        "経過時間: ${order.formatElapsedTime(order.elapsedTime)}",
        style: AppTextTheme.cardDescription.copyWith(
          color: order.getElapsedTimeColor(order.elapsedTime),
          fontSize: 12,
        ),
      ),
    ],
  );

  /// プログレス値を計算（0.0 - 1.0）
  double _getProgressValue() => switch (order.status) {
    core_enums.OrderStatus.pending => 0.1,
    core_enums.OrderStatus.confirmed => 0.25,
    core_enums.OrderStatus.preparing => 0.5,
    core_enums.OrderStatus.ready => 0.75,
    core_enums.OrderStatus.delivered => 1.0,
    core_enums.OrderStatus.completed => 1.0,
    core_enums.OrderStatus.cancelled => 0.0,
    core_enums.OrderStatus.refunded => 0.0,
  };

  /// プログレス色を取得
  Color _getProgressColor() => switch (order.status) {
    core_enums.OrderStatus.pending => AppColors.warning,
    core_enums.OrderStatus.confirmed => AppColors.primary,
    core_enums.OrderStatus.preparing => AppColors.cooking,
    core_enums.OrderStatus.ready => AppColors.complete,
    core_enums.OrderStatus.delivered => AppColors.success,
    core_enums.OrderStatus.completed => AppColors.success,
    core_enums.OrderStatus.cancelled => AppColors.danger,
    core_enums.OrderStatus.refunded => AppColors.secondary,
  };

  /// ステップが完了しているかチェック
  bool _isStepCompleted(core_enums.OrderStatus stepStatus) {
    final List<core_enums.OrderStatus> completedStatuses = <core_enums.OrderStatus>[
      core_enums.OrderStatus.delivered,
      core_enums.OrderStatus.completed,
    ];

    if (completedStatuses.contains(order.status)) {
      return true;
    }

    return switch (stepStatus) {
      core_enums.OrderStatus.confirmed => _isStatusReached(core_enums.OrderStatus.confirmed),
      core_enums.OrderStatus.preparing => _isStatusReached(core_enums.OrderStatus.preparing),
      core_enums.OrderStatus.ready => _isStatusReached(core_enums.OrderStatus.ready),
      core_enums.OrderStatus.delivered => _isStatusReached(core_enums.OrderStatus.delivered),
      _ => false,
    };
  }

  /// ステップがアクティブかチェック
  bool _isStepActive(core_enums.OrderStatus stepStatus) => order.status == stepStatus;

  /// 指定ステータスに到達しているかチェック
  bool _isStatusReached(core_enums.OrderStatus targetStatus) {
    const List<core_enums.OrderStatus> statusOrder = <core_enums.OrderStatus>[
      core_enums.OrderStatus.pending,
      core_enums.OrderStatus.confirmed,
      core_enums.OrderStatus.preparing,
      core_enums.OrderStatus.ready,
      core_enums.OrderStatus.delivered,
      core_enums.OrderStatus.completed,
    ];

    final int currentIndex = statusOrder.indexOf(order.status);
    final int targetIndex = statusOrder.indexOf(targetStatus);

    return currentIndex >= targetIndex;
  }
}
