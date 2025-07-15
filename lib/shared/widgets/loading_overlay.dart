import "package:flutter/material.dart";

/// ローディング状態を表示するオーバーレイウィジェット
///
/// 全画面に半透明の背景を表示し、中央にローディングインジケーターとメッセージを配置します。
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    this.message = "ローディング中...",
    this.backgroundColor,
    this.indicatorColor,
    this.textColor,
    this.dismissible = false,
    this.onDismiss,
    super.key,
  });

  /// ローディングメッセージ
  final String message;

  /// 背景色
  final Color? backgroundColor;

  /// インジケーターの色
  final Color? indicatorColor;

  /// テキストの色
  final Color? textColor;

  /// タップで閉じることができるかどうか
  final bool dismissible;

  /// 閉じる時のコールバック
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final Container overlay = Container(
      color: backgroundColor ?? Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ローディングインジケーター
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ローディングメッセージ
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              // 閉じるボタン（dismissible=trueの場合のみ）
              if (dismissible) ...<Widget>[
                const SizedBox(height: 16),
                TextButton(onPressed: onDismiss, child: const Text("キャンセル")),
              ],
            ],
          ),
        ),
      ),
    );

    if (dismissible) {
      return GestureDetector(onTap: onDismiss, child: overlay);
    }

    return overlay;
  }
}

/// ミニマルなローディングインジケーター
class MinimalLoadingIndicator extends StatelessWidget {
  const MinimalLoadingIndicator({this.size = 20, this.strokeWidth = 2, this.color, super.key});

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: strokeWidth,
      valueColor: AlwaysStoppedAnimation<Color>(color ?? Theme.of(context).colorScheme.primary),
    ),
  );
}

/// ローディング状態付きボタン
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.loadingWidget,
    this.style,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: style,
    child: isLoading ? loadingWidget ?? const MinimalLoadingIndicator(size: 16) : child,
  );
}

/// プログレス付きローディング表示
class ProgressLoadingOverlay extends StatelessWidget {
  const ProgressLoadingOverlay({
    required this.progress,
    this.message = "ローディング中...",
    this.backgroundColor,
    this.progressColor,
    this.textColor,
    super.key,
  });

  /// 進捗（0.0-1.0）
  final double progress;

  /// ローディングメッセージ
  final String message;

  /// 背景色
  final Color? backgroundColor;

  /// プログレスバーの色
  final Color? progressColor;

  /// テキストの色
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
    color: backgroundColor ?? Colors.black54,
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ローディングメッセージ
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor ?? Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // プログレスバー
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // パーセンテージ表示
            Text(
              "${(progress * 100).toInt()}%",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// ドット形式のローディングインジケーター
class DotLoadingIndicator extends StatefulWidget {
  const DotLoadingIndicator({
    this.dotCount = 3,
    this.dotSize = 8.0,
    this.color,
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  final int dotCount;
  final double dotSize;
  final Color? color;
  final Duration duration;

  @override
  State<DotLoadingIndicator> createState() => _DotLoadingIndicatorState();
}

class _DotLoadingIndicatorState extends State<DotLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: widget.duration, vsync: this)..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List<Widget>.generate(
      widget.dotCount,
      (int index) => AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          final double animationValue = (_animationController.value - (index * 0.2)) % 1.0;
          final double opacity = animationValue < 0.5
              ? animationValue * 2
              : (1 - animationValue) * 2;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: (widget.color ?? Theme.of(context).colorScheme.primary).withValues(
                alpha: opacity.clamp(0.3, 1.0),
              ),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    ),
  );
}

/// スケルトンローディング
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({this.width, this.height = 16, this.borderRadius = 4, super.key});

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (BuildContext context, Widget? child) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
          stops: <double>[0.0, 0.5 + _animation.value * 0.5, 1.0],
        ),
      ),
    ),
  );
}
