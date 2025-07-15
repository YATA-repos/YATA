import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../enums/ui_enums.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";
import "app_button.dart";

/// モーダルダイアログコンポーネント
///
/// 背景オーバーレイ、閉じる処理、レスポンシブ対応
class AppModal extends StatelessWidget {
  const AppModal({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.onClose,
    this.width,
    this.height,
    this.maxWidth = 600,
    this.maxHeight,
    this.padding,
    this.showCloseButton = true,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.scrollable = true,
  });

  /// モーダルコンテンツ
  final Widget child;

  /// タイトル
  final String? title;

  /// サブタイトル
  final String? subtitle;

  /// アクションボタン
  final List<Widget>? actions;

  /// 閉じる処理コールバック
  final VoidCallback? onClose;

  /// モーダル幅
  final double? width;

  /// モーダル高さ
  final double? height;

  /// 最大幅
  final double maxWidth;

  /// 最大高さ
  final double? maxHeight;

  /// コンテンツパディング
  final EdgeInsetsGeometry? padding;

  /// 閉じるボタン表示
  final bool showCloseButton;

  /// 背景タップで閉じる
  final bool barrierDismissible;

  /// 背景色
  final Color? backgroundColor;

  /// スクロール可能
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: AppLayout.padding4,
    child: _buildModalContent(context),
  );

  Widget _buildModalContent(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double modalWidth = width ?? (screenWidth * 0.9).clamp(300, maxWidth.toDouble());
    final double? modalHeight = height ?? (maxHeight != null ? screenHeight * 0.8 : null);

    Widget content = Container(
      width: modalWidth,
      height: modalHeight,
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight ?? screenHeight * 0.9),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        borderRadius: AppLayout.radiusXl,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: AppLayout.elevationXl,
            offset: Offset(0, AppLayout.spacing2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null || showCloseButton) _buildHeader(context),
          Flexible(child: _buildBody()),
          if (actions != null) _buildActions(),
        ],
      ),
    );

    if (barrierDismissible) {
      content = GestureDetector(
        onTap: () => _handleClose(context),
        child: Container(
          color: Colors.black54,
          child: GestureDetector(
            onTap: () {}, // コンテンツタップでモーダルが閉じないように
            child: Center(child: content),
          ),
        ),
      );
    } else {
      content = Container(
        color: Colors.black54,
        child: Center(child: content),
      );
    }

    return content;
  }

  Widget _buildHeader(BuildContext context) => Container(
    padding: AppLayout.padding6,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppLayout.spacing1),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
        ),
        if (showCloseButton)
          IconButton(
            onPressed: () => _handleClose(context),
            icon: const Icon(LucideIcons.x),
            iconSize: AppLayout.iconSize,
            color: AppColors.mutedForeground,
            tooltip: "閉じる",
          ),
      ],
    ),
  );

  Widget _buildBody() {
    Widget content = Container(padding: padding ?? AppLayout.padding6, child: child);

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return content;
  }

  Widget _buildActions() => Container(
    padding: AppLayout.padding6,
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions!
          .map(
            (Widget action) => Padding(
              padding: const EdgeInsets.only(left: AppLayout.spacing2),
              child: action,
            ),
          )
          .toList(),
    ),
  );

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// モーダル表示ヘルパー
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    VoidCallback? onClose,
    double? width,
    double? height,
    double maxWidth = 600,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    Color? backgroundColor,
    bool scrollable = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => AppModal(
      title: title,
      subtitle: subtitle,
      actions: actions,
      onClose: onClose,
      width: width,
      height: height,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      padding: padding,
      showCloseButton: showCloseButton,
      barrierDismissible: barrierDismissible,
      backgroundColor: backgroundColor,
      scrollable: scrollable,
      child: child,
    ),
  );
}

/// 確認ダイアログ
class AppConfirmModal extends StatelessWidget {
  const AppConfirmModal({
    required this.title,
    required this.message,
    required this.onConfirm,
    super.key,
    this.onCancel,
    this.confirmText = "確認",
    this.cancelText = "キャンセル",
    this.confirmVariant = ButtonVariant.primary,
    this.isDestructive = false,
  });

  /// タイトル
  final String title;

  /// メッセージ
  final String message;

  /// 確認処理
  final VoidCallback onConfirm;

  /// キャンセル処理
  final VoidCallback? onCancel;

  /// 確認ボタンテキスト
  final String confirmText;

  /// キャンセルボタンテキスト
  final String cancelText;

  /// 確認ボタンバリアント
  final ButtonVariant confirmVariant;

  /// 破壊的操作フラグ
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => AppModal(
    title: title,
    maxWidth: 400,
    actions: <Widget>[
      AppButton.text(
        cancelText,
        onPressed: () {
          onCancel?.call();
          Navigator.of(context).pop(false);
        },
        variant: ButtonVariant.ghost,
      ),
      AppButton.text(
        confirmText,
        onPressed: () {
          onConfirm();
          Navigator.of(context).pop(true);
        },
        variant: isDestructive ? ButtonVariant.danger : confirmVariant,
      ),
    ],
    child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
  );

  /// 確認ダイアログ表示ヘルパー
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = "確認",
    String cancelText = "キャンセル",
    ButtonVariant confirmVariant = ButtonVariant.primary,
    bool isDestructive = false,
  }) => AppModal.show<bool>(
    context: context,
    child: AppConfirmModal(
      title: title,
      message: message,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmVariant: confirmVariant,
      isDestructive: isDestructive,
    ),
  );
}

/// アラートダイアログ
class AppAlertModal extends StatelessWidget {
  const AppAlertModal({
    required this.title,
    required this.message,
    super.key,
    this.buttonText = "OK",
    this.onPressed,
    this.variant = ButtonVariant.primary,
  });

  /// タイトル
  final String title;

  /// メッセージ
  final String message;

  /// ボタンテキスト
  final String buttonText;

  /// ボタン押下処理
  final VoidCallback? onPressed;

  /// ボタンバリアント
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) => AppModal(
    title: title,
    maxWidth: 400,
    actions: <Widget>[
      AppButton.text(
        buttonText,
        onPressed: () {
          onPressed?.call();
          Navigator.of(context).pop();
        },
        variant: variant,
      ),
    ],
    child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
  );

  /// アラートダイアログ表示ヘルパー
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    VoidCallback? onPressed,
    ButtonVariant variant = ButtonVariant.primary,
  }) => AppModal.show<void>(
    context: context,
    child: AppAlertModal(
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      variant: variant,
    ),
  );
}
