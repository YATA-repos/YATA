import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";

/// ページ全体の余白と背景を統一するコンテナ。
class YataPageContainer extends StatelessWidget {
  /// [YataPageContainer]を生成する。
  const YataPageContainer({
    required this.child,
    super.key,
    this.padding = YataSpacingTokens.pagePadding,
    this.maxWidth = 1280,
    this.scrollable = true,
  });

  /// 内包するウィジェット。
  final Widget child;

  /// 余白設定。
  final EdgeInsetsGeometry padding;

  /// レイアウトの最大幅。
  final double maxWidth;

  /// ページ全体をスクロール可能にするか。
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return Container(
        color: YataColorTokens.background,
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      );
    }

    // 非スクロール: ビューポートにフィットさせ、高さを制約する
    return Container(
      color: YataColorTokens.background,
      alignment: Alignment.topCenter,
      child: SizedBox.expand(
        child: Padding(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
