import "package:flutter/material.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// ローディングインジケーターコンポーネント
///
/// 統一されたローディング表示を提供します。
/// メッセージ付きローディングや、画面全体のオーバーレイ表示に対応。
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    this.message,
    this.size = LoadingSize.medium,
    this.showBackground = false,
    super.key,
  });

  final String? message;
  final LoadingSize size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final Widget loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircularProgressIndicator(color: AppColors.primary, strokeWidth: _getStrokeWidth()),
        if (message != null) ...<Widget>[
          SizedBox(height: _getSpacing()),
          Text(
            message!,
            style: AppTextTheme.cardDescription.copyWith(fontSize: _getFontSize()),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        color: AppColors.background.withValues(alpha: 0.8),
        child: Center(child: loadingWidget),
      );
    }

    return Center(child: loadingWidget);
  }

  double _getStrokeWidth() => switch (size) {
    LoadingSize.small => 2.0,
    LoadingSize.medium => 3.0,
    LoadingSize.large => 4.0,
  };

  double _getSpacing() => switch (size) {
    LoadingSize.small => 8.0,
    LoadingSize.medium => 12.0,
    LoadingSize.large => 16.0,
  };

  double _getFontSize() => switch (size) {
    LoadingSize.small => 12.0,
    LoadingSize.medium => 14.0,
    LoadingSize.large => 16.0,
  };
}

/// インラインローディングインジケーター
///
/// ボタン内やカード内など、小さなスペースでの利用に最適化されています。
class InlineLoadingIndicator extends StatelessWidget {
  const InlineLoadingIndicator({this.color, this.size = 16.0, super.key});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: size,
    width: size,
    child: CircularProgressIndicator(color: color ?? AppColors.primary, strokeWidth: 2.0),
  );
}

/// フルスクリーンローディングオーバーレイ
///
/// 画面全体を覆うローディング表示を提供します。
class FullScreenLoadingOverlay extends StatelessWidget {
  const FullScreenLoadingOverlay({this.message = "読み込み中...", super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background.withValues(alpha: 0.8),
    body: LoadingIndicator(message: message, size: LoadingSize.large),
  );
}
