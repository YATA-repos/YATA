import "package:flutter/material.dart";

import "../../foundations/tokens/color_tokens.dart";
import "../../foundations/tokens/radius_tokens.dart";
import "../../foundations/tokens/spacing_tokens.dart";
import "../../foundations/tokens/typography_tokens.dart";

/// リストやテーブルのフィルタリングに使用する検索フィールド。
class YataSearchField extends StatelessWidget {
  /// [YataSearchField]を生成する。
  const YataSearchField({
    super.key,
    this.controller,
    this.hintText = "キーワードで検索...",
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  });

  /// テキスト編集用コントローラ。
  final TextEditingController? controller;

  /// ヒントテキスト。
  final String hintText;

  /// 入力変更時に呼ばれるコールバック。
  final ValueChanged<String>? onChanged;

  /// フィールドタップ時に呼ばれるコールバック。
  final VoidCallback? onTap;

  /// 提交時に呼ばれるコールバック。
  final ValueChanged<String>? onSubmitted;

  /// フィールドの有効・無効状態。
  final bool enabled;

  /// ビルド直後にフォーカスするかどうか。
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onTap: onTap,
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge ?? YataTypographyTokens.bodyLarge,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: YataColorTokens.textSecondary),
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium ?? YataTypographyTokens.bodyMedium,
        contentPadding: YataSpacingTokens.inputPadding,
        filled: true,
        fillColor: YataColorTokens.neutral0,
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          borderSide: BorderSide(color: YataColorTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          borderSide: const BorderSide(color: YataColorTokens.primary, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(YataRadiusTokens.medium)),
          borderSide: BorderSide(color: YataColorTokens.border.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
