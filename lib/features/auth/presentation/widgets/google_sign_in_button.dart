import "package:flutter/material.dart";

/// Googleログイン/サインアップ用のアクションボタン。
class GoogleSignInButton extends StatelessWidget {
  /// [GoogleSignInButton]を生成する。
  const GoogleSignInButton({required this.onPressed, super.key, this.isLoading = false});

  /// ボタン押下時のハンドラー。
  final VoidCallback? onPressed;

  /// ローディング中かどうか。
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      child: isLoading ? _buildLoadingContent(context) : _buildLabelContent(context),
    ),
  );

  Widget _buildLabelContent(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: const <Widget>[Icon(Icons.login), SizedBox(width: 12), Text("Googleでログイン / サインアップ")],
  );

  Widget _buildLoadingContent(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      const SizedBox(width: 12),
      const Text("Googleで認証中..."),
    ],
  );
}
