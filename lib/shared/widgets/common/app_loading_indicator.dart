import "dart:math" as math;

import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.variant = LoadingIndicatorVariant.circular,
    this.size = LoadingIndicatorSize.medium,
    this.color,
    this.strokeWidth,
    this.value,
    this.backgroundColor,
    this.message,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final LoadingIndicatorVariant variant;
  final LoadingIndicatorSize size;
  final Color? color;
  final double? strokeWidth;
  final double? value;
  final Color? backgroundColor;
  final String? message;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: AppConstants.animationSlow, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

    if (widget.variant == LoadingIndicatorVariant.dots ||
        widget.variant == LoadingIndicatorVariant.spinner) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _LoadingIndicatorStyle style = _getLoadingIndicatorStyle();

    Widget indicator = _buildIndicator(style);

    if (widget.message != null) {
      indicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          indicator,
          const SizedBox(height: AppLayout.spacing4),
          Text(
            widget.message!,
            style: TextStyle(color: style.textColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Semantics(
      label: widget.semanticsLabel ?? "読み込み中",
      value: widget.semanticsValue,
      child: indicator,
    );
  }

  Widget _buildIndicator(_LoadingIndicatorStyle style) {
    switch (widget.variant) {
      case LoadingIndicatorVariant.circular:
        return _buildCircularIndicator(style);
      case LoadingIndicatorVariant.linear:
        return _buildLinearIndicator(style);
      case LoadingIndicatorVariant.dots:
        return _buildDotsIndicator(style);
      case LoadingIndicatorVariant.spinner:
        return _buildSpinnerIndicator(style);
    }
  }

  Widget _buildCircularIndicator(_LoadingIndicatorStyle style) => SizedBox(
    width: style.size,
    height: style.size,
    child: CircularProgressIndicator(
      value: widget.value,
      strokeWidth: widget.strokeWidth ?? style.strokeWidth,
      color: widget.color ?? style.color,
      backgroundColor: widget.backgroundColor ?? style.backgroundColor,
    ),
  );

  Widget _buildLinearIndicator(_LoadingIndicatorStyle style) => SizedBox(
    width: style.size * 2,
    height: style.strokeWidth,
    child: LinearProgressIndicator(
      value: widget.value,
      color: widget.color ?? style.color,
      backgroundColor: widget.backgroundColor ?? style.backgroundColor,
    ),
  );

  Widget _buildDotsIndicator(_LoadingIndicatorStyle style) => AnimatedBuilder(
    animation: _animation,
    builder: (BuildContext context, Widget? child) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        final double delay = index * 0.2;
        final double value = (_animation.value - delay).clamp(0.0, 1.0);
        final double scale = (Curves.elasticOut.transform(value) * 0.5) + 0.5;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: style.dotSpacing / 2),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: style.dotSize,
              height: style.dotSize,
              decoration: BoxDecoration(color: widget.color ?? style.color, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    ),
  );

  Widget _buildSpinnerIndicator(_LoadingIndicatorStyle style) => AnimatedBuilder(
    animation: _animationController,
    builder: (BuildContext context, Widget? child) => Transform.rotate(
      angle: _animationController.value * 2 * 3.14159,
      child: SizedBox(
        width: style.size,
        height: style.size,
        child: CustomPaint(
          painter: _SpinnerPainter(
            color: widget.color ?? style.color,
            strokeWidth: widget.strokeWidth ?? style.strokeWidth,
          ),
        ),
      ),
    ),
  );

  _LoadingIndicatorStyle _getLoadingIndicatorStyle() {
    final Color defaultColor = widget.color ?? AppColors.primary;
    final Color defaultBackgroundColor = widget.backgroundColor ?? AppColors.muted;

    switch (widget.size) {
      case LoadingIndicatorSize.small:
        return _LoadingIndicatorStyle(
          size: 16,
          strokeWidth: 2,
          dotSize: 4,
          dotSpacing: 2,
          color: defaultColor,
          backgroundColor: defaultBackgroundColor,
          textColor: AppColors.foreground,
        );
      case LoadingIndicatorSize.medium:
        return _LoadingIndicatorStyle(
          size: 24,
          strokeWidth: 3,
          dotSize: 6,
          dotSpacing: 4,
          color: defaultColor,
          backgroundColor: defaultBackgroundColor,
          textColor: AppColors.foreground,
        );
      case LoadingIndicatorSize.large:
        return _LoadingIndicatorStyle(
          size: 32,
          strokeWidth: 4,
          dotSize: 8,
          dotSpacing: 6,
          color: defaultColor,
          backgroundColor: defaultBackgroundColor,
          textColor: AppColors.foreground,
        );
    }
  }
}

class _LoadingIndicatorStyle {
  const _LoadingIndicatorStyle({
    required this.size,
    required this.strokeWidth,
    required this.dotSize,
    required this.dotSpacing,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  final double size;
  final double strokeWidth;
  final double dotSize;
  final double dotSpacing;
  final Color color;
  final Color backgroundColor;
  final Color textColor;
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    const int lineCount = 8;
    for (int i = 0; i < lineCount; i++) {
      final double angle = (i * 2 * 3.14159) / lineCount;
      final double opacity = (i + 1) / lineCount;

      paint.color = color.withValues(alpha: opacity);

      final Offset start = Offset(
        center.dx + (radius * 0.6) * math.cos(angle),
        center.dy + (radius * 0.6) * math.sin(angle),
      );
      final Offset end = Offset(
        center.dx + (radius * 0.9) * math.cos(angle),
        center.dy + (radius * 0.9) * math.sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
