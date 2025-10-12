import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";

typedef YataTableSortCallback = void Function(bool ascending);
typedef YataTableCellBuilder = Widget Function(BuildContext context);

/// テーブル列のメタ情報を表現するスペック。
class YataTableColumnSpec {
  const YataTableColumnSpec({
    required this.id,
    required this.label,
    this.tooltip,
    this.onSort,
    this.numeric = false,
    this.defaultAlignment = Alignment.centerLeft,
    this.minWidth,
    this.maxWidth,
  });

  /// 列を一意に識別するID。
  final String id;

  /// ヘッダー表示。
  final Widget label;

  /// ヘッダーに付与するツールチップ。
  final String? tooltip;

  /// ソート操作のハンドラ。
  final YataTableSortCallback? onSort;

  /// 数値列かどうか。
  final bool numeric;

  /// デフォルトのセル整列位置。
  final AlignmentGeometry defaultAlignment;

  /// セルに適用する最小幅。
  final double? minWidth;

  /// セルに適用する最大幅。
  final double? maxWidth;
}

/// 行単位の表示・状態を表現するスペック。
class YataTableRowSpec {
  const YataTableRowSpec({
    required this.id,
    required this.cells,
    this.key,
    this.onTap,
    this.tooltip,
    this.semanticLabel,
    this.isBusy = false,
    this.errorMessage,
    this.backgroundColor,
  }) : assert(cells.length > 0, "Row requires at least one cell");

  /// 行を識別するID。
  final String id;

  /// 行に含まれるセル。
  final List<YataTableCellSpec> cells;

  /// 行に割り当てるキー。
  final LocalKey? key;

  /// 行タップ時のコールバック。
  final VoidCallback? onTap;

  /// 行全体のツールチップ。
  final String? tooltip;

  /// 行全体のセマンティクスラベル。
  final String? semanticLabel;

  /// 行が処理中かどうか。
  final bool isBusy;

  /// 行レベルのエラーメッセージ。
  final String? errorMessage;

  /// 行全体に適用する背景色。
  final Color? backgroundColor;
}

/// セル表示を抽象化するスペック。
class YataTableCellSpec {
  const YataTableCellSpec._({
    required this.builder,
    this.alignment,
    this.tooltip,
    this.semanticLabel,
    this.applyRowBusyOverlay = false,
    this.isBusy = false,
    this.errorMessage,
  });

  /// 任意のウィジェットを表示するセル。
  factory YataTableCellSpec.widget({
    required YataTableCellBuilder builder,
    AlignmentGeometry? alignment,
    String? tooltip,
    String? semanticLabel,
    bool applyRowBusyOverlay = false,
    bool isBusy = false,
    String? errorMessage,
  }) => YataTableCellSpec._(
    builder: builder,
    alignment: alignment,
    tooltip: tooltip,
    semanticLabel: semanticLabel,
    applyRowBusyOverlay: applyRowBusyOverlay,
    isBusy: isBusy,
    errorMessage: errorMessage,
  );

  /// 主テキストと補助テキストを縦に並べるセル。
  factory YataTableCellSpec.text({
    required String label,
    String? description,
    TextStyle? labelStyle,
    TextStyle? descriptionStyle,
    AlignmentGeometry? alignment,
    TextAlign textAlign = TextAlign.start,
    String? tooltip,
    String? semanticLabel,
    int? labelMaxLines,
    TextOverflow labelOverflow = TextOverflow.ellipsis,
    int? descriptionMaxLines,
    TextOverflow descriptionOverflow = TextOverflow.ellipsis,
  }) => YataTableCellSpec._(
    alignment: alignment,
    tooltip: tooltip,
    semanticLabel: semanticLabel,
    builder: (BuildContext context) {
      final TextStyle resolvedLabelStyle =
          labelStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
      final TextStyle? resolvedDescriptionStyle = description == null
          ? null
          : (descriptionStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle());

      final List<Widget> children = <Widget>[
        Text(
          label,
          style: resolvedLabelStyle,
          textAlign: textAlign,
          maxLines: labelMaxLines,
          overflow: labelOverflow,
        ),
      ];
      if (description != null && description.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: YataSpacingTokens.xs),
            child: Text(
              description,
              style: resolvedDescriptionStyle,
              maxLines: descriptionMaxLines,
              overflow: descriptionOverflow,
              textAlign: textAlign,
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: _toCrossAxisAlignment(textAlign),
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    },
  );

  /// バッジを並べるセル。
  factory YataTableCellSpec.badges({
    required List<Widget> badges,
    AlignmentGeometry? alignment,
    double spacing = YataSpacingTokens.xs,
    double runSpacing = YataSpacingTokens.xs,
    String? tooltip,
    String? semanticLabel,
  }) => YataTableCellSpec._(
    alignment: alignment,
    tooltip: tooltip,
    semanticLabel: semanticLabel,
    builder: (_) => Wrap(spacing: spacing, runSpacing: runSpacing, children: badges),
  );

  /// セル内容を生成するビルダー。
  final YataTableCellBuilder builder;

  /// セル単位の整列位置。
  final AlignmentGeometry? alignment;

  /// セル単位のツールチップ。
  final String? tooltip;

  /// セル単位のセマンティクスラベル。
  final String? semanticLabel;

  /// 行のBusy状態をセルに適用するか。
  final bool applyRowBusyOverlay;

  /// セル固有のBusy状態。
  final bool isBusy;

  /// セル固有のエラーメッセージ。
  final String? errorMessage;
}

CrossAxisAlignment _toCrossAxisAlignment(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return CrossAxisAlignment.center;
    case TextAlign.right:
    case TextAlign.end:
      return CrossAxisAlignment.end;
    case TextAlign.left:
    case TextAlign.start:
    case TextAlign.justify:
      return CrossAxisAlignment.start;
  }
}

/// Busyオーバーレイ付きでセル内容を表示するヘルパー。
Widget yataTableBusyOverlay(Widget child) => Stack(
  alignment: Alignment.center,
  children: <Widget>[
    IgnorePointer(child: Opacity(opacity: 0.5, child: child)),
    const Positioned.fill(
      child: Center(
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    ),
  ],
);

/// セルのエラーメッセージを表示するヘルパー。
Widget yataTableCellWithError({required Widget child, required String message}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    child,
    const SizedBox(height: YataSpacingTokens.xs),
    Text(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: YataColorTokens.danger, fontSize: 12),
    ),
  ],
);
