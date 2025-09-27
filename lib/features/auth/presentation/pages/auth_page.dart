import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/auth_state.dart";
import "../providers/auth_providers.dart";
import "../widgets/google_sign_in_button.dart";

/// Google OAuth専用のログイン/サインアップ画面。
class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authStateNotifierProvider);
    final bool isLoading = authState.isAuthenticating;
    final String? errorMessage = authState.error;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.storefront, size: 56, color: Colors.deepOrange),
                const SizedBox(height: 16),
                Text("YATA", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  "Googleアカウントでログインまたはサインアップしてください",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GoogleSignInButton(
                  isLoading: isLoading,
                  onPressed: () async => _signInWithGoogle(context, ref),
                ),
                if (errorMessage != null && errorMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  _AuthErrorMessage(message: errorMessage),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithGoogle();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("ログインに失敗しました。時間を置いて再度お試しください。")));
    }
  }
}

/// 認証エラーメッセージを表示するカード。
class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
