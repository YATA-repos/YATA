import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

/// プログレスバーコンポーネント
///
/// 進捗表示、アニメーション対応
class AppProgressBar extends StatefulWidget {
  const AppProgressBar({
    required this.value,
    super.key,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.borderRadius,
    this.showLabel = false,
    this.label,
    this.animated = true,
    this.animationDuration,
  });

  /// 進捗値（0.0 - 1.0）
  final double value;

  /// バーの高さ
  final double height;

  /// 背景色
  final Color? backgroundColor;

  /// 進捗色
  final Color? valueColor;

  /// 角丸
  final BorderRadius? borderRadius;

  /// ラベル表示
  final bool showLabel;

  /// カスタムラベル
  final String? label;

  /// アニメーション有効
  final bool animated;

  /// アニメーション時間
  final Duration? animationDuration;

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? AppConstants.animationNormal,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AppProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

      if (widget.animated) {
        _animationController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (widget.showLabel) ...<Widget>[
        _buildLabel(context),
        const SizedBox(height: AppLayout.spacing1),
      ],
      _buildProgressBar(),
    ],
  );

  Widget _buildLabel(BuildContext context) {
    final String displayLabel = widget.label ?? "${(widget.value * 100).toInt()}%";

    return Text(
      displayLabel,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.mutedForeground,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProgressBar() => Container(
    height: widget.height,
    decoration: BoxDecoration(
      color: widget.backgroundColor ?? AppColors.muted,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
    ),
    child: ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
      child: widget.animated
          ? AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? child) => LinearProgressIndicator(
                value: _animation.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor ?? AppColors.primary),
              ),
            )
          : LinearProgressIndicator(
              value: widget.value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor ?? AppColors.primary),
            ),
    ),
  );
}

/// 円形プログレスバー
class AppCircularProgressBar extends StatefulWidget {
  const AppCircularProgressBar({
    required this.value,
    super.key,
    this.size = 48,
    this.strokeWidth = 4,
    this.backgroundColor,
    this.valueColor,
    this.showLabel = false,
    this.label,
    this.child,
    this.animated = true,
    this.animationDuration,
  });

  /// 進捗値（0.0 - 1.0）
  final double value;

  /// サイズ
  final double size;

  /// 線の太さ
  final double strokeWidth;

  /// 背景色
  final Color? backgroundColor;

  /// 進捗色
  final Color? valueColor;

  /// ラベル表示
  final bool showLabel;

  /// カスタムラベル
  final String? label;

  /// 中央コンテンツ
  final Widget? child;

  /// アニメーション有効
  final bool animated;

  /// アニメーション時間
  final Duration? animationDuration;

  @override
  State<AppCircularProgressBar> createState() => _AppCircularProgressBarState();
}

class _AppCircularProgressBarState extends State<AppCircularProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? AppConstants.animationNormal,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AppCircularProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

      if (widget.animated) {
        _animationController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        widget.animated
            ? AnimatedBuilder(
                animation: _animation,
                builder: (BuildContext context, Widget? child) => CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor ?? AppColors.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor ?? AppColors.primary),
                ),
              )
            : CircularProgressIndicator(
                value: widget.value,
                strokeWidth: widget.strokeWidth,
                backgroundColor: widget.backgroundColor ?? AppColors.muted,
                valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor ?? AppColors.primary),
              ),
        if (widget.child != null) widget.child! else if (widget.showLabel) _buildLabel(context),
      ],
    ),
  );

  Widget _buildLabel(BuildContext context) {
    final String displayLabel = widget.label ?? "${(widget.value * 100).toInt()}%";

    return Text(
      displayLabel,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.foreground, fontWeight: FontWeight.w600),
    );
  }
}
